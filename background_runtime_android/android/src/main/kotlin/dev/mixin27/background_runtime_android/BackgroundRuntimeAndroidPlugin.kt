package dev.mixin27.background_runtime_android

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

class BackgroundRuntimeAndroidPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private lateinit var downloadEventChannel: EventChannel
    private lateinit var playerStateEventChannel: EventChannel
    private lateinit var lifecycleEventChannel: EventChannel
    private lateinit var context: Context
    private var activityBinding: ActivityPluginBinding? = null

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "dev.mixin27.background_runtime/method")
        channel.setMethodCallHandler(this)

        downloadEventChannel = EventChannel(
            binding.binaryMessenger,
            "dev.mixin27.background_runtime/downloadEvents"
        )
        playerStateEventChannel = EventChannel(
            binding.binaryMessenger,
            "dev.mixin27.background_runtime/playerState"
        )
        lifecycleEventChannel = EventChannel(
            binding.binaryMessenger,
            "dev.mixin27.background_runtime/lifecycleEvents"
        )

        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "startDownload" -> handleStartDownload(call, result)
            "pauseDownload" -> handlePauseDownload(call, result)
            "resumeDownload" -> handleResumeDownload(call, result)
            "cancelDownload" -> handleCancelDownload(call, result)
            "playAudio" -> handlePlayAudio(call, result)
            "pauseAudio" -> handlePauseAudio(result)
            "resumeAudio" -> handleResumeAudio(result)
            "stopAudio" -> handleStopAudio(result)
            "seekAudio" -> handleSeekAudio(call, result)
            "shutdown" -> handleShutdown(result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        scope.launch {
            try {
                val config = call.argument<Map<String, Any?>>("config")
                BackgroundRuntimeServiceManager.initialize(context, config)
                result.success(null)
            } catch (e: Exception) {
                result.error("SERVICE_UNAVAILABLE", e.message, null)
            }
        }
    }

    private fun handleStartDownload(call: MethodCall, result: Result) {
        scope.launch {
            try {
                val request = call.argument<Map<String, Any?>>("request")
                val taskId = DownloadManager.startDownload(context, request)
                result.success(mapOf("taskId" to taskId))
            } catch (e: Exception) {
                result.error("DOWNLOAD_FAILED", e.message, null)
            }
        }
    }

    private fun handlePauseDownload(call: MethodCall, result: Result) {
        scope.launch {
            try {
                val taskId = call.argument<String>("taskId")
                DownloadManager.pauseDownload(taskId!!)
                result.success(null)
            } catch (e: Exception) {
                result.error("DOWNLOAD_FAILED", e.message, null)
            }
        }
    }

    private fun handleResumeDownload(call: MethodCall, result: Result) {
        scope.launch {
            try {
                val taskId = call.argument<String>("taskId")
                DownloadManager.resumeDownload(taskId!!)
                result.success(null)
            } catch (e: Exception) {
                result.error("DOWNLOAD_FAILED", e.message, null)
            }
        }
    }

    private fun handleCancelDownload(call: MethodCall, result: Result) {
        scope.launch {
            try {
                val taskId = call.argument<String>("taskId")
                DownloadManager.cancelDownload(taskId!!)
                result.success(null)
            } catch (e: Exception) {
                result.error("DOWNLOAD_FAILED", e.message, null)
            }
        }
    }

    private fun handlePlayAudio(call: MethodCall, result: Result) {
        scope.launch {
            try {
                val track = call.argument<Map<String, Any?>>("track")
                AudioPlayerManager.play(context, track!!)
                result.success(null)
            } catch (e: Exception) {
                result.error("SERVICE_UNAVAILABLE", e.message, null)
            }
        }
    }

    private fun handlePauseAudio(result: Result) {
        AudioPlayerManager.pause()
        result.success(null)
    }

    private fun handleResumeAudio(result: Result) {
        AudioPlayerManager.resume()
        result.success(null)
    }

    private fun handleStopAudio(result: Result) {
        AudioPlayerManager.stop()
        result.success(null)
    }

    private fun handleSeekAudio(call: MethodCall, result: Result) {
        val positionMillis = call.argument<Long>("positionMillis") ?: 0L
        AudioPlayerManager.seek(positionMillis)
        result.success(null)
    }

    private fun handleShutdown(result: Result) {
        scope.launch {
            try {
                BackgroundRuntimeServiceManager.shutdown(context)
                result.success(null)
            } catch (e: Exception) {
                result.error("SERVICE_UNAVAILABLE", e.message, null)
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivity() {
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activityBinding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding = null
    }
}
