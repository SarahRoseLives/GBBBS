import 'package:flutter/material.dart';
import '../../../models/board_post.dart';

class ThreadViewScreen extends StatelessWidget {
  final String threadId;
  final List<BoardPost> allPosts;
  final Function(String subject, String body, String threadId) onReply;

  const ThreadViewScreen({
    super.key,
    required this.threadId,
    required this.allPosts,
    required this.onReply,
  });

  void _showReplyDialog(BuildContext context, BoardPost originalPost) {
    final subjectController =
        TextEditingController(text: "Re: ${originalPost.subject}");
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reply to Thread"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(labelText: "Subject"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(labelText: "Body"),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final subject = subjectController.text.trim();
                final body = bodyController.text.trim();
                if (subject.isNotEmpty && body.isNotEmpty) {
                  onReply(subject, body, originalPost.threadId);
                  Navigator.pop(context);
                }
              },
              child: const Text("Post Reply"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final threadPosts = allPosts
        .where((post) => post.threadId == threadId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final originalPost = threadPosts.first;

    return Scaffold(
      appBar: AppBar(
        title: Text(originalPost.subject, overflow: TextOverflow.ellipsis),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: threadPosts.length,
        itemBuilder: (context, index) {
          final post = threadPosts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.subject,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Divider(),
                  Text(post.body),
                  const SizedBox(height: 8),
                  Text(
                    "From: ${post.author} at ${TimeOfDay.fromDateTime(post.timestamp).format(context)}",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReplyDialog(context, originalPost),
        child: const Icon(Icons.reply),
      ),
    );
  }
}