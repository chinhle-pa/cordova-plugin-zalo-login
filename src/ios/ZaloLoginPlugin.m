#import "ZaloLoginPlugin.h"
#import <objc/runtime.h>

@interface ZaloLoginPlugin()
@property (strong, nonatomic) NSString* dialogCallbackId;
@property (strong, nonatomic) FBSDKLoginManager *loginManager;
@property (strong, nonatomic) NSString* gameRequestDialogCallbackId;

- (NSDictionary *)responseObject;
- (NSDictionary*)parseURLParams:(NSString *)query;
- (BOOL)isPublishPermission:(NSString*)permission;
- (BOOL)areAllPermissionsReadPermissions:(NSArray*)permissions;
@end

@implementation ZaloLoginPlugin

- (void)pluginInitialize {
    NSLog(@"Starting Zalo Login plugin");
    // Add notification listener for tracking app activity with Zalo Events
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidFinishLaunching:)
                                                 name:UIApplicationDidFinishLaunchingNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
}

- (void) applicationDidFinishLaunching:(NSNotification *) notification {
    NSDictionary* launchOptions = notification.userInfo;
    if (launchOptions == nil) {
        //launchOptions is nil when not start because of notification or url open
        launchOptions = [NSDictionary dictionary];
    }

    [[ZDKApplicationDelegate sharedInstance] application:[UIApplication sharedApplication] didFinishLaunchingWithOptions:launchOptions];
}

- (void) applicationDidBecomeActive:(NSNotification *) notification {
    [FBSDKAppEvents activateApp];
}

#pragma mark - Cordova commands

- (void)login:(CDVInvokedUrlCommand *)command {
    NSLog(@"Starting login");
    [[ZaloSDK sharedInstance] authenticateZaloWithAuthenType:ZAZAloSDKAuthenTypeViaZaloAppOnly
                        parentController:self                        //controller hiện form đăng nhập
                        handler:^(ZOOauthResponseObject *response) { //callback kết quả đăng nhập
        if([response isSucess]) {
        // đăng nhập thành công
            NSString oauthCode* = tresponse.oauthCode;
        // có thể dùng oauth code này để verify lại từ server của ứng dụng
        } else if(response.errorCode != kZaloSDKErrorCodeUserCancel) {
        //lỗi đăng nhập
        }
    }];
}