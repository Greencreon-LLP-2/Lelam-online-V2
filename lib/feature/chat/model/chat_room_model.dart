class ChatRoom {
  final String id;
  final String userIdFrom;
  final String userIdTo;
  final String createdOn;
  final String updatedOn;


  ChatRoom({
    required this.id,
    required this.userIdFrom,
    required this.userIdTo,
    required this.createdOn,
    required this.updatedOn,

  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['chat_room_id'] as String,
      userIdFrom: json['user_id_from'] as String,
      userIdTo: json['user_id_to'] as String,
      createdOn: json['created_on'] as String,
      updatedOn: json['updated_on'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_room_id': id,
      'user_id_from': userIdFrom,
      'user_id_to': userIdTo,
      'created_on': createdOn,
      'updated_on': updatedOn,
    };
  }
}