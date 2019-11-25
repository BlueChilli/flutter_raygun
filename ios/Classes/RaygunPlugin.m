#import "RaygunPlugin.h"
#if __has_include(<raygun/raygun-Swift.h>)
#import <raygun/raygun-Swift.h>
#else
#import "raygun-Swift.h"
#endif


@implementation RaygunPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRaygunPlugin registerWithRegistrar:registrar];
}
@end
