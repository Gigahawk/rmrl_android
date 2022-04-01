
import 'dart:async';
import 'dart:convert';

import 'package:shared_storage/shared_storage.dart';

enum DocumentType {
  document,
  collection
}

class RemarkableDocument {
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

  Future<DocumentType?> getDocType() async {
    await ready.future;
    return _docType;
  }

  Future<Map<String, dynamic>?> getMetadata() async {
    await ready.future;
    return metadata;
  }



}