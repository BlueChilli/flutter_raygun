package com.bluechilli.plugin.raygun

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.PluginRegistry.Registrar
import main.java.com.mindscapehq.android.raygun4android.RaygunClient
import main.java.com.mindscapehq.android.raygun4android.RaygunOnBeforeSend
import main.java.com.mindscapehq.android.raygun4android.messages.RaygunMessage
import main.java.com.mindscapehq.android.raygun4android.messages.RaygunUserInfo
import android.content.pm.PackageManager


class RaygunPlugin(private val context: Activity): MethodCallHandler, RaygunOnBeforeSend {

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
        RaygunClient.setOnBeforeSend(this)

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

    override fun onBeforeSend(message: RaygunMessage?): RaygunMessage {

        if(message != null) {

            val packageManager = context.getPackageManager()

            try
            {
                val packageInfo = packageManager.getPackageInfo(context.application.packageName, 0)
                val applicationName = context.applicationInfo.loadLabel(packageManager).toString()

                if(message.details.userCustomData == null) {
                    message.details.userCustomData = HashMap<String, Any>()
                }

                message.details.userCustomData.put("appVersion", packageInfo.versionName)
                message.details.userCustomData.put("appName", applicationName)
                message.details.userCustomData.put("buildNumber", packageInfo.versionCode)
                message.details.userCustomData.put("firstInstallTime", packageInfo.firstInstallTime)
                message.details.userCustomData.put("lastUpdateTime", packageInfo.lastUpdateTime)

            }
            catch (e:PackageManager.NameNotFoundException) {
                e.printStackTrace();
            }

            return message
        }
        else {
            return RaygunMessage()
        }
    }

    override fun OnBeforeSend(message: RaygunMessage?): RaygunMessage {
        return onBeforeSend(message)
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
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
