/// 议题页面

import 'package:flutter/material.dart';
import 'package:markdown_editor_plus/markdown_editor_plus.dart';


class IssueScreen extends StatelessWidget {
  const IssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('标题'),
      ),
      body: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            flex: 1,
            child: IssueContent(
                title: '内容'
            ),
          ),
          Flexible(
            flex: 1,
            child: IssueContent(
                title: '结论'
            ),
          )
        ]
      )
    );
  }
}


class IssueContent extends StatelessWidget {
  final String title;

  const IssueContent({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController();
    return Card(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 1,
              child: Text(title),
            ),
            Flexible(
              flex: 3,
              child: MarkdownAutoPreview(
                // editable text with toolbar by default
                controller: controller,
                emojiConvert: true,
              ),
            ),
          ]
      ),
    );
  }
}
