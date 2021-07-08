package hb.plugins.openWebview;

import android.app.Dialog;
import android.content.Intent;
import android.content.res.Resources;
import android.graphics.Color;
import android.net.Uri;
import android.os.Build;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.view.animation.LinearInterpolator;
import android.webkit.JavascriptInterface;
import android.webkit.WebChromeClient;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;

/**
 * This class echoes a string called from JavaScript.
 */
public class openWebview extends CordovaPlugin {

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {
        if (action.equals("open")) {
            JSONObject openOption = args.getJSONObject(0);
            this.open(openOption, callbackContext);
            return true;
        }
        return false;
    }

    private void open(JSONObject openOption, CallbackContext callbackContext) {
        this.openWebViewDialog(openOption, callbackContext);
    }

    /**
     * 初始化 webview dialog
     */
    private void openWebViewDialog(final JSONObject openOption, final CallbackContext callbackContext) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                try {
                    Boolean inSubView = false;
                    Boolean showBackBtn = false;
                    if (openOption.has("inSubView")) {
                        inSubView = openOption.getBoolean("inSubView");
                    }
                    if (openOption.has("showBackBtn")) {
                        showBackBtn = openOption.getBoolean("showBackBtn");
                    }

                    if (openOption.getString("url").contains("#webview-external")) {
                        Log.d("open URL", "========= 外部浏览器 =========");
                        String replacedUrl = openOption.getString("url").replace("#webview-external", "");
                        Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(replacedUrl));
                        cordova.getContext().startActivity(browserIntent);
                        return;
                    }


                    Log.d("openWebview", "run: " + openOption);
                    /* create Dialog */
                    final Dialog mShareDialog = new Dialog(cordova.getContext(), getName("webview_dialog"));
                    mShareDialog.setCanceledOnTouchOutside(false);
                    mShareDialog.setCancelable(false);
                    Window window = mShareDialog.getWindow();

                    /* set layout */
                    final View mainView = View.inflate(cordova.getContext(), getLayout("open_webview"), null);
                    mainView.findViewById(getId("open_webview_close")).setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View view) {
                            if (mShareDialog != null && mShareDialog.isShowing()) {
                                mShareDialog.dismiss();
                            }
                            mShareDialog.dismiss();
                        }
                    });

                    /* set webView */
                    LinearLayout webviewBox = mainView.findViewById(getId("webViewBox"));
                    final WebView webviews = new WebView(cordova.getActivity());
                    webviews.setLayoutParams(new LinearLayout.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT));
                    webviews.setWebChromeClient(new WebChromeClient(){
                        @Override
                        public void onProgressChanged(WebView view, int newProgress) {
                            super.onProgressChanged(view, newProgress);
                            if(newProgress==100){
                                mainView.findViewById(getId("webViewLoading")).setVisibility(View.GONE);
                            }
                            else{
                                if(mainView.findViewById(getId("webViewLoading")).getVisibility() == View.GONE){
                                    mainView.findViewById(getId("webViewLoading")).setVisibility(View.VISIBLE);
                                    ImageView webViewLoading_pic = mainView.findViewById(getId("webViewLoading_pic"));
                                    Animation myAlphaAnimation = AnimationUtils.loadAnimation(cordova.getContext(), getAnim("openwebview_loading_anim"));
                                    myAlphaAnimation.setInterpolator(new LinearInterpolator());
                                    webViewLoading_pic.startAnimation(myAlphaAnimation);
                                }
                            }
                        }
                    });
                    webviews.setWebViewClient(new WebViewClient() {
                        @Override
                        public boolean shouldOverrideUrlLoading(WebView view, String url) {
                            Log.d("open URL", url);
                            //使用WebView加载显示url
//                            view.loadUrl(url);
                            if (url.contains(".pdf")){
                                Intent browserIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
                                cordova.getContext().startActivity(browserIntent);
                                return true;
                            }
                            if(Build.VERSION.SDK_INT < 26) {
                                view.loadUrl(url);
                                return true;
                            } else {
                                return false;
                            }
                        }

                        @Override
                        public void onPageFinished(WebView view, String url) {
                            view.loadUrl("javascript:var nativeAllLinks = document.getElementsByTagName('a'); if (nativeAllLinks) { var i; for (i = 0; i < nativeAllLinks.length; i++) { var link = nativeAllLinks[i]; link.setAttribute('target', '_self'); } }");
                            setWebviewBack(view, mainView);
                        }
                    });
                    /* 添加webview 回调 */
                    webviews.addJavascriptInterface(new Object() {
                        @JavascriptInterface
                        public void openNew(final String options) {
                            cordova.getActivity().runOnUiThread(new Runnable() {
                                public void run() {
                                    try{
                                        JSONObject newOption = new JSONObject(options);
                                        newOption.put("inSubView",true);
                                        Log.d("openWebview", "newOption: " + newOption);
                                        String url = newOption.getString("url");
                                        if (url.startsWith("http://") || url.startsWith("https://")) {
//                                            Toast.makeText(cordova.getActivity(), url, Toast.LENGTH_SHORT).show();
                                            WebView mainWebview = cordova.getActivity().findViewById(getId("cordovaWebView"));
                                            mainWebview.loadUrl("javascript:cordova.plugins.openWebview.open(" + newOption + ")");
                                        } else {
                                            callbackContext.error("error url, url should start width 'http://' or 'https://'.");
                                        }
                                    }catch (Exception e){
                                        callbackContext.error(e.toString() + "");
                                    }
                                }
                            });
                        }
                    }, "openWebview");

                    WebSettings webSettings = webviews.getSettings();
                    //如果访问的页面中要与Javascript交互，则webview必须设置支持Javascript
                    webSettings.setJavaScriptEnabled(true);
                    webSettings.setDomStorageEnabled(true); // 开启 DOM storage API 功能
                    webSettings.setDatabaseEnabled(true);   //开启 database storage API 功能
                    webSettings.setAppCacheEnabled(true);//开启 Application Caches 功能

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        webSettings.setMixedContentMode(WebSettings.MIXED_CONTENT_ALWAYS_ALLOW);
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT){
                        webSettings.setAllowUniversalAccessFromFileURLs(true);
                    }else{
                        try {
                            Class<?> clazz = webSettings.getClass();
                            Method method = clazz.getMethod("setAllowUniversalAccessFromFileURLs", boolean.class);
                            if (method != null) {
                                method.invoke(webSettings, true);
                            }
                        } catch (NoSuchMethodException e) {
                            e.printStackTrace();
                        } catch (InvocationTargetException e) {
                            e.printStackTrace();
                        } catch (IllegalAccessException e) {
                            e.printStackTrace();
                        }
                    }
                    webSettings.setBlockNetworkImage(false);//解决图片不显示
                    //设置自适应屏幕，两者合用
                    webSettings.setUseWideViewPort(true); //将图片调整到适合webview的大小
                    webSettings.setLoadWithOverviewMode(true); // 缩放至屏幕的大小
                    //缩放操作
                    webSettings.setSupportZoom(true); //支持缩放，默认为true。是下面那个的前提。
                    webSettings.setBuiltInZoomControls(true); //设置内置的缩放控件。若为false，则该WebView不可缩放
                    webSettings.setDisplayZoomControls(false); //隐藏原生的缩放控件
                    //其他细节操作
                    webSettings.setAllowFileAccess(true); //设置可以访问文件
                    webSettings.setJavaScriptCanOpenWindowsAutomatically(true); //支持通过JS打开新窗口
                    webSettings.setLoadsImagesAutomatically(true); //支持自动加载图片
                    webSettings.setDefaultTextEncodingName("utf-8");//设置编码格式
                    webSettings.setCacheMode(WebSettings.LOAD_CACHE_ELSE_NETWORK);//没网，则从本地获取，即离线加载

                    if (showBackBtn){
                        mainView.findViewById(getId("open_webview_back")).setVisibility(View.VISIBLE);
                    }
                    mainView.findViewById(getId("open_webview_back")).setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View view) {
                            if (webviews.canGoBack()) {
                                webviews.goBack();
                                setWebviewBack(webviews, mainView);
                            }
                        }
                    });
                    mainView.findViewById(getId("open_webview_forward")).setOnClickListener(new View.OnClickListener() {
                        @Override
                        public void onClick(View view) {
                            if (webviews.canGoForward()) {
                                webviews.goForward();
                                setWebviewBack(webviews, mainView);
                            }
                        }
                    });

                    webviews.loadUrl(openOption.getString("url").startsWith("http") ? openOption.getString("url") : "about:blank");
                    webviewBox.addView(webviews);
                    /* show Dialog */
                    window.setContentView(mainView);
                    if (inSubView){
                        window.getDecorView().setPadding(0, 100, 0, 0);
                    }else{
                        window.getDecorView().setPadding(0, 0, 0, 0);
                    }

                    window.getDecorView().setBackgroundColor(Color.parseColor("#00000000"));
                    window.setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT);//设置横向全屏
                    mShareDialog.show();
                } catch (Exception e) {
                    callbackContext.error(e.toString() + "");
                }
            }
        });
    }

    private int getId(String idName) {
        Resources resources = cordova.getContext().getResources();
        return resources.getIdentifier(idName, "id", cordova.getContext().getPackageName());
    }

    private int getLayout(String layoutName) {
        Resources resources = cordova.getContext().getResources();
        return resources.getIdentifier(layoutName, "layout", cordova.getContext().getPackageName());
    }

    private int getName(String name) {
        Resources resources = cordova.getContext().getResources();
        return resources.getIdentifier(name, "name", cordova.getContext().getPackageName());
    }

    private int getAnim(String name) {
        Resources resources = cordova.getContext().getResources();
        return resources.getIdentifier(name, "anim", cordova.getContext().getPackageName());
    }

    //   设置 text 组件文本
    private void setViewText(final TextView view, final String text) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                if (view != null) {
                    view.setText(text);
                }
            }
        });
    }

    private void setWebviewBack(final WebView webview, final View mainView) {
        cordova.getActivity().runOnUiThread(new Runnable() {
            public void run() {
                View backBtn = mainView.findViewById(getId("open_webview_back"));
                View forwardBtn = mainView.findViewById(getId("open_webview_forward"));
                if (backBtn.getVisibility() == View.VISIBLE){
                    Log.d("webview.canGoBack()", "run: " + webview.canGoBack());
                    if (!webview.canGoBack()) {
                        backBtn.setAlpha((float) 0.5);
                        backBtn.setEnabled(false);
                    } else {
                        backBtn.setAlpha(1);
                        backBtn.setEnabled(true);
                    }
                }

                if (forwardBtn.getVisibility() == View.VISIBLE){
                    if (!webview.canGoForward()) {
                        forwardBtn.setAlpha((float) 0.5);
                        forwardBtn.setEnabled(false);
                    } else {
                        forwardBtn.setAlpha(1);
                        forwardBtn.setEnabled(true);
                    }
                }
            }
        });
    }
}
