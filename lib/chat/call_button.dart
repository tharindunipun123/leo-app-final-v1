// call_buttons.dart
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_zimkit/zego_zimkit.dart';

List<Widget> buildCallButtons(
    BuildContext context,
    String conversationID,
    ZIMConversationType type,
    ) {
  // Only show call buttons for peer-to-peer conversations
  if (type != ZIMConversationType.peer) return [];

  return [
    // Video Call Button
    ZegoSendCallInvitationButton(
      iconSize:  const Size(20, 20),
      buttonSize: const Size(30, 30),
      isVideoCall: true,
      resourceID: 'zego_data',
      invitees: [
        ZegoUIKitUser(
          id: conversationID,
          name: ZIMKit().getConversation(conversationID, type).value.name,
        )
      ],
      onPressed: (String code, String message, List<String> errorInvitees) {
        if (errorInvitees.isNotEmpty || code.isNotEmpty) {
          String errorMessage = '';
          if (errorInvitees.isNotEmpty) {
            errorMessage = "User doesn't exist or is offline: ${errorInvitees[0]}";
            if (code.isNotEmpty) {
              errorMessage += ', code: $code, message:$message';
            }
          } else if (code.isNotEmpty) {
            errorMessage = 'code: $code, message:$message';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      },
    ),
    // Voice Call Button
    ZegoSendCallInvitationButton(
      iconSize: const Size(40, 40),
      buttonSize: const Size(50, 50),
      isVideoCall: false,
      resourceID: 'zego_data',
      invitees: [
        ZegoUIKitUser(
          id: conversationID,
          name: ZIMKit().getConversation(conversationID, type).value.name,
        )
      ],
      onPressed: (String code, String message, List<String> errorInvitees) {
        if (errorInvitees.isNotEmpty || code.isNotEmpty) {
          String errorMessage = '';
          if (errorInvitees.isNotEmpty) {
            errorMessage = "User doesn't exist or is offline: ${errorInvitees[0]}";
            if (code.isNotEmpty) {
              errorMessage += ', code: $code, message:$message';
            }
          } else if (code.isNotEmpty) {
            errorMessage = 'code: $code, message:$message';
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      },
    ),
  ];
}