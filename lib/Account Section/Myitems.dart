import 'package:flutter/material.dart';


class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data for store items with network image URLs
    final List<Map<String, dynamic>> items = [
      {
        "image": "https://thumbs.dreamstime.com/b/car-gift-22638825.jpg",
        "duration": "1 day",
        "price": 5000,
      },
      {
        "image": "https://thumbs.dreamstime.com/b/car-gift-22638825.jpg",
        "duration": "3 days",
        "price": 15000,
      },
      {
        "image": "https://thumbs.dreamstime.com/b/car-gift-22638825.jpg",
        "duration": "7 days",
        "price": 35000,
      },
      {
        "image": "https://thumbs.dreamstime.com/b/car-gift-22638825.jpg",
        "duration": "7 days",
        "price": 70000,
      },
      {
        "image": "https://thumbs.dreamstime.com/b/car-gift-22638825.jpg",
        "duration": "3 days",
        "price": 45000,
      },
      {
        "image": "https://thumbs.dreamstime.com/b/car-gift-22638825.jpg",
        "duration": "7 days",
        "price": 55000,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Store",style: TextStyle(color: Colors.white),),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["Leo Store", "My Items"]
                  .map((category) => Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: category == "Cars" ? Colors.purple : Colors.black,
                ),
              ))
                  .toList(),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.8,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Image
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                item["image"],
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          // Duration
                          Text(
                            item["duration"],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          // Price
                          Text(
                            "💰 ${item['price']}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Expanded(
                              //   // child: ElevatedButton(
                              //   //   onPressed: () {
                              //   //     // Handle Send
                              //   //   },
                              //   //   style: ElevatedButton.styleFrom(
                              //   //     backgroundColor: Colors.purple,
                              //   //     shape: RoundedRectangleBorder(
                              //   //       borderRadius: BorderRadius.circular(8.r),
                              //   //     ),
                              //   //   ),
                              //   //   child: Text(
                              //   //     "Send",
                              //   //     style: TextStyle(fontSize: 12.sp),
                              //   //   ),
                              //   // ),
                              // ),
                              SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Handle Buy
                                  },
                                  style: OutlinedButton.styleFrom(

                                    side: BorderSide(color: Colors.blue),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    "Buy Now",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold

                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
