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
        [[ZaloSDK sharedInstance] authenticateZaloWithAuthenType:ZAZAloSDKAuthenTypeViaZaloAppAndWebView
                            parentController:[self topMostController]                        //controller hiện form đăng nhập
                            handler:^(ZOOauthResponseObject *response) { //callback kết quả đăng nhập
            if([response isSucess]) {
            // đăng nhập thành công
                // NSString *oauthCode = response.oauthCode;
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK
                                                          messageAsDictionary:[self createResponseObject:response]];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
            // có thể dùng oauth code này để verify lại từ server của ứng dụng
            } else if(response.errorCode != kZaloSDKErrorCodeUserCancel) {
            //lỗi đăng nhập
                NSString *errorMessage = [NSString stringWithFormat: @"%ld",response.errorCode];
                CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                                messageAsString:errorMessage];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
                return;
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
@end