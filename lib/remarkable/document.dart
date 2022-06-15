
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rmrl_android/remarkable/filesystem.dart';
import 'package:rmrl_android/util/native.dart';
import 'package:shared_storage/shared_storage.dart';

enum DocumentType {
  document,
  collection
}

class RemarkableDocument {
  final RemarkableFileSystem fs = RemarkableFileSystem();
  final PartialDocumentFile metadataFile;
  //Stream<String> metadataStream;
  String uuid;
  final Completer<void> ready = Completer();
  Map<String, dynamic>? metadata;
  String? _parent;
  DocumentType? _docType;

  RemarkableDocument({
    required this.metadataFile,
  }):
    uuid = metadataFile.data?[DocumentFileColumn.displayName].split(".")[0]
  {
    loadData();
  }

  Future<Widget> getThumbnailDoc() async {
    PartialDocumentFile? file = await fs.getThumbnail(uuid);
    if (file == null) return const Text("No thumbnail");

    Uint8List? data = await getDocumentContentBytes(
        file.metadata!.uri!
    );
    if(data == null) {
      return const Text("No thumbnail");
    }

    Image thumbnail = Image.memory(data, fit: BoxFit.contain);
    return thumbnail;
  }

  Future<Widget> getThumbnailFolder() async {
    List<RemarkableDocument>? children = await getChildren();
    if (children == null || children.isEmpty) {
      return const Center(
        child: Icon(Icons.folder, size: 100),
      );
    } else {
      List<Widget> images = await Future.wait(
        children.map((RemarkableDocument doc) => doc.getThumbnailDoc())
      );
      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        crossAxisCount: 2,
        children: images,
      );
    }
  }

  Future<Widget> getThumbnail() async {
    if (_docType == DocumentType.document) {
      return await getThumbnailDoc();
    } else {
      return await getThumbnailFolder();
    }
  }

  void loadData() async {
    String? metadataString = await getDocumentContentString(metadataFile.metadata!.uri!);
    if(metadataString != null) {
      metadata = json.decode(metadataString);
      if (metadata == null) return;

      _parent = metadata!["parent"];
      switch(metadata!["type"]) {
        case "CollectionType":
          _docType = DocumentType.collection;
          break;
        case "DocumentType":
          _docType = DocumentType.document;
          break;
      }
      ready.complete();
    }
  }

  Future<String> getName() async {
    await ready.future;
    return metadata!["visibleName"];
  }

  Future<String?> getParent() async {
    await ready.future;
    return _parent;
  }

  Future<List<RemarkableDocument>?> getChildren() async {
    if (_docType == DocumentType.document) {
      // Only folders can have children
      return null;
    } else {
      return await fs.getView(uuid);
    }
  }

  Future<DocumentType?> getDocType() async {
    await ready.future;
    return _docType;
  }

  Future<Map<String, dynamic>?> getMetadata() async {
    await ready.future;
    return metadata;
  }

  Future<Map<String, Uint8List?>> getData() async {
    return await fs.getData(uuid);
  }

  Future<Uri?> convertDocument() async {
    Map<String, Uint8List?> fileData = await getData();
    String docName = await getName();
    return await convertToPdf(uuid, docName, fileData);
  }



}