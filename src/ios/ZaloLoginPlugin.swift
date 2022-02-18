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
    ]) { [self](response) in
            self.onAuthenticateComplete(with: response, command: command)
        }
    }

    func onAuthenticateComplete(with response: ZOOauthResponseObject?, command: CDVInvokedUrlCommand) {
        if response?.isSucess == true {
            getAccessTokenFromOAuthCode(response?.oauthCode, command: command);
        } else if let response = response,
            response.errorCode != -1001 { // not cancel
            // showAlert(with: "Error \(response.errorCode)", message: response.errorMessage ?? "")
            let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: createErrorResponseObject(response:response))
            self.commandDelegate.send(result, callbackId: command.callbackId)
            return
        }
    }

    private func getAccessTokenFromOAuthCode(_ oauthCode: String?, command: CDVInvokedUrlCommand) {
        ZaloSDK.sharedInstance().getAccessToken(withOAuthCode: oauthCode, codeVerifier: AuthenUtils.shared.getCodeVerifier()) {[self] (tokenResponse) in
            AuthenUtils.shared.saveTokenResponse(tokenResponse)
            if let tokenResponse = tokenResponse {
                if let accessToken = tokenResponse.accessToken {
                ZaloSDK.sharedInstance().getZaloUserProfile(withAccessToken: accessToken) { (response) in
                    self.onLoad(profile: response, command: command)
                }
            }
            } else {
                showAlert(with: "Get AccessToken from OauthCode error \(tokenResponse?.errorCode ?? ZaloSDKErrorCode.sdkErrorCodeUnknownException.rawValue)", message: tokenResponse?.errorMessage ?? "")
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: createErrorResponseObject(response:tokenResponse))
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }
        }
    }

    func onLoad(profile: ZOGraphResponseObject?, command : CDVInvokedUrlCommand) {
        guard let profile = profile,
            profile.isSucess
            else {
                showAlert(with: "Error", message: "Get profile error")
                let result = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: createResponseObject(response:profile))
                self.commandDelegate.send(result, callbackId: command.callbackId)
                return
            }

            let result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: createResponseObject(response:profile))
            self.commandDelegate.send(result, callbackId: command.callbackId)
    }

    private func createResponseObject(response: ZOGraphResponseObject?) -> [AnyHashable : Any]? {
        var result: [AnyHashable : Any] = [:]

        guard let profile = response,
            profile.isSucess,
            // let errorCode = profile.data["error"] as? String,
            let name = profile.data["name"] as? String,
            let id = profile.data["id"] as? String,
            let message = profile.data["message"] as? String
        else {
            result["status"] = "error"
            showAlert(with: "Error", message: (response!.data["error"] as! String))
            return result
        }
        result["status"] = "connected"
        result["authResponse"] = [
            "message": message,
            "userID": id,
            "displayName": name
        ]
        
        return result
    }
    private func createErrorResponseObject(response: Any?) ->  [AnyHashable : Any]? {
        var result: [AnyHashable : Any] = [:]
        result["status"] = "error"
        return result
    }

    private func showAlert(with title: String = "ZaloSDK", message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default) { (action) in
            controller.dismiss(animated: true, completion: nil)
        }
        controller.addAction(action)
        self.viewController?.present(controller, animated: true, completion: nil)
    }

}



// @UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        /// 0b. Receive callback from zalo
        return ZDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
    }
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
