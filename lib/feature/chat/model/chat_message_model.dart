class ChatMessage {
  final String id;
  final String chatRoomId;
  final String userIdFrom;
  final String userIdTo;
  final String message;
  final String chatFrom;
  final String status;
  final String createdOn;
  final String updatedOn;
  

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.userIdFrom,
    required this.userIdTo,
    required this.message,
    required this.chatFrom,
    required this.status,
    required this.createdOn,
    required this.updatedOn,
  
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['message_id'] as String,
      chatRoomId: json['chat_room_id'] as String,
      userIdFrom: json['user_id_from'] as String,
      userIdTo: json['user_id_to'] as String,
      message: json['message'] as String,
      chatFrom: json['chat_from'] as String,
      status: json['status'] as String,
      createdOn: json['created_on'] as String,
      updatedOn: json['updated_on'] as String,
     
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message_id': id,
      'chat_room_id': chatRoomId,
      'user_id_from': userIdFrom,
      'user_id_to': userIdTo,
      'message': message,
      'chat_from': chatFrom,
      'status': status,
      'created_on': createdOn,
      'updated_on': updatedOn,
 
    };
  }
}