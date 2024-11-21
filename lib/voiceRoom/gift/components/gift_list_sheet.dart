import 'package:flutter/material.dart';
import '../gift_data.dart';
import '../gift_manager/defines.dart';
import '../gift_manager/gift_manager.dart';

void showGiftListSheet(BuildContext context) {
  showModalBottomSheet(
    backgroundColor: Colors.black.withOpacity(0.8),
    context: context,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(32.0),
        topRight: Radius.circular(32.0),
      ),
    ),
    isDismissible: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return AnimatedPadding(
        padding: MediaQuery.of(context).viewInsets,
        duration: const Duration(milliseconds: 50),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: ZegoGiftSheet(
              itemDataList: giftItemList,
            ),
          ),
        ),
      );
    },
  );
}

class ZegoGiftSheet extends StatefulWidget {
  const ZegoGiftSheet({
    Key? key,
    required this.itemDataList,
  }) : super(key: key);

  final List<ZegoGiftItem> itemDataList;

  @override
  State<ZegoGiftSheet> createState() => _ZegoGiftSheetState();
}

class _ZegoGiftSheetState extends State<ZegoGiftSheet> {
  final selectedGiftItemNotifier = ValueNotifier<ZegoGiftItem?>(null);
  final countNotifier = ValueNotifier<String>('1');

  @override
  void initState() {
    super.initState();

    widget.itemDataList.sort((l, r) => l.weight.compareTo(r.weight));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: giftGrid(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            countDropList(),
            SizedBox(
              height: 30,
              child: sendButton(),
            ),
          ],
        ),
      ],
    );
  }

  Widget sendButton() {
    return ElevatedButton(
      onPressed: () {
        if (selectedGiftItemNotifier.value == null) return;

        final giftItem = selectedGiftItemNotifier.value!;
        final giftCount = int.tryParse(countNotifier.value) ?? 1;
        Navigator.of(context).pop();

        /// local play
        ZegoGiftManager().playList.add(PlayData(giftItem: giftItem, count: giftCount));

        /// notify remote host
        ZegoGiftManager().service.sendGift(name: giftItem.name, count: giftCount);
      },
      child: const Text('SEND'),
    );
  }

  Widget countDropList() {
    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 15,
    );

    return ValueListenableBuilder<String>(
      valueListenable: countNotifier,
      builder: (context, count, _) {
        return DropdownButton<String>(
          value: count,
          onChanged: (selectedValue) {
            countNotifier.value = selectedValue!;
          },
          alignment: AlignmentDirectional.centerEnd,
          style: textStyle,
          dropdownColor: Colors.black.withOpacity(0.5),
          items: <String>['1', '5', '10', '100'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: textStyle,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget giftGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Number of columns
        crossAxisSpacing: 10, // Horizontal spacing
        mainAxisSpacing: 10, // Vertical spacing
        childAspectRatio: 0.8, // Aspect ratio of each grid item
      ),
      itemCount: widget.itemDataList.length,
      itemBuilder: (context, index) {
        final item = widget.itemDataList[index];
        return GestureDetector(
          onTap: () => selectedGiftItemNotifier.value = item,
          child: ValueListenableBuilder<ZegoGiftItem?>(
            valueListenable: selectedGiftItemNotifier,
            builder: (context, selectedGiftItem, _) {
              final isSelected = selectedGiftItem?.name == item.name;
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.red : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.icon.isEmpty
                          ? const Icon(Icons.card_giftcard, color: Colors.red, size: 40)
                          : Image.asset(
                        item.icon,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(item.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.attach_money, color: Colors.yellow, size: 14),
                        Text(
                          item.weight.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
