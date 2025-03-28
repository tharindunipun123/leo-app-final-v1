import '../models/message.dart';

class MessageSelectionManager {
  final List<Message> _selectedMessages = [];

  // Get all selected messages
  List<Message> get selectedMessages => List.unmodifiable(_selectedMessages);

  // Check if a message is selected
  bool isSelected(Message message) {
    return _selectedMessages.any((m) => m.messageId == message.messageId);
  }

  // Check if any messages are selected
  bool get hasSelection => _selectedMessages.isNotEmpty;

  // Get the number of selected messages
  int get selectionCount => _selectedMessages.length;

  // Toggle selection for a message
  void toggleSelection(Message message) {
    final isAlreadySelected = isSelected(message);

    if (isAlreadySelected) {
      _selectedMessages.removeWhere((m) => m.messageId == message.messageId);
    } else {
      _selectedMessages.add(message);
    }
  }

  // Add a message to selection
  void selectMessage(Message message) {
    if (!isSelected(message)) {
      _selectedMessages.add(message);
    }
  }

  // Remove a message from selection
  void unselectMessage(Message message) {
    _selectedMessages.removeWhere((m) => m.messageId == message.messageId);
  }

  // Clear all selections
  void clearSelection() {
    _selectedMessages.clear();
  }

  // Check if all selected messages are from current user
  bool allMessagesFromUser(String userId) {
    if (_selectedMessages.isEmpty) return false;
    return _selectedMessages.every((m) => m.senderId == userId);
  }

  // Check if all selected messages are newer than given duration (in milliseconds)
  bool allMessagesNewerThan(int durationMs) {
    if (_selectedMessages.isEmpty) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    return _selectedMessages.every((m) => (now - m.timestamp) <= durationMs);
  }
}
