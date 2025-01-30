const express = require('express');
const app = express();
const http = require('http').createServer(app);
const io = require('socket.io')(http);
const axios = require('axios');

const POCKETBASE_URL = 'http://145.223.21.62:8090';
const DEBUG = true;
const UPDATE_INTERVAL = 2000;  // Poll every 2 seconds
const CLEANUP_INTERVAL = 10000;  // Clean up every 10 seconds
const INACTIVE_TIMEOUT = 30000;  // Consider users inactive after 30 seconds

// Data structures for tracking
const rooms = new Map();  // roomId -> { users: Map<userId, userDetails>, lastUpdate: timestamp }
const userSockets = new Map();  // userId -> Set<socketId>
const socketRooms = new Map();  // socketId -> { roomId, userId }
const activeRooms = new Set();  // Set of active roomIds

function logDebug(message, data = null) {
  if (DEBUG) {
    console.log(`[DEBUG] ${message}`, data ? JSON.stringify(data, null, 2) : '');
  }
}

// Helper function to get user details from PocketBase
async function getUserDetails(userId) {
  try {
    const response = await axios.get(
      `${POCKETBASE_URL}/api/collections/users/records/${userId}`
    );
    
    const userData = response.data;
    return {
      id: userData.id,
      name: `${userData.firstname} ${userData.lastname}`.trim(),
      avatarUrl: `${POCKETBASE_URL}/api/files/${userData.collectionId}/${userData.id}/${userData.avatar}`,
      motto: userData.moto || '',
      firstName: userData.firstname || '',
      lastName: userData.lastname || '',
      lastSeen: Date.now()
    };
  } catch (error) {
    console.error(`Error fetching user details for ${userId}:`, error.message);
    return null;
  }
}

// Initialize room data structure
function initializeRoom(roomId) {
  if (!rooms.has(roomId)) {
    rooms.set(roomId, {
      users: new Map(),
      lastUpdate: Date.now(),
      connectionCount: 0
    });
  }
  return rooms.get(roomId);
}

// Fetch all online users from PocketBase
async function fetchAllOnlineUsers() {
  try {
    const response = await axios.get(`${POCKETBASE_URL}/api/collections/online_users/records`);
    const onlineUsers = response.data.items;
    
    // Group users by room
    const roomGroups = new Map();
    onlineUsers.forEach(user => {
      if (!roomGroups.has(user.voiceRoomId)) {
        roomGroups.set(user.voiceRoomId, []);
      }
      roomGroups.get(user.voiceRoomId).push(user);
    });

    // Initialize each room
    for (const [roomId, users] of roomGroups) {
      activeRooms.add(roomId);
      const room = initializeRoom(roomId);

      // Fetch and store user details
      for (const user of users) {
        const userDetails = await getUserDetails(user.userId);
        if (userDetails) {
          room.users.set(user.userId, userDetails);
        }
      }
    }

    logDebug(`Initialized ${activeRooms.size} active rooms`);
  } catch (error) {
    console.error('Error fetching initial room data:', error);
  }
}

// Update room data and notify clients
async function updateRoomAndNotify(roomId) {
  try {
    const room = rooms.get(roomId);
    if (!room) {
      logDebug(`Room ${roomId} not found`);
      return;
    }

    logDebug(`Updating room ${roomId}`, {
      beforeUpdate: {
        userCount: room.users.size,
        users: Array.from(room.users.keys())
      }
    });

    // Fetch current online users from PocketBase
    const response = await axios.get(`${POCKETBASE_URL}/api/collections/online_users/records`, {
      params: {
        filter: `voiceRoomId="${roomId}"`,
      }
    });

    const onlineUsers = response.data.items;
    const currentUsers = new Set(onlineUsers.map(u => u.userId));
    
    // Remove users who are no longer online
    for (const [userId, userData] of room.users.entries()) {
      if (!currentUsers.has(userId) || Date.now() - userData.lastSeen > INACTIVE_TIMEOUT) {
        room.users.delete(userId);
        io.to(roomId).emit('userLeft', { userId });
        logDebug(`Removed user ${userId} from room ${roomId}`);
      }
    }

    // Add or update current users
    for (const user of onlineUsers) {
      if (!room.users.has(user.userId)) {
        const userDetails = await getUserDetails(user.userId);
        if (userDetails) {
          room.users.set(user.userId, userDetails);
          io.to(roomId).emit('userJoined', userDetails);
          logDebug(`Added user ${user.userId} to room ${roomId}`);
        }
      }
    }

    // Update room data
    room.lastUpdate = Date.now();

    const roomData = {
      roomId,
      users: Array.from(room.users.values()),
      count: room.users.size
    };

    io.to(roomId).emit('roomUpdate', roomData);
    logDebug(`Notified clients for room ${roomId}`, roomData);

    return roomData;
  } catch (error) {
    console.error(`Error updating room ${roomId}:`, error);
  }
}

// Socket.IO connection handling
io.on('connection', (socket) => {
  logDebug('Client connected:', socket.id);

  socket.on('joinRoom', async (data) => {
    const { roomId, userId, userName, userAvatar } = data;
    
    logDebug('Join room request', { roomId, userId, userName });
    
    if (!roomId || !userId) {
      socket.emit('error', { message: 'Invalid room or user ID' });
      return;
    }

    try {
      // Join socket.io room
      socket.join(roomId);
      
      // Track socket-room-user relationship
      socketRooms.set(socket.id, { roomId, userId });
      
      // Initialize room if needed
      const room = initializeRoom(roomId);
      activeRooms.add(roomId);
      
      // Track user sockets
      if (!userSockets.has(userId)) {
        userSockets.set(userId, new Set());
      }
      userSockets.get(userId).add(socket.id);
      
      // Get user details
      const userDetails = await getUserDetails(userId);
      if (userDetails) {
        // Always update user details to ensure latest data
        room.users.set(userId, {
          ...userDetails,
          lastSeen: Date.now()
        });
        
        logDebug(`Updated user details for ${userId}`, userDetails);
      }

      // Update and notify all clients
      const roomData = await updateRoomAndNotify(roomId);
      if (roomData) {
        // Send current state to joining client
        socket.emit('roomUpdate', roomData);
      }

      logDebug(`User ${userId} joined room ${roomId}`, {
        roomUsers: Array.from(room.users.keys())
      });
    } catch (error) {
      console.error(`Error handling room join:`, error);
      socket.emit('error', { message: 'Failed to join room' });
    }
  });

  socket.on('heartbeat', (data) => {
    const { roomId, userId } = data;
    if (!roomId || !userId) return;
    
    const room = rooms.get(roomId);
    if (room && room.users.has(userId)) {
      const user = room.users.get(userId);
      user.lastSeen = Date.now();
      room.users.set(userId, user);
    }
  });

  socket.on('leaveRoom', async (data) => {
    const { roomId, userId } = data;
    if (!roomId || !userId) return;

    try {
      await handleUserLeave(socket.id, roomId, userId);
    } catch (error) {
      console.error(`Error handling room leave:`, error);
    }
  });

  socket.on('disconnect', async () => {
    const socketData = socketRooms.get(socket.id);
    if (socketData) {
      const { roomId, userId } = socketData;
      await handleUserLeave(socket.id, roomId, userId);
    }
    socketRooms.delete(socket.id);
    logDebug('Client disconnected:', socket.id);
  });

  socket.on('fetchUsers', async (data, callback) => {
    const { roomId } = data;
    if (!roomId) {
      callback({ error: 'Invalid room ID' });
      return;
    }

    try {
      const room = rooms.get(roomId);
      if (room) {
        callback({
          users: Array.from(room.users.values()),
          count: room.users.size
        });
      } else {
        // Try to fetch room data if not in memory
        const roomData = await updateRoomAndNotify(roomId);
        if (roomData) {
          callback(roomData);
        } else {
          callback({ error: 'Room not found' });
        }
      }
    } catch (error) {
      console.error(`Error fetching users:`, error);
      callback({ error: 'Failed to fetch users' });
    }
  });
});

// Helper function to handle user leaving
async function handleUserLeave(socketId, roomId, userId) {
  logDebug(`Handling user leave`, { socketId, roomId, userId });

  // Remove socket from room
  const socket = io.sockets.sockets.get(socketId);
  if (socket) {
    socket.leave(roomId);
  }

  // Remove socket from user's sockets
  if (userSockets.has(userId)) {
    userSockets.get(userId).delete(socketId);
    if (userSockets.get(userId).size === 0) {
      userSockets.delete(userId);
      
      // Notify others before removing user
      io.to(roomId).emit('userLeft', { userId });
      
      // Remove user from room
      const room = rooms.get(roomId);
      if (room) {
        room.users.delete(userId);
        await updateRoomAndNotify(roomId);
        
        logDebug(`Removed user ${userId} from room ${roomId}`, {
          remainingUsers: Array.from(room.users.keys())
        });
      }
    }
  }

  // Clean up empty room
  const room = rooms.get(roomId);
  if (room && room.users.size === 0) {
    rooms.delete(roomId);
    activeRooms.delete(roomId);
    logDebug(`Removed empty room ${roomId}`);
  }
}

// Enable CORS
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
});

// Health check endpoint with detailed status
app.get('/health', (req, res) => {
  const roomDetails = Array.from(rooms.entries()).map(([roomId, room]) => ({
    roomId,
    userCount: room.users.size,
    users: Array.from(room.users.values()).map(u => ({
      id: u.id,
      name: u.name,
      lastSeen: new Date(u.lastSeen).toISOString()
    })),
    lastUpdate: new Date(room.lastUpdate).toISOString()
  }));

  res.json({
    status: 'ok',
    connections: io.engine.clientsCount,
    activeRooms: Array.from(activeRooms),
    roomDetails,
    activeUserConnections: Array.from(userSockets.entries()).map(([userId, sockets]) => ({
      userId,
      connectionCount: sockets.size
    })),
    lastCheck: new Date().toISOString()
  });
});

// API endpoint for room users
app.get('/api/rooms/:roomId/users', async (req, res) => {
  try {
    const { roomId } = req.params;
    const room = rooms.get(roomId);
    
    if (room) {
      res.json({
        users: Array.from(room.users.values()),
        count: room.users.size
      });
    } else {
      // Try to fetch room data if not in memory
      const roomData = await updateRoomAndNotify(roomId);
      if (roomData) {
        res.json(roomData);
      } else {
        res.status(404).json({ error: 'Room not found' });
      }
    }
  } catch (error) {
    console.error(`Error getting room users:`, error);
    res.status(500).json({ error: 'Failed to get room users' });
  }
});

// Cleanup inactive users and empty rooms
setInterval(() => {
  try {
    const now = Date.now();
    rooms.forEach((room, roomId) => {
      // Remove inactive users
      room.users.forEach((user, userId) => {
        if (now - user.lastSeen > INACTIVE_TIMEOUT) {
          room.users.delete(userId);
          io.to(roomId).emit('userLeft', { userId });
          logDebug(`Removed inactive user ${userId} from room ${roomId}`);
        }
      });
      
      // Remove empty rooms
      if (room.users.size === 0) {
        rooms.delete(roomId);
        activeRooms.delete(roomId);
        logDebug(`Removed empty room ${roomId}`);
      }
    });
  } catch (error) {
    console.error('Error in cleanup interval:', error);
  }
}, CLEANUP_INTERVAL);

// Update active rooms
setInterval(() => {
  activeRooms.forEach(roomId => {
    updateRoomAndNotify(roomId).catch(error => {
      console.error(`Error in polling update for room ${roomId}:`, error);
    });
  });
}, UPDATE_INTERVAL);

// Start server
const PORT = process.env.PORT || 3000;
http.listen(PORT, async () => {
  console.log(`Server running on port ${PORT}`);
  
  // Initialize rooms from existing data
  console.log('Initializing rooms from PocketBase...');
  await fetchAllOnlineUsers();
  console.log('Room initialization complete');
});

// Global error handling
process.on('unhandledRejection', (error) => {
  console.error('Unhandled promise rejection:', error);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught exception:', error);
  // Attempt graceful shutdown
  http.close(() => {
    process.exit(1);
  });
});