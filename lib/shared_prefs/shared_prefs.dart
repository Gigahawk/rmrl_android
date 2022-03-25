import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_storage/shared_storage.dart';
import 'package:tuple/tuple.dart';

const String srcFolderKey = 'srcFolderKey';
const String dstFolderKey = 'dstFolderKey';

Future<void> storeFolderPath(Uri? tree, bool srcSelect) async {
  if (tree == null) {
    return;
  }
  final prefs = await SharedPreferences.getInstance();
  String key = srcSelect ? srcFolderKey : dstFolderKey;
  await prefs.setString(key, tree.toString());
}

Future<Uri?> getFolderPath(bool srcSelect) async {
  final prefs = await SharedPreferences.getInstance();
  String key = srcSelect ? srcFolderKey : dstFolderKey;
  String? uriString = prefs.getString(key);
  if (uriString == null) {
    return null;
  }
  Uri? uri = Uri.parse(uriString);
  return uri;
}

Future<Tuple2<bool, Uri?>> checkFolderPath(bool srcSelect) async {
  Uri? uri = await getFolderPath(srcSelect);
  if (uri == null) {
    return const Tuple2(false, null);
  }
  bool isPersisted = await isPersistedUri(uri);
  return Tuple2(isPersisted, uri);
}
