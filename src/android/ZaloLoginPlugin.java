package com.pcv.zalo;

import android.content.Context;
import android.content.Intent;
import android.content.res.Resources;
import android.net.Uri;
import android.os.Bundle;
import android.util.Log;
import android.webkit.WebView;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemSelectedListener;
import android.widget.Spinner;
import android.widget.TextView;
import android.widget.Toast;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.net.URLDecoder;
import java.util.Collection;
import java.util.Currency;
import java.util.Date;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import com.zing.zalo.zalosdk.oauth.LoginVia;
import com.zing.zalo.zalosdk.oauth.OAuthCompleteListener;
import com.zing.zalo.zalosdk.oauth.model.ErrorResponse;
import com.zing.zalo.zalosdk.oauth.OauthResponse;
import com.zing.zalo.zalosdk.oauth.ValidateCallback;
import com.zing.zalo.zalosdk.oauth.ZaloSDK;
import com.zing.zalo.zalosdk.oauth.ZaloOpenAPICallback;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Scanner;
import java.util.Base64;
import java.security.SecureRandom;

public class ZaloLoginPlugin extends CordovaPlugin {
    public static String userId = "";
    private ImageView imgViewLoginFormBg;
    private Spinner zalo_login_type;
    private Spinner show_login_form_type;
    private String showProtectAccType ;

    private final String TAG = "ZaloLoginPlugin";

    private CallbackContext loginContext = null;
    private CallbackContext reauthorizeContext = null;
    private CallbackContext showDialogContext = null;
    private CallbackContext lastGraphContext = null;
    private String lastGraphRequestMethod = null;
    private String graphPath;
    private String codeVerifier = genCodeVerifier();

    OAuthCompleteListener listener = new OAuthCompleteListener(){
        @Override
        public void onAuthenError(ErrorResponse errorResponse) {
            //Đăng nhập thất bại..
            super.onAuthenError(errorResponse);
            loginContext.error(getErrorResponse(errorResponse));
        }
    
        @Override
        public void onGetOAuthComplete(OauthResponse response) {
            super.onGetOAuthComplete(response);
            String code = response.getOauthCode();
            //Đăng nhập thành công..
            // loginContext.success(getResponse(response));
            Context context = cordova.getActivity().getApplicationContext();
            ZaloSDK.Instance.getAccessTokenByOAuthCode( context, code, codeVerifier, new ZaloOpenAPICallback() {
                @Override
                public void onResult(JSONObject data) {
                    int err = data.optInt("error");
                    if (err == 0) {
                        //clearOauthCodeInfo(); //clear used oacode
            
                        String access_token = data.optString("access_token");
                        String refresh_token = data.optString("refresh_token");
                        long expires_in = Long.parseLong(data.optString("expires_in"));
                        String[] fields = {"id"};
            
                        ZaloSDK.Instance.getProfile( context, access_token, new ZaloOpenAPICallback(){
                            @Override
                            public void onResult(JSONObject response) {
                                loginContext.success(getResponse(response));
                            }
                        }, fields);
                          
                    } else {
                        loginContext.error(getErrorResponse(data));
                    }
                }
            });
        };
    };
    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent intent) {
        super.onActivityResult(requestCode, resultCode, intent);
        ZaloSDK.Instance.onActivityResult(cordova.getActivity(), requestCode, resultCode, intent);
    }
    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        
        if (action.equals("login")) {
            executeLogin(args, callbackContext);
            return true;
        }
        else if (action.equals("logout")) {
            executeLogout(args, callbackContext);
            return true;
        }
        return false;
    }

    private void executeLogin(JSONArray args, CallbackContext callbackContext) throws JSONException {
        // Set a pending callback to cordova
        loginContext = callbackContext;
        PluginResult pr = new PluginResult(PluginResult.Status.NO_RESULT);
        pr.setKeepCallback(true);
        loginContext.sendPluginResult(pr);
        // Set up the activity result callback to this class
        cordova.setActivityResultCallback(this);
        String codeChallenge = genCodeChallenge(codeVerifier);
        ZaloSDK.Instance.authenticateZaloWithAuthenType(cordova.getActivity(), LoginVia.APP_OR_WEB, codeChallenge, listener);
    }
    private void executeLogout(JSONArray args, CallbackContext callbackContext) throws JSONException {
        ZaloSDK.Instance.unauthenticate();
    }

    /**
     * Create a Zalo Response object that matches the one for the Javascript SDK
     * @return JSONObject - the response object
     */
    public JSONObject getResponse(JSONObject response) {
        String result;
        // Context context = this.cordova.getActivity().getApplicationContext();
        // int duration = Toast.LENGTH_LONG;

        // Toast toast = Toast.makeText(context, response.optString("id"), duration);
        // toast.show();
        
        if (response.optInt("error")==0) {
            result = "{"
                + "\"status\": \"connected\","
                + "\"authResponse\": {"
                + "\"errorCode\": \"" + response.optInt("error") + "\","
                + "\"userID\": \"" + response.opt("id") + "\""
                + "}"
                + "}";
        } else {
            result = "{"
                + "\"status\": \"unknown\""
                + "}";
        }
        try {
            return new JSONObject(result);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return new JSONObject();
    }

    public JSONObject getErrorResponse(ErrorResponse response) {
        String result;
        if (response.getErrorCode()!=0) {
            result = "{"
                + "\"status\": \"error\","
                + "\"authResponse\": {"
                + "\"oauthCode\": \"" + response.getErrorCode() + "\","
                + "}"
                + "}";
        } else {
            System.out.print(response);
            result = "{"
                + "\"status\": \"unknown\""
                + "}";
        }
        try {
            return new JSONObject(result);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return new JSONObject();
    }

    public String genCodeVerifier() {  
        SecureRandom sr = new SecureRandom();  
        byte[] code = new byte[32];  
        sr.nextBytes(code);  
        String verifier = Base64.getUrlEncoder().withoutPadding().encodeToString(code);  
        return verifier;  
    }  

    public String genCodeChallenge(String codeVerifier) {  
        String result = null;  
        try {  
            byte[] bytes = codeVerifier.getBytes("US-ASCII");  
            MessageDigest md = MessageDigest.getInstance("SHA-256");  
            md.update(bytes, 0, bytes.length);  
            byte[] digest = md.digest();  
            result = Base64.getUrlEncoder().withoutPadding().encodeToString(digest);  
        } catch (Exception ex) {  
            System.out.println(ex.getMessage());
        }  
        return result;  
    }
}