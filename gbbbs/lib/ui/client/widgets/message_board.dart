import 'package:flutter/material.dart';
import '../../../models/board_post.dart';
import 'thread_view_screen.dart';

class MessageBoard extends StatelessWidget {
  final List<BoardPost> posts;
  final Function(String subject, String body) onNewPost;
  final Function(String subject, String body, String threadId) onReply;
  final String bbsCallsign;

  const MessageBoard({
    super.key,
    required this.posts,
    required this.onNewPost,
    required this.onReply,
    required this.bbsCallsign,
  });

  void _showNewPostDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create New Post"),
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
                  onNewPost(subject, body);
                  Navigator.pop(context);
                }
              },
              child: const Text("Post"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Group posts by threadId
    final Map<String, List<BoardPost>> threads = {};
    for (var post in posts) {
      threads.putIfAbsent(post.threadId, () => []).add(post);
    }
    // Sort each thread by timestamp
    threads.forEach((key, value) {
      value.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });

    // Get the root post of each thread for the main list
    final rootPosts = threads.values.map((thread) => thread.first).toList()
    ..sort((a,b) => b.timestamp.compareTo(a.timestamp)); // Show newest threads first


    return Scaffold(
      body: rootPosts.isEmpty
          ? Center(
              child: Text(
                  "No messages on $bbsCallsign yet.\nBe the first to post!"),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: rootPosts.length,
              itemBuilder: (context, idx) {
                final rootPost = rootPosts[idx];
                final postCount = threads[rootPost.threadId]?.length ?? 1;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(rootPost.subject),
                    subtitle: Text("From: ${rootPost.author}"),
                    leading: CircleAvatar(child: Text(rootPost.author[0])),
                    trailing: Chip(label: Text("$postCount msg(s)")),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ThreadViewScreen(
                            threadId: rootPost.threadId,
                            allPosts: posts,
                            onReply: onReply,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewPostDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}