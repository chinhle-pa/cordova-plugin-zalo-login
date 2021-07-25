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
    NSLog(@"Starting Zalo Login plugin");
    [[ZaloSDK sharedInstance] initializeWithAppId:@"2382863458001662740"];
    }

#pragma mark - Cordova commands

- (void)login:(CDVInvokedUrlCommand *)command {
    NSLog(@"Starting login");
        [[ZaloSDK sharedInstance] authenticateZaloWithAuthenType:ZAZaloSDKAuthenTypeViaZaloAppOnly
                            parentController:[self topMostController]                        //controller hiện form đăng nhập
                            handler:^(ZOOauthResponseObject *response) { //callback kết quả đăng nhập
            if([response isSucess]) {
            // đăng nhập thành công
                NSString *oauthCode = response.oauthCode;
                NSLog(@"%@ chinhle ma:", oauthCode);
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:[self responseObject]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            // có thể dùng oauth code này để verify lại từ server của ứng dụng
            } else if(response.errorCode != kZaloSDKErrorCodeUserCancel) {
            //lỗi đăng nhập
                NSLog(@"%ld chinh le error", response.errorCode);
                NSString *errorMessage = error.userInfo[FBSDKErrorLocalizedDescriptionKey] ?: @"There was a problem logging you in.";
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsString:errorMessage];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
            }
        }];
    // [self.commandDelegate runInBackground:^{
    //     __block CDVPluginResult *pluginResult;
    //     [[ZaloSDK sharedInstance] authenticateZaloWithAuthenType:ZAZaloSDKAuthenTypeViaZaloAppOnly
    //                         parentController:[self topMostController]                        //controller hiện form đăng nhập
    //                         handler:^(ZOOauthResponseObject *response) { //callback kết quả đăng nhập
    //         if([response isSucess]) {
    //         // đăng nhập thành công
    //             NSString *oauthCode = response.oauthCode;
    //             NSLog(@"%@", oauthCode);
    //             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
    //                                                     messageAsDictionary:response];
    //             [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    //         // có thể dùng oauth code này để verify lại từ server của ứng dụng
    //         } else if(response.errorCode != kZaloSDKErrorCodeUserCancel) {
    //         //lỗi đăng nhập
    //             NSLog(@"%ld", response.errorCode);
    //             pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
    //                                                     messageAsDictionary:response];
    //             [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    //         }
    //     }];
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
- (NSDictionary *)responseObject {

    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];
    // ZOOauthResponseObject *response = [ZOOauthResponseObject currentAccessToken];

    // NSTimeInterval expiresTimeInterval = token.expirationDate.timeIntervalSinceNow;
    // NSString *expiresIn = @"0";
    // if (expiresTimeInterval > 0) {
    //     expiresIn = [NSString stringWithFormat:@"%0.0f", expiresTimeInterval];
    // }


    result[@"status"] = @"connected";
    // result[@"authResponse"] = @{
    //                               @"accessToken" : token.tokenString ? token.tokenString : @"",
    //                               @"expiresIn" : expiresIn,
    //                               @"secret" : @"...",
    //                               @"session_key" : [NSNumber numberWithBool:YES],
    //                               @"sig" : @"...",
    //                               @"userID" : token.userID ? token.userID : @""
    //                               };


    return [result copy];
}

@end

#pragma mark - AppDelegate Overrides
@implementation AppDelegate (ZaloLoginPlugin)
- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url options:(nonnull NSDictionary<NSString *,id> *)options {
  return [[ZDKApplicationDelegate sharedInstance] application:application openURL:url options:options];
}
@end