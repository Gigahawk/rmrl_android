import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rmrl_android/doc_view/simple_card.dart';
import 'package:rmrl_android/navigation/navigation.dart';
import 'package:rmrl_android/remarkable/document.dart';
import 'package:rmrl_android/remarkable/filesystem.dart';


class DocViewPage extends StatefulWidget {
  final String parent;

  const DocViewPage({
    Key? key,
    this.parent = ""
  }) : super(key: key);

  @override
  _DocViewPageState createState() => _DocViewPageState();
}

class _DocViewPageState extends State<DocViewPage> {
  RemarkableFileSystem fs = RemarkableFileSystem();
  List<RemarkableDocument>? documents;


  Widget _buildFileList() {
    if (documents == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Loading"),
        ),
      );
    }
    if (documents!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Empty Folder"),
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 8.5 / 12.5,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5),
      itemCount: documents!.length,
      itemBuilder: (context, index) {
        final doc = documents![index];

        return DocTile(document: doc);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  void _loadDocuments() async {
    await fs.ready;
    documents = await fs.getView(widget.parent);
    setState(() {});
  }

  @override
  void dispose() {

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('reMarkable')),
      body: _buildFileList(),
    );
  }
}

class DocTile extends StatefulWidget {
  final RemarkableDocument document;

  const DocTile({Key? key, required this.document}) : super(key: key);

  @override
  _DocTileState createState() => _DocTileState();
}

class _DocTileState extends State<DocTile> {
  RemarkableDocument get document => widget.document;

  String documentName = "";
  Widget image = const Text("No image");

  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();

    _loadValues();
  }

  void _loadValues() async {
    documentName = await document.getName();
    setState(() {});
    image = await document.getThumbnail();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      onTap: () async {
        var docType = await document.getDocType();
        var uuid = document.uuid;
        if (docType == DocumentType.collection) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => DocViewPage(parent: uuid))
          );
        } else {
          document.convertDocument();
        }
      },
      children: [
        image,
        Text(documentName)
      ]
    );
  }
}
