#import "RaygunPlugin.h"
#import <raygun/raygun-Swift.h>
// #if __has_include(<raygun/raygun-Swift.h>)

// #else
// // Support project import fallback if the generated compatibility header
// // is not copied when this plugin is created as a library.
// // https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
// #import "raygun-Swift.h"
// #endif

@implementation RaygunPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRaygunPlugin registerWithRegistrar:registrar];
}
@end
