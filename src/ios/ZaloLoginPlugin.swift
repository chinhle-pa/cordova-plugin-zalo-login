import Foundation
import ZaloSDK

@objc(ZaloLoginPlugin) class ZaloLoginPlugin : CDVPlugin {
    override func pluginInitialize() {
        let appID = Bundle.main.infoDictionary?["appID"] as? String
        ZaloSDK.sharedInstance().initialize(withAppId: appID)
    }
  @objc(echo:)
  func echo(command: CDVInvokedUrlCommand) {
    var pluginResult = CDVPluginResult(
      status: CDVCommandStatus_ERROR
    )

    let msg = command.arguments[0] as? String ?? ""

    if msg.count > 0 {
      let toastController: UIAlertController =
        UIAlertController(
          title: "",
          message: msg,
          preferredStyle: .alert
        )
      
      self.viewController?.present(
        toastController,
        animated: true,
        completion: nil
      )

      DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
        toastController.dismiss(
          animated: true,
          completion: nil
        )
      }
        
      pluginResult = CDVPluginResult(
        status: CDVCommandStatus_OK,
        messageAs: msg
      )
    }

    self.commandDelegate!.send(
      pluginResult,
      callbackId: command.callbackId
    )
  }
  @objc(login:)
    func login(command: CDVInvokedUrlCommand) {
        AuthenUtils.shared.renewPKCECode()
        ZaloSDK.sharedInstance().authenticateZalo(with: ZAZAloSDKAuthenTypeViaZaloAppAndWebView, parentController: self.viewController, codeChallenge: AuthenUtils.shared.getCodeChallenge(), extInfo: [
        "appVersion": "1.0.0",
    ]) { (response) in
            self.onAuthenticateComplete(with: response)
        }
    }

    func onAuthenticateComplete(with response: ZOOauthResponseObject?) {
        // loadingIndicator.stopAnimating()
        // loginButton.isHidden = false
        
        if response?.isSucess == true {
            getAccessTokenFromOAuthCode(response?.oauthCode);
        } else if let response = response,
                response.errorCode != -1001 { // not cancel
            // showAlert(with: "Error \(response.errorCode)", message: response.errorMessage ?? "")
            let toastController: UIAlertController =
                UIAlertController(
                title: "",
                message: response.errorMessage,
                preferredStyle: .alert
                )
            
            self.viewController?.present(
                toastController,
                animated: true,
                completion: nil
            )

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                toastController.dismiss(
                animated: true,
                completion: nil
                )
            }
        }
    }

    private func getAccessTokenFromOAuthCode(_ oauthCode: String?) {
        ZaloSDK.sharedInstance().getAccessToken(withOAuthCode: oauthCode, codeVerifier: AuthenUtils.shared.getCodeVerifier()) { (tokenResponse) in
            AuthenUtils.shared.saveTokenResponse(tokenResponse)
            if let tokenResponse = tokenResponse {
                print("""
                      getAccessTokenFromOAuthCode:
                      accessToken: \(tokenResponse.accessToken ?? "")
                      refreshToken: \(tokenResponse.refreshToken ?? "")
                      expriedTime: \(tokenResponse.expriedTime)
                      """)
                // self.showMainController()
            } else {
                // showAlert(with: "Get AccessToken from OauthCode error \(tokenResponse?.errorCode ?? ZaloSDKErrorCode.sdkErrorCodeUnknownException.rawValue)", message: tokenResponse?.errorMessage ?? "")
                let toastController: UIAlertController =
                    UIAlertController(
                    title: "",
                    message: tokenResponse?.errorMessage,
                    preferredStyle: .alert
                    )
                
                self.viewController?.present(
                    toastController,
                    animated: true,
                    completion: nil
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    toastController.dismiss(
                    animated: true,
                    completion: nil
                    )
                }
            }
        }
    }
    // private func showAlert(with title: String = "ZaloSDK", message: String) {
    //     let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
    //     let action = UIAlertAction(title: "OK", style: .default) { (action) in
    //         controller.dismiss(animated: true, completion: nil)
    //     }
    //     controller.addAction(action)
    //     self.present(controller, animated: true, completion: nil)
    // }

}



// @UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
 
        /// 0a. Init zalo sdk
        // let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let appID = Bundle.main.infoDictionary?["appID"] as? String
        ZaloSDK.sharedInstance().initialize(withAppId: appID)
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        /// 0b. Receive callback from zalo
        return ZDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }

    
    // func _customNavigationBarForiOS15() {
    //     if #available(iOS 15.0, *) {
    //         let navigationBarAppearance = UINavigationBarAppearance()
    //         navigationBarAppearance.configureWithDefaultBackground()
    //         navigationBarAppearance.backgroundColor = UIColor(red: 0, green: 143.0/255.0, blue: 243.0/255.0, alpha: 255/255.0)
    //         navigationBarAppearance.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
    //         UINavigationBar.appearance().tintColor = .white;
    //         UINavigationBar.appearance().standardAppearance = navigationBarAppearance
    //         UINavigationBar.appearance().compactAppearance = navigationBarAppearance
    //         UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance
    //     }

    // }
}

enum UserDefaultsKeys: String, CaseIterable {
    case refreshToken = "refreshToken"
    case accessToken = "accessToken"
    case expriedTime = "expriedTime"
}

#if os(Linux)
import Crypto
#else
import CommonCrypto
#endif

public func generateState(withLength len: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let length = UInt32(letters.count)

    var randomString = ""
    for _ in 0..<len {
        let rand = arc4random_uniform(length)
        let idx = letters.index(letters.startIndex, offsetBy: Int(rand))
        let letter = letters[idx]
        randomString += String(letter)
    }
    return randomString
}

/// Generating a code verifier for PKCE
public func generateCodeVerifier() -> String? {
    var buffer = [UInt8](repeating: 0, count: 32)
    _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
   let codeVerifier = Data(buffer).base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
        .trimmingCharacters(in: .whitespaces)

    return codeVerifier
}

/// Generating a code challenge for PKCE
public func generateCodeChallenge(codeVerifier: String?) -> String? {
    guard let verifier = codeVerifier, let data = verifier.data(using: .utf8) else { return nil }

    #if !os(Linux)
    var buffer = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &buffer)
    }
    let hash = Data(buffer)
    #else
    let buffer = [UInt8](repeating: 0, count: SHA256.byteCount)
    let sha = Array(HMAC<SHA256>.authenticationCode(for: buffer, using: SymmetricKey(size: .bits256)))
    let hash = Data(sha)
    #endif

    let challenge = hash.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
        .trimmingCharacters(in: .whitespaces)

    return challenge
}


class AuthenUtils {

    static let shared = AuthenUtils()
    var tokenResponse: ZOTokenResponseObject?
    var codeChallenage = ""
    var codeVerifier = ""
    

    func getAccessToken(_ completionHandler: @escaping (String?) -> ()) {
        let now = TimeInterval(Date().timeIntervalSince1970 - 10)
        if let tokenResponse = tokenResponse,
           let accessToken = tokenResponse.accessToken, !accessToken.isEmpty,
           tokenResponse.expriedTime > now {

            completionHandler(accessToken)
            return
        }
        let refreshToken = UserDefaults.standard.string(forKey: UserDefaultsKeys.refreshToken.rawValue)
        ZaloSDK.sharedInstance().getAccessToken(withRefreshToken: refreshToken) { (response) in
            self.saveTokenResponse(response)
            completionHandler(response?.accessToken)
        }
    }

    func saveTokenResponse(_ tokenResponse: ZOTokenResponseObject?) {
        guard let tokenResponse = tokenResponse else {
            return
        }
        self.tokenResponse = tokenResponse
        let userDefault = UserDefaults.standard
        userDefault.set(tokenResponse.accessToken, forKey: UserDefaultsKeys.accessToken.rawValue)
        userDefault.set(tokenResponse.refreshToken, forKey: UserDefaultsKeys.refreshToken.rawValue)
    }
    
    func logout() {
        let allKeys = UserDefaultsKeys.allCases;
        let userDefault = UserDefaults.standard
        for key in allKeys {
            userDefault.removeObject(forKey: key.rawValue)
        }
        self.tokenResponse = nil
    }
    
    func getCodeChallenge() -> String {
        return self.codeChallenage
    }
    
    func getCodeVerifier() -> String {
        return self.codeVerifier
    }
    
    func renewPKCECode() {
        self.codeVerifier = generateCodeVerifier() ?? ""
        self.codeChallenage = generateCodeChallenge(codeVerifier: self.codeVerifier) ?? ""
    }
}
