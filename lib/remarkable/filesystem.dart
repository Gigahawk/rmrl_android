import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:flutter/cupertino.dart';
import 'package:rmrl_android/remarkable/document.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:stream_transform/stream_transform.dart';

import '../shared_prefs/shared_prefs.dart';

class RemarkableFileSystem {
  static const Duration watchDogInterval = Duration(milliseconds: 500);
  List<RemarkableDocument> documents = [];
  final List<PartialDocumentFile> _rawFiles = [];
  Uri? rootUri;
  final StreamController<void> _notifier = StreamController<void>.broadcast();
  Stream<void> get notifier => _notifier.stream;
  final Completer<void> _ready = Completer();
  Future<void> get ready =>_ready.future;
  RestartableTimer? watchDog;

  static final RemarkableFileSystem _remarkableFileSystem = RemarkableFileSystem._internal();

  factory RemarkableFileSystem() {
    return _remarkableFileSystem;
  }

  RemarkableFileSystem._internal() {
    _loadFiles();
  }

  void _loadFiles() async {
    rootUri = await getFolderPath(true);
    final DocumentFile? df = await rootUri?.toDocumentFile();

    final columns = [
      DocumentFileColumn.displayName,
      DocumentFileColumn.size,
      DocumentFileColumn.lastModified,
      DocumentFileColumn.id,
      DocumentFileColumn.mimeType,
    ];

    // Use a watchdog to indicate when no more files are read,
    // since listFiles() doesn't ever call done.
    // Consumers should first await ready, then listen to notifier to know when
    // to update.
    watchDog = RestartableTimer(watchDogInterval, () { _ready.complete(); });
    df?.listFiles(columns).listen(
        (PartialDocumentFile file){
          watchDog!.reset();
          String fileName = file.data?[DocumentFileColumn.displayName];
          _rawFiles.add(file);

          if (file.metadata?.isDirectory == false && fileName.endsWith("metadata")) {
            RemarkableDocument doc = RemarkableDocument(metadataFile: file);
            documents.add(doc);
            _notifier.sink.add(null);
          }
        }
    );
  }

  Future<List<RemarkableDocument>> getView(String parent) async {
    return Stream.fromIterable(documents).asyncWhere(
        (RemarkableDocument doc) async {
          String? docParent = await doc.getParent();
          return docParent == parent;
        }
    ).toList();
  }

  Future<PartialDocumentFile?> getThumbnail(String uuid, {int idx = 0}) async {
    List<PartialDocumentFile> thumbNails = _rawFiles.where(
        (PartialDocumentFile file) {
          Uri? parentUri = file.metadata?.parentUri;
          String fileName = file.data?[DocumentFileColumn.displayName];
          String thumbnailsPath = "$uuid.thumbnails";
          bool isJpeg = fileName.endsWith(".jpg") || fileName.endsWith(".jpeg");
          bool isPathCorrect = parentUri?.path.endsWith(thumbnailsPath) ?? false;
          if (isJpeg && isPathCorrect) {
            return true;
          }
          return false;
        }).toList();

    if(thumbNails.isEmpty) return null;
    return thumbNails[idx];
  }

  String getFullPath(PartialDocumentFile file) {
    Uri? parentUri = file.metadata?.parentUri;
    String parentPath = parentUri?.path ?? "";
    Uri? rootUri = file.metadata?.rootUri;
    String rootPath = rootUri?.path ?? "";
    String fileName = file.data?[DocumentFileColumn.displayName];

    String parent = parentPath.substring(rootPath.length);

    if(parent.isNotEmpty) {
      parent = parent.substring(3);
      return "$parent/$fileName";
    }

    return fileName;
  }

  Future<Map<String, Uint8List?>> getData(String uuid) async {
    Iterable<PartialDocumentFile> files = _rawFiles.where(
      (PartialDocumentFile file) {
        if (!(file.metadata?.isDirectory ?? false)) {
          String fullPath = getFullPath(file);
          if (fullPath.contains(uuid)) {
            return true;
          }
        }
        return false;
    });

    Map<String, Uint8List?> fileMap = {
      for (PartialDocumentFile file in files) 
        getFullPath(file) : await getDocumentContentBytes(file.metadata!.uri!)
    };

    return fileMap;
  }
}