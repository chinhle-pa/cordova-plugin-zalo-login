#import <Cordova/CDV.h>
#import "AppDelegate.h"

@interface ZaloLoginPlugin: CDVPlugin <>
- (void)login:(CDVInvokedUrlCommand *)command;
@end