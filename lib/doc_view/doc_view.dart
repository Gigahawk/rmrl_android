import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rmrl_android/doc_view/simple_card.dart';
import 'package:rmrl_android/shared_prefs/shared_prefs.dart';
import 'package:shared_storage/shared_storage.dart';

import 'key_value_text.dart';

class DocViewPage extends StatefulWidget {

  const DocViewPage({Key? key}) : super(key: key);

  @override
  _DocViewPageState createState() => _DocViewPageState();
}

class _DocViewPageState extends State<DocViewPage> {
  Uri? uri;
  List<PartialDocumentFile>? _files;
  List<PartialDocumentFile>? metaDataFiles;

  StreamSubscription<PartialDocumentFile>? _listener;

  Widget _buildFileList() {
    if (_files!.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text("Empty Folder"),
        ),
      );
    }

    metaDataFiles = _files!.where((f) {
      String fname = f.data?[DocumentFileColumn.displayName];
      return fname.endsWith("metadata");
    }).toList();

    return ListView.builder(
      itemCount: metaDataFiles!.length,
      itemBuilder: (context, index) {
        final file = metaDataFiles![index];

        return FileTile(partialFile: file);
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

    _listener = documentUri?.listFiles(columns).listen((file) {
      /// Append new files to the current file list
      _files == null ? _files = [file] : _files!.add(file);

      /// Update the state only if the widget is currently showing
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Inside ${uri?.pathSegments.last}')),
      body: _files == null
          ? const Center(child: CircularProgressIndicator())
          : _buildFileList(),
    );
  }
}

class FileTile extends StatefulWidget {
  final PartialDocumentFile partialFile;

  const FileTile({Key? key, required this.partialFile}) : super(key: key);

  @override
  _FileTileState createState() => _FileTileState();
}

class _FileTileState extends State<FileTile> {
  PartialDocumentFile get file => widget.partialFile;

  static const _size = Size.square(150);

  Uint8List? imageBytes;

  void _loadThumbnailIfAvailable() async {
    final rootUri = file.metadata?.rootUri;
    final documentId = file.data?[DocumentFileColumn.id];

    if (rootUri == null || documentId == null) return;

    final bitmap = await getDocumentThumbnail(
      rootUri: rootUri,
      documentId: documentId,
      width: _size.width,
      height: _size.height,
    );

    if (bitmap == null || !mounted) return;

    setState(() => imageBytes = bitmap.bytes);
  }

  @override
  void initState() {
    super.initState();

    _loadThumbnailIfAvailable();
  }

  void _openListFilesPage(Uri uri) {
  }

  @override
  Widget build(BuildContext context) {
    return SimpleCard(
      onTap: () async {
        if (file.metadata?.isDirectory == false) {
          final document = await file.metadata!.uri!.toDocumentFile();

          print(document!.uri.toString());

          final onNewLine = getDocumentContent(file.metadata!.uri!);

          onNewLine.listen((newLine) {
            print('New line: $newLine');
          });
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: imageBytes == null
              ? Container(
            height: _size.height,
            width: _size.width,
            color: Colors.grey,
          )
              : Image.memory(
            imageBytes!,
            height: _size.height,
            width: _size.width,
            fit: BoxFit.contain,
          ),
        ),
        KeyValueText(
          entries: {
            'name': '${file.data?[DocumentFileColumn.displayName]}',
            'type': '${file.data?[DocumentFileColumn.mimeType]}',
            'size': '${file.data?[DocumentFileColumn.size]}',
            'lastModified': '${(() {
              if (file.data?[DocumentFileColumn.lastModified] == null) {
                return null;
              }

              final millisecondsSinceEpoch =
              file.data?[DocumentFileColumn.lastModified]!;

              final date = DateTime.fromMillisecondsSinceEpoch(
                millisecondsSinceEpoch,
              );

              return date.toIso8601String();
            })()}',
            'summary': '${file.data?[DocumentFileColumn.summary]}',
            'id': '${file.data?[DocumentFileColumn.id]}',
            'parentUri': '${file.metadata?.parentUri}',
            'rootUri': '${file.metadata?.rootUri}',
            'uri': '${file.metadata?.uri}',
          },
        ),
        if (file.metadata?.isDirectory ?? false)
          TextButton(
            onPressed: () async {
              if (file.metadata?.isDirectory ?? false) {
                final uri = await buildTreeDocumentUri(
                  file.metadata!.rootUri!.authority,
                  file.data![DocumentFileColumn.id]!,
                );

                _openListFilesPage(uri!);
              }
            },
            child: const Text('Open folder'),
          ),
      ],
    );
  }
}
