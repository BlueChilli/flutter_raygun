package com.bluechilli.plugin.raygun

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar
import main.java.com.mindscapehq.android.raygun4android.messages.RaygunUserInfo
import main.java.com.mindscapehq.android.raygun4android.RaygunClient


class RaygunPlugin(private val context: Activity): MethodCallHandler {

  val RAYGUN_TAG:String = "FlutterRaygun";

  var isInitialized:Boolean = false

  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val channel = MethodChannel(registrar.messenger(), "flutter_raygun")
      channel.setMethodCallHandler(RaygunPlugin(registrar.activity()))
    }
  }


  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "initialize" -> {
        val args = call.arguments as Map<String, Any>
        val apikey = args["apikey"] as String
        val pulse = args["pulse"] as Boolean
        val networkLogging = args["networkLogging"] as Boolean

        RaygunClient.init(context, apikey)

        val packageManager = context.packageManager
        val packageInfo = packageManager.getPackageInfo(context.application.packageName, 0)
        val applicationName = context.applicationInfo.loadLabel(packageManager).toString()

        RaygunClient.setOnBeforeSend(FlutterRaygunBeforeSend(packageInfo, applicationName))

        if(pulse) {
          RaygunClient.attachPulse(context, networkLogging)
        }

        RaygunClient.attachExceptionHandler()
        isInitialized = true

        result.success(null)
      }
      else -> {
        if(isInitialized) {
          onInitialisedMethodCall(call, result)
        } else {
          // Should not result in an error. Otherwise Opt Out clients would need to handle errors
          result.success(null)
        }
      }
    }
  }


  private fun onInitialisedMethodCall(call: MethodCall, result: Result) {
    when {
      call.method == "log" -> {
        val info = call.arguments as Map<String, Any>
        val send = info["send"] as Boolean
        val msg = info["message"] as String
        val tags = info["tags"] as List<String>

        if(send) {
          var tagItems = listOf(RAYGUN_TAG, "log")
          RaygunClient.send(FlutterLogException(msg), tagItems.plus(tags))
        }

        Log.i(RAYGUN_TAG, msg)

        result.success(null)
      }
      call.method == "setInfo" -> {

        val info = call.arguments as Map<String, Any>
        RaygunClient.setUserCustomData(info)
        result.success(null)
      }
      call.method == "setUserInfo" -> {
        val info = call.arguments as Map<String, String>
        val userInfo = RaygunUserInfo(
                info["id"],
                info["firstname"],
                info["email"],
                info["name"],
                null,
                false
        )

        RaygunClient.setUser(userInfo)
        result.success(null)
      }
      call.method == "reportCrash" -> {
        val exception = (call.arguments as Map<String, Any>)
        val forceCrash = exception["forceCrash"] as? Boolean ?: false

        val throwable = Utils.create(exception)

        if (forceCrash) {
          RaygunClient.send(throwable)
        } else {
          RaygunClient.send(throwable)
        }
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }
}
