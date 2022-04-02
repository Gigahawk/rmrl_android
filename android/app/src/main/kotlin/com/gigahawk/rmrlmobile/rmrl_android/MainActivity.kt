package com.gigahawk.rmrlmobile.rmrl_android

import android.annotation.TargetApi
import android.content.ContentUris
import android.content.Context
import android.content.SharedPreferences
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.os.Build.VERSION_CODES
import android.os.Bundle
import android.os.Environment
import android.os.PersistableBundle
import android.provider.DocumentsContract
import android.provider.MediaStore
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.chaquo.python.PyException
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.gigahawk.rmrl_android"

    override fun onCreate(savedInstanceState: Bundle?, persistentState: PersistableBundle?) {
        super.onCreate(savedInstanceState, persistentState)
        if(!Python.isStarted()) {
            Python.start(AndroidPlatform(this))
        }
    }

    @RequiresApi(VERSION_CODES.LOLLIPOP)
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "getFolderPathStringFromUriString" -> {
                    val uriString: String = call.argument<String>("uri")!!
                    result.success(getFolderPathStringFromUriString(uriString))
                }
                "isAcceptableFolderUriString" -> {
                    val uriString: String = call.argument<String>("uri")!!
                    result.success(isAcceptableFolderUriString(uriString))
                }
                "convertToPdf" -> {
                    val uuid: String? = call.argument<String>("uuid")
                    val fileData: HashMap<String, ByteArray?>? =
                        call.argument<HashMap<String, ByteArray?>>("fileData")
                    val docName: String? = call.argument<String>("docName")

                    if (uuid == null || docName == null || fileData == null) {
                        result.error("argsError", "missing args", null)
                    } else {
                        convertDocument(uuid, docName, fileData)
                        result.success(null)
                    }
                }
                else -> {
                    result.notImplemented();
                }
            }
        }
    }

    @RequiresApi(VERSION_CODES.LOLLIPOP)
    private fun convertDocument(uuid: String, docName: String, fileData: HashMap<String, ByteArray?>) {
        val py = Python.getInstance()
        val module: PyObject = py.getModule("convert")
        val source: PyObject =  module.callAttr("ChaquopySource", uuid)

        for((path: String, data: ByteArray?) in fileData) {
            if(data != null) {
                source.callAttr("insert_file", path, data)
                Log.i("convert", "adding file")
                Log.i("convert", path)
            } else {
                Log.w("convert", "File is empty?")
                Log.w("convert", path)
            }
        }

        val pdf: ByteArray = module.callAttr("convert", source).toJava(ByteArray::class.java)

        Log.i("convert", "writing to output dir")
        val sp: SharedPreferences = context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
        val outPathUriStr: String = sp.getString(
            "flutter." + "dstFolderKey", null) ?: return
        val outPathUri: Uri = getUriFromString(outPathUriStr)
        val outFileUri: Uri = DocumentsContract.createDocument(
            context.contentResolver,
            outPathUri,
            "application/pdf",
            docName
        ) ?: return

        contentResolver.openFileDescriptor(outFileUri, "w")?.use {
            FileOutputStream(it.fileDescriptor).use { it ->
                it.write(pdf)
            }
        }
        return
    }

    @RequiresApi(VERSION_CODES.LOLLIPOP)
    private fun getUriFromString(uriString: String) : Uri {
        val treeUri = Uri.parse(uriString)
        val docUri = DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri)
        )
        return docUri
    }

    @RequiresApi(VERSION_CODES.LOLLIPOP)
    private fun getFolderPathStringFromUriString(uriString: String) : String {
        val docUri = getUriFromString(uriString)
        return getPath(this, docUri)!!
    }

    @RequiresApi(VERSION_CODES.LOLLIPOP)
    private fun isAcceptableFolderUriString(uriString: String) : Boolean {
        val docUri = getUriFromString(uriString)
        return isAcceptableFolderUri(this, docUri)
    }

    @RequiresApi(VERSION_CODES.KITKAT)
    fun isAcceptableFolderUri(context: Context, uri: Uri): Boolean {
        val isKitKat: Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT

        // DocumentProvider
        if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            return isExternalStorageDocument(uri)
        }
        return false
    }

    @TargetApi(VERSION_CODES.KITKAT)
    fun getPath(context: Context, uri: Uri): String? {
        val isKitKat: Boolean = Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT

        // DocumentProvider
        if (isKitKat && DocumentsContract.isDocumentUri(context, uri)) {
            // ExternalStorageProvider
            if (isExternalStorageDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":").toTypedArray()
                val type = split[0]
                if ("primary".equals(type, ignoreCase = true)) {
                    return Environment.getExternalStorageDirectory().toString() + "/" + split[1]
                }

                // TODO handle non-primary volumes
            } else if (isDownloadsDocument(uri)) {
                val id = DocumentsContract.getDocumentId(uri)
                val contentUri: Uri = ContentUris.withAppendedId(
                    Uri.parse("content://downloads/public_downloads"), (id.filter { it.isDigit() }).toLong()
                )
                return getDataColumn(context, contentUri, null, null)
            } else if (isMediaDocument(uri)) {
                val docId = DocumentsContract.getDocumentId(uri)
                val split = docId.split(":").toTypedArray()
                val type = split[0]
                var contentUri: Uri? = null
                if ("image" == type) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
                } else if ("video" == type) {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI
                } else if ("audio" == type) {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI
                }
                val selection = "_id=?"
                val selectionArgs = arrayOf(
                    split[1]
                )
                return getDataColumn(context, contentUri, selection, selectionArgs)
            }
        } else if ("content".equals(uri.scheme, ignoreCase = true)) {

            // Return the remote address
            return if (isGooglePhotosUri(uri)) uri.lastPathSegment else getDataColumn(
                context,
                uri,
                null,
                null
            )
        } else if ("file".equals(uri.scheme, ignoreCase = true)) {
            return uri.path
        }
        return null
    }

    fun getDataColumn(
        context: Context, uri: Uri?, selection: String?,
        selectionArgs: Array<String>?
    ): String? {
        var cursor: Cursor? = null
        val column = "_data"
        val projection = arrayOf(
            column
        )
        try {
            cursor = context.contentResolver.query(
                uri!!, projection, selection, selectionArgs,
                null
            )
            if (cursor != null && cursor.moveToFirst()) {
                val index: Int = cursor.getColumnIndexOrThrow(column)
                return cursor.getString(index)
            }
        } finally {
            if (cursor != null) cursor.close()
        }
        return null
    }


    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    fun isExternalStorageDocument(uri: Uri): Boolean {
        return "com.android.externalstorage.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    fun isDownloadsDocument(uri: Uri): Boolean {
        return "com.android.providers.downloads.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    fun isMediaDocument(uri: Uri): Boolean {
        return "com.android.providers.media.documents" == uri.authority
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is Google Photos.
     */
    fun isGooglePhotosUri(uri: Uri): Boolean {
        return "com.google.android.apps.photos.content" == uri.authority
    }

}
