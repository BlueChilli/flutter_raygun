package com.bluechilli.plugin.raygun

import android.app.Activity
import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import main.java.com.mindscapehq.android.raygun4android.RaygunOnBeforeSend
import main.java.com.mindscapehq.android.raygun4android.messages.RaygunMessage

class FlutterRaygunBeforeSend(private val packageInfo: PackageInfo, private val applicationName: String) : RaygunOnBeforeSend {

    override fun onBeforeSend(message: RaygunMessage?): RaygunMessage {

        if(message != null) {

            try
            {
                if(message.details.userCustomData == null) {
                    message.details.userCustomData = HashMap<String, Any>()
                }

                message.details.userCustomData.put("appVersion", packageInfo.versionName)
                message.details.userCustomData.put("appName", applicationName)
                message.details.userCustomData.put("buildNumber", packageInfo.versionCode)
                message.details.userCustomData.put("firstInstallTime", packageInfo.firstInstallTime)
                message.details.userCustomData.put("lastUpdateTime", packageInfo.lastUpdateTime)

            }
            catch (e: PackageManager.NameNotFoundException) {
                e.printStackTrace()
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


}