#import "ZaloLoginPlugin.h"
#import <objc/runtime.h>
#import "AppDelegate.h"

@interface ZaloLoginPlugin()
@property (strong, nonatomic) NSString* dialogCallbackId;
@property (strong, nonatomic) NSString* gameRequestDialogCallbackId;
- (NSDictionary *)responseObject;
@end

@implementation ZaloLoginPlugin

- (void)pluginInitialize {
    // NSLog(@"Starting Zalo Login plugin");
    [[ZaloSDK sharedInstance] initializeWithAppId:@"3552157261157599875"];
    }

#pragma mark - Cordova commands

- (void)login:(CDVInvokedUrlCommand *)command {
    NSLog(@"Starting login");
        [[ZaloSDK sharedInstance] authenticateZaloWithAuthenType:ZAZAloSDKAuthenTypeViaZaloAppAndWebView
                            parentController:[self topMostController]                        //controller hiện form đăng nhập
                            handler:^(ZOOauthResponseObject *response) { //callback kết quả đăng nhập
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:[self createResponseObject:response]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            if([response isSucess]) {
                // đăng nhập thành công
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:[self createResponseObject:response]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            } else {
                //lỗi đăng nhập
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                          messageAsDictionary:[self createResponseObject:response]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            }
        }];
    // [self.commandDelegate runInBackground:^{
    // }];
}
#pragma mark - Utility methods
- (UIViewController*) topMostController {
    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;

    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }

    return topController;
}
- (NSDictionary *) createResponseObject:(ZOOauthResponseObject *)response {
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    if(response.errorCode >= 0){
        result[@"status"] = @"connected";
    } else {
        result[@"status"] = @"error";
    }

    result[@"authResponse"] = @{
                                  @"errorCode" : [NSString stringWithFormat:@"%ld", response.errorCode],
                                  @"errorMessage" : response.errorMessage ? response.errorMessage : @"",
                                  @"oauthCode" : response.oauthCode ? response.oauthCode : @"",
                                  @"userId" : response.userId ? response.userId : @"",
                                  @"displayName" : response.displayName ? response.displayName : @"",
                                  @"dob" : response.dob ? response.dob : @"",
                                  @"gender": response.gender ? response.gender : @""
                                  };
    return [result copy];
}
@end

#pragma mark - AppDelegate Overrides
@implementation AppDelegate (ZaloLoginPlugin)
- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<NSString *,id> *)options {
  return [[ZDKApplicationDelegate sharedInstance] application:application openURL:url options:options];
}
// - (BOOL)application:(UIApplication *)application
//  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//     NSLog(@"Starting Zalo Login plugin");
//     [[ZaloSDK sharedInstance] initializeWithAppId:kZALO_SDK_APP_ID];
//     return YES;
// }
@end