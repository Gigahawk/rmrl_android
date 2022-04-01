import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rmrl_android/doc_view/simple_card.dart';
import 'package:rmrl_android/navigation/navigation.dart';
import 'package:rmrl_android/remarkable/document.dart';
import 'package:rmrl_android/shared_prefs/shared_prefs.dart';
import 'package:shared_storage/shared_storage.dart';

import 'key_value_text.dart';


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
  Uri? uri;
  List<RemarkableDocument> documents = [];

  StreamSubscription<PartialDocumentFile>? _listener;

  Widget _buildFileList() {
    if (documents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Empty Folder"),
        ),
      );
    }

    // TODO: Replace with a widget that properly handles reMarkable file structure
    // Should take:
    // - the global list of files
    // - the current parent (defaults to "")
    // Behavior:
    // - Filter list for metadata files
    // - Filter list for files matching current parent
    // - Sort list by name
    // - Sort list by type (folders vs files)
    // - Pass filtered/sorted list to gridview builder
    //    - Builder should create a folder for folder types, and a image preview for the files

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 400,
          childAspectRatio: 8.5 / 10,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5),
      itemCount: documents.length,
      itemBuilder: (context, index) {
        final doc = documents[index];

        return DocTile(document: doc);
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _loadFiles();
  }

  @override
  void dispose() {
    _listener?.cancel();

    super.dispose();
  }

  void _loadFiles() async {
    uri = await getFolderPath(true);
    final documentUri = await uri?.toDocumentFile();

    final columns = [
      DocumentFileColumn.displayName,
      DocumentFileColumn.size,
      DocumentFileColumn.lastModified,
      DocumentFileColumn.id,
      DocumentFileColumn.mimeType,
    ];

    _listener = documentUri?.listFiles(columns).listen(
      (file) async {
        String fileName = file.data?[DocumentFileColumn.displayName];
        if (file.metadata?.isDirectory == false) {
         if (fileName.endsWith("metadata")) {
           RemarkableDocument doc = RemarkableDocument(metadataFile: file);
           String? parent = await doc.getParent();
           if(parent == widget.parent) {
             documents.add(doc);
             setState(() {});
           }
         }
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inside ${uri?.pathSegments.last}')),
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

  static const _size = Size.square(150);

  String documentName = "";

  Uint8List? imageBytes;

  void _loadThumbnailIfAvailable() async {
    //final rootUri = file.metadata?.rootUri;
    //final documentId = file.data?[DocumentFileColumn.id];

    //if (rootUri == null || documentId == null) return;

    //final bitmap = await getDocumentThumbnail(
    //  rootUri: rootUri,
    //  documentId: documentId,
    //  width: _size.width,
    //  height: _size.height,
    //);

    //if (bitmap == null || !mounted) return;

    //setState(() => imageBytes = bitmap.bytes);
  }

  @override
  void initState() {
    super.initState();

    _loadValues();
  }

  void _loadValues() async {
    documentName = await document.getName();
    setState(() {});
  }

  void _openListFilesPage(Uri uri) {
  }

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      onTap: () async {
        var docType = await document.getDocType();
        var m = await document.getMetadata();
        var documentName = await document.getName();
        var parent = await document.getParent();
        var uuid = document.uuid;
        print(m);
        print(m.runtimeType);
        print(documentName);
        print(uuid);
        print(docType);
        print(parent);
        if (docType == DocumentType.collection) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => DocViewPage(parent: uuid))
          );
        }
      },
      children: [
        Text(documentName)
      ]
    );
  }
}
