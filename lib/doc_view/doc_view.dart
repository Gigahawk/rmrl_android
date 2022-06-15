import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rmrl_android/doc_view/simple_card.dart';
import 'package:rmrl_android/navigation/navigation.dart';
import 'package:rmrl_android/remarkable/document.dart';
import 'package:rmrl_android/remarkable/filesystem.dart';
import 'package:rmrl_android/util/native.dart';


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
  Widget icon = const Icon(Icons.file_copy);

  Uint8List? imageBytes;

  @override
  void initState() {
    super.initState();

    _loadValues();
  }

  void _loadValues() async {
    DocumentType? docType = await document.getDocType();
    documentName = await document.getName();
    setState(() {});
    image = await document.getThumbnail();
    if (docType == null) {
      icon = const Icon(Icons.question_mark);
    } else if(docType == DocumentType.collection) {
      icon = const Icon(Icons.folder);
    } else {
      // TODO: figure out a better icon
      icon = const Icon(Icons.file_copy);
    }
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
          showDialog(
            barrierDismissible: false,
            context: context,
            builder: (_) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical:20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 5),
                      Text("Exporting"),
                    ]
                  )
                )
              );
            }
          );
          Uri? uri = await document.convertDocument();
          Navigator.of(context).pop();
          if (uri != null) {
            openPdfFromUri(uri);
          }
        }
      },
      children: [
        Expanded(child: image),
        Row(
            children: [
              icon,
              const SizedBox(width: 5),
              Expanded(
                child: Text(documentName),
              )
            ],
        ),
      ]
    );
  }
}
