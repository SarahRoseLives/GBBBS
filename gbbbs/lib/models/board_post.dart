import 'dart:convert';
import 'package:uuid/uuid.dart';

class BoardPost {
  final String id;
  final String threadId; // ID of the root post in the thread
  final String author;
  final String subject;
  final String body;
  final DateTime timestamp;

  BoardPost({
    required this.id,
    required this.threadId,
    required this.author,
    required this.subject,
    required this.body,
    required this.timestamp,
  });

  /// Creates a new post, starting its own thread.
  factory BoardPost.createNew({
    required String author,
    required String subject,
    required String body,
  }) {
    final newId = const Uuid().v4();
    return BoardPost(
      id: newId,
      threadId: newId, // A new post is its own thread root
      author: author,
      subject: subject,
      body: body,
      timestamp: DateTime.now(),
    );
  }

  /// Creates a reply to an existing post.
  factory BoardPost.createReply({
    required String toThreadId,
    required String author,
    required String subject,
    required String body,
  }) {
    return BoardPost(
      id: const Uuid().v4(),
      threadId: toThreadId, // Replies belong to the parent's thread
      author: author,
      subject: subject,
      body: body,
      timestamp: DateTime.now(),
    );
  }

  /// Encodes the post into a string for packet transmission.
  /// Format: BOARD|id|threadId|author|timestamp_in_millis|subject|body
  @override
  String toString() {
    return 'BOARD|${id}|${threadId}|${author}|${timestamp.millisecondsSinceEpoch}|${subject}|${body}';
  }

  /// Decodes a post from a packet string. Returns null if format is invalid.
  static BoardPost? fromString(String packetInfo) {
    final parts = packetInfo.split('|');
    if (parts.length != 7 || parts[0] != 'BOARD') {
      return null;
    }
    try {
      return BoardPost(
        id: parts[1],
        threadId: parts[2],
        author: parts[3],
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[4])),
        subject: parts[5],
        body: parts[6],
      );
    } catch (e) {
      return null; // Parsing failed
    }
  }

  // Methods for JSON conversion for local storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'threadId': threadId,
        'author': author,
        'subject': subject,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };

  factory BoardPost.fromJson(Map<String, dynamic> json) {
    return BoardPost(
      id: json['id'],
      threadId: json['threadId'],
      author: json['author'],
      subject: json['subject'],
      body: json['body'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}