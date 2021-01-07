/********* openWebview.m Cordova Plugin Implementation *******/

#import <objc/runtime.h>
#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "CustomIOSAlertView.h"
#import "AppDelegate.h"
#import "OpenWebvViewController.h"


@interface openWebview : CDVPlugin {
  // Member variables go here.
}

@property (nonatomic, strong) NSMutableArray *alertViewList;    // dialog list
@property (nonatomic, strong) NSMutableArray *webvieViewList;   // webview list
@property (nonatomic, strong) NSMutableArray *closeButtonList;   // close button list
@property (nonatomic, strong) NSMutableArray *backButtonList;   // back button list
@property (nonatomic, assign) BOOL isSubWebView;

- (void)open:(CDVInvokedUrlCommand*)command;


@end

@implementation openWebview

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSDictionary* options = [command.arguments objectAtIndex:0];
    NSLog(@"open options: %@", options);
    if (options != nil) {
        NSString *redirectUrl = options[@"url"];
        BOOL inSubView = [options[@"inSubView"] boolValue];
        BOOL showBackBtn = [options[@"showBackBtn"] boolValue];
        // 判断已打开的webview个数
        int alertViewListCount = (int)[self.alertViewList count];
        if(alertViewListCount == 2){
            return;
        };
        if ([redirectUrl hasPrefix:@"http://"] || [redirectUrl hasPrefix:@"https://"]) {
            CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
            UIView *outContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            UIColor *color = [UIColor blackColor];
            outContainer.backgroundColor = [color colorWithAlphaComponent:0.3f];
            if (alertViewListCount == 0) {
                self.alertViewList = [[NSMutableArray alloc]init];
            }
            [self.alertViewList addObject:alertView];
            UIView *actionBar = [self createActionBar:showBackBtn isSubWebView:inSubView];
            WKWebView *aWebView = [self createWebView:inSubView];
            // webview 标识：5600
            aWebView.tag = 5600 + [self.alertViewList count];
            // 设置访问的URL
            NSURL *url = [NSURL URLWithString:redirectUrl];
            // 根据URL创建请求
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            // WKWebView加载请求
            [aWebView loadRequest:request];
            // 将WKWebView添加到视图
            [outContainer addSubview:actionBar];
            [outContainer addSubview:aWebView];
            [alertView setContainerView:outContainer];
            [alertView show];
            pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:options[@"url"]];
        }
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(int)getStatusBarHeight{
    int statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
    return statusBarHeight;
}


-(UIView *)createActionBar:(BOOL)isShowBack isSubWebView:(BOOL)isSubWebView
{
    // This is the dialog's container; we attach the custom content and the buttons to this one
    int pos_y = 0;
    // 判断是否从 subwebview 中调用的
    if(isSubWebView){
        // 从 webview 中 再打开 webview，减少高度
        pos_y = 80;
    }
    UIView *actionContainer = [[UIView alloc] initWithFrame:CGRectMake(0, pos_y, [UIScreen mainScreen].bounds.size.width, [self getStatusBarHeight] + 44)];
    actionContainer.layer.backgroundColor = [[UIColor colorWithRed:211.0/255.0 green:17.0/255.0 blue:69.0/255.0 alpha:1.0f] CGColor];
    
    if(isSubWebView){
        // 从 webview 中 再打开 webview，设置圆角
        CGFloat radius = 10; // 圆角大小
        UIRectCorner corner = UIRectCornerTopLeft | UIRectCornerTopRight; // 圆角位置
        UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:actionContainer.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = actionContainer.bounds;
        maskLayer.path = path.CGPath;
        actionContainer.layer.mask = maskLayer;
    }
    
    int closeButtonListCount = (int)[self.closeButtonList count];
    int backButtonListCount = (int)[self.backButtonList count];
    if (closeButtonListCount == 0) {
        self.closeButtonList = [[NSMutableArray alloc]init];
    }
    if (backButtonListCount == 0) {
        self.backButtonList = [[NSMutableArray alloc]init];
    }
    
    // close button
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(10, [self getStatusBarHeight] + 5, 30, 30);
    [closeButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath],@"open_webview_close.png"]] forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeDialog:) forControlEvents:UIControlEventTouchUpInside];
    [actionContainer addSubview:closeButton];
    [self.closeButtonList addObject:closeButton];
    
    // 判断是否显示 返回 按钮
    if (isShowBack) {
        // back button
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        backButton.frame = CGRectMake(50, [self getStatusBarHeight] + 6, 26, 26);
        [backButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath],@"open_webview_back.png"]] forState:UIControlStateNormal];
        [backButton setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(webviewBack:) forControlEvents:UIControlEventTouchUpInside];
        [actionContainer addSubview:backButton];
        [self.backButtonList addObject:backButton];
        NSLog(@"createActionBar showBackBtn: %@", @"show");
    }else{
        NSLog(@"createActionBar showBackBtn: %@", @"hide");
    }
    
    return actionContainer;
}

// 关闭 dialog
- (void)closeDialog:(UIButton *)btn
{
    int alertViewListCount = (int)[self.alertViewList count];
    if(alertViewListCount > 0){
        CustomIOSAlertView *getAlertView = [self.alertViewList lastObject];
        NSLog(@"closeDialog getAlertView: %@", getAlertView);
        [getAlertView close];
        [self.alertViewList removeLastObject];
        [self.webvieViewList removeLastObject];
        [self.closeButtonList removeLastObject];
        [self.backButtonList removeLastObject];
    }else{
        return;
    }
}

// webview 后退
- (void)webviewBack:(UIButton *)btn
{
    int webvieViewListCount = (int)[self.webvieViewList count];
    NSLog(@"webviewBack webvieViewList: %@", self.webvieViewList);
    if(webvieViewListCount > 0){
        WKWebView *getWebview = [self.webvieViewList lastObject];
        NSLog(@"webviewBack getWebview: %@", getWebview);
        [getWebview goBack];
    }else{
        return;
    }
}


-(WKWebView *)createWebView:(BOOL)isSubWebView
{
    int pos_y = 44;
    if(isSubWebView){
        pos_y = 44 + 80;
    }
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    //实例化对象
    configuration.userContentController = [WKUserContentController new];
    //调用JS方法
    [configuration.userContentController addScriptMessageHandler:self name:@"openNew"];
    // 创建WKWebView
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, [self getStatusBarHeight] + pos_y, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [self getStatusBarHeight] - pos_y) configuration:configuration];
    webView.navigationDelegate = self;
    int webvieViewListCount = (int)[self.webvieViewList count];
    if (webvieViewListCount == 0) {
        self.webvieViewList = [[NSMutableArray alloc]init];
    }
    [self.webvieViewList addObject:webView];
    // 添加属性监听
    [webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    return webView;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{//    message.body  --  Allowed types are NSNumber, NSString, NSDate, NSArray,NSDictionary, and NSNull.
    // [[UIApplication sharedApplication].delegate.window.rootViewController presentViewController:(nonnull UIViewController *) animated:YES completion:nil]
    if(message.body == nil){
        return;
    }
    if ([message.name isEqualToString:@"openNew"]) {
        // 获取消息数据
        NSDictionary *msgData = message.body;
        NSString *jsStr = [NSString stringWithFormat:@"cordova.plugins.openWebview.open({url:'%@', showBackBtn: '%i',inSubView:'%i'})", msgData[@"url"], [msgData[@"showBackBtn"] boolValue], [msgData[@"inSubView"] boolValue]];
//        NSString *jsStr = [NSString stringWithFormat:@"cordova.plugins.openWebview.open(%@)", newData];
        if(self.webViewEngine){
            [self.webViewEngine evaluateJavaScript:jsStr completionHandler:^(id object, NSError * _Nullable error) {
                NSLog(@"obj:%@---error:%@", object, error);
            }];
        }
    }
}

//#pragma mark - WKNavigationDelegate
//// 页面开始加载时调用
//- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
//    NSLog(@"WKNavigationDelegate canGoBack: %@", webView.canGoBack? @"YES": @"NO");
//    NSLog(@"WKNavigationDelegate Tag: %li", webView.tag);
//    NSLog(@"WKNavigationDelegate didStartProvisionalNavigation: %@", @"didStartProvisionalNavigation");
//}
//// 当内容开始返回时调用
//- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
//    NSLog(@"WKNavigationDelegate didCommitNavigation: %@", @"didCommitNavigation");
//}
//// 页面加载完成之后调用
//- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
//    NSLog(@"WKNavigationDelegate canGoBack: %@", webView.canGoBack? @"YES": @"NO");
//    NSInteger index = [self.webvieViewList indexOfObject:webView];
//    NSLog(@"WKNavigationDelegate index: %li", index);
//    UIButton* backButton = [self.backButtonList objectAtIndex:index];
//    NSLog(@"WKNavigationDelegate backButton: %@", backButton);
//    if (webView.canGoBack) {
//        backButton.userInteractionEnabled = YES;
//        backButton.alpha = 1.0;
//    }else{
//        backButton.userInteractionEnabled = NO;
//        backButton.alpha = 0.4;
//    }
//}
//// 页面加载失败时调用
//- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
//    NSLog(@"WKNavigationDelegate didFailProvisionalNavigation: %@", @"didFailProvisionalNavigation");
//}

#pragma mark - 监听加载进度
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSLog(@"change == %f",[change[NSKeyValueChangeNewKey] floatValue]);
        WKWebView *getWebview = [self.webvieViewList lastObject];
        UIButton* backButton = [self.backButtonList lastObject];
        NSLog(@"estimatedProgress getWebview: %@", getWebview);
        NSLog(@"estimatedProgress backButton: %@", backButton);
        NSLog(@"estimatedProgress canGoBack: %@", getWebview.canGoBack? @"YES": @"NO");
        
        if (backButton != nil) {
            if (getWebview.canGoBack) {
                backButton.userInteractionEnabled = YES;
                backButton.alpha = 1.0;
                
            }else{
                backButton.userInteractionEnabled = NO;
                backButton.alpha = 0.4;
            }
        }
        if ([change[NSKeyValueChangeNewKey] floatValue] == 1) {
            // page load done
        }
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

- (void)dealloc{
    WKWebView *getWebview = [self.webvieViewList lastObject];
    [getWebview removeObserver:self forKeyPath:@"estimatedProgress"];
}



// 递归获取子视图
- (UIView *)viewWithTagNotCountingSelf:(NSInteger)tag
{
    UIView *toReturn = nil;
    CustomIOSAlertView *getAlertView = [self alertViewList].lastObject;
    for (UIView *subView in getAlertView.subviews) {
        toReturn = [subView viewWithTag:tag];
        NSLog(@"openNew toReturn: %@", toReturn);
        if (toReturn) {
            break;
        }
    }
    return toReturn;
}

+ (UIImage*)imageFromMainBundleFile_zmm:(NSString*)aFileName
{
    NSString* bundlePath = [[NSBundle mainBundle] bundlePath];
    return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", bundlePath,aFileName]];
}

@end
