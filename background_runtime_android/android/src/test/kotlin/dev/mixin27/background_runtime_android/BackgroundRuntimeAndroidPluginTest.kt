package dev.mixin27.background_runtime_android

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.mockito.Mockito
import kotlin.test.Test

internal class BackgroundRuntimeAndroidPluginTest {

    @Test
    fun onMethodCall_unknownMethod_returnsNotImplemented() {
        val plugin = BackgroundRuntimeAndroidPlugin()
        val call = MethodCall("unknownMethod", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)
        Mockito.verify(mockResult).notImplemented()
    }
}
