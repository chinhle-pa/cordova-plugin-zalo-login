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
import com.zing.zalo.zalosdk.oauth.OauthResponse;
import com.zing.zalo.zalosdk.oauth.ValidateOAuthCodeCallback;
import com.zing.zalo.zalosdk.oauth.ZaloSDK;

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

    OAuthCompleteListener listener = new OAuthCompleteListener(){
        @Override
        public void onAuthenError(int errorCode, String message) {
            // Đăng nhập thất bại..
            super.onAuthenError(errorCode, message);
            try {
                loginContext.error( new JSONObject("{"+ "\"status\": \"error\",authResponse:{"+"\"errorCode\":"+errorCode+"}}"));
            } catch (JSONException e) {
                loginContext.error(errorCode);
                e.printStackTrace();
            }
        };
    
        @Override
        public void onGetOAuthComplete(OauthResponse response) {
            super.onGetOAuthComplete(response);
            String code = response.getOauthCode();
            //Đăng nhập thành công..
            loginContext.success(getResponse(response));
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
        ZaloSDK.Instance.authenticate(cordova.getActivity(), LoginVia.APP_OR_WEB, listener);
    }

    /**
     * Create a Zalo Response object that matches the one for the Javascript SDK
     * @return JSONObject - the response object
     */
    public JSONObject getResponse(OauthResponse response) {
        String result;
        if (response.getuId()!=0) {
            result = "{"
                + "\"status\": \"connected\","
                + "\"authResponse\": {"
                + "\"oauthCode\": \"" + response.getOauthCode() + "\","
                + "\"userID\": \"" + response.getuId() + "\""
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
}