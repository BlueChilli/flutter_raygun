#import "RaygunPlugin.h"
#import <raygun/raygun-Swift.h>

@implementation RaygunPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftRaygunPlugin registerWithRegistrar:registrar];
}
@end
