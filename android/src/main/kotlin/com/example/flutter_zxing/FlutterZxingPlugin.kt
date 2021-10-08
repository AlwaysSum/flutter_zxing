package com.example.flutter_zxing

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.util.Log
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.FlutterPlugin.FlutterPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.concurrent.Callable
import java.util.concurrent.FutureTask

/** FlutterZxingPlugin */
class FlutterZxingPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var flutterPluginBinding: FlutterPluginBinding? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        this.flutterPluginBinding = flutterPluginBinding
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_zxing")
        channel.setMethodCallHandler(this)
    }

    /**
     * method call handle
     */
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${Build.VERSION.RELEASE}")
            }
            "decodeImageByte" -> {
                val bytes = call.argument<ByteArray>("data")
                val width = call.argument<Int>("width")
                val height = call.argument<Int>("height")
                Log.e("@TSET", "bytes:$bytes")
                Log.e("@TSET", "bytes size:${bytes?.size}")
                Log.e("@TSET", "width:$width")
                Log.e("@TSET", "height:$height")
                if (bytes != null && width != null && height != null) {
                    var task = FutureTask(QrCodeReadByteTask(bytes, width, height))
                    Thread(task).start()
                    onReturnCode(task.get(), result)
                } else {
                    result.success("")
                }
            }
            "decodeImagePath" -> {
                val path = call.argument<String>("data") ?: ""
                var task = FutureTask(QrCodeTask(this, path))
                Thread(task).start()
                onReturnCode(task.get(), result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    /**
     * 扫码解析
     */
    internal class QrCodeTask(val plugin: FlutterZxingPlugin, private val path: String) :
        Callable<String?> {
        override fun call(): String? {
            return QRCodeDecoder.decodeQRCode(
                plugin.flutterPluginBinding?.applicationContext,
                path
            )
        }
    }

    internal class QrCodeReadByteTask(
        private val data: ByteArray,
        private val width: Int,
        private val height: Int
    ) :
        Callable<String?> {
        override fun call(): String? {
            return QRCodeDecoder.decodeImageQRCodeByte(
                data,
                width,
                height
            )
        }
    }

    private fun onReturnCode(code: String?, result: Result) {
        code?.let {
            val myVib = flutterPluginBinding?.applicationContext?.getSystemService(
                Context.VIBRATOR_SERVICE
            ) as Vibrator
            myVib?.let { vibrator ->
                if (Build.VERSION.SDK_INT >= 26) {
                    vibrator.vibrate(
                        VibrationEffect.createOneShot(
                            50,
                            VibrationEffect.DEFAULT_AMPLITUDE
                        )
                    )
                } else {
                    vibrator.vibrate(50)
                }
            }
        }
        result.success(code ?: "")
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        flutterPluginBinding = null
    }

}
