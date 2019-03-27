# raygun

This is written in swift
when you create the flutter project use -i swift option

## iOS configuration

nothing to be done

## Android configuration

add below to AndroidManifest.xml

```xml
 <service   android:name="main.java.com.mindscapehq.android.raygun4android.RaygunPostService"
           android:exported="false"
           android:process=":raygunpostservice"/>
```

## Usage

### Setup

setup Api Key

```dart
FlutterRaygun().initialize('Raygun Api Key here')
```

### Log Exception

Log exception to raygun

```dart
FlutterRaygun().logException(exception, stacktrace)
```

### Log

Log to raygun

```dart
FlutterRaygun().log("log here" send: true, tags:["tag1", "tag2"])
```
