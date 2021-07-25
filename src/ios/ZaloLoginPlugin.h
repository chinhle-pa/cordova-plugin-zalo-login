#import <Cordova/CDV.h>
#import "AppDelegate.h"
#import <ZaloSDK/ZaloSDK.h>

@interface ZaloLoginPlugin: CDVPlugin
- (void)login:(CDVInvokedUrlCommand *)command;
@end