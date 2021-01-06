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

    if (options != nil) {
        NSString *redirectUrl = options[@"url"];
        NSString *fromWhere = options[@"fromWhere"];
        if ([fromWhere isEqual:@"webview"]) {
            NSLog(@"open fromWhere: %@", fromWhere);
            self.isSubWebView = YES;
        }
        int alertViewListCount = (int)[self.alertViewList count];
        if(alertViewListCount == 2){
            return;
        };
        if ([redirectUrl hasPrefix:@"http://"] || [redirectUrl hasPrefix:@"https://"]) {
            CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
            UIView *outContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            UIColor *color = [UIColor blackColor];
            outContainer.backgroundColor = [color colorWithAlphaComponent:0.3f];
//            outContainer.backgroundColor = [UIColor blueColor];
            if (alertViewListCount == 0) {
                self.alertViewList = [[NSMutableArray alloc]init];
            }
            [self.alertViewList addObject:alertView];
            UIView *actionBar = [self createActionBar];
            WKWebView *aWebView = [self createWebView];
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


-(UIView *)createActionBar
{
    // This is the dialog's container; we attach the custom content and the buttons to this one
    int pos_y = 0;
    if(self.isSubWebView){
        // 从 webview 中 再打开 webview，减少高度
        pos_y = 80;
    }
    UIView *actionContainer = [[UIView alloc] initWithFrame:CGRectMake(0, pos_y, [UIScreen mainScreen].bounds.size.width, [self getStatusBarHeight] + 44)];
    actionContainer.layer.backgroundColor = [[UIColor colorWithRed:211.0/255.0 green:17.0/255.0 blue:69.0/255.0 alpha:1.0f] CGColor];
    
    if(self.isSubWebView){
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
    [closeButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath],@"open_webview_close@3x.png"]] forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeDialog:) forControlEvents:UIControlEventTouchUpInside];
    [actionContainer addSubview:closeButton];
    [self.closeButtonList addObject:closeButton];
    
    // back button
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(40, [self getStatusBarHeight] + 5, 30, 30);
    [backButton setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath],@"open_webview_back@3x.png"]] forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(webviewBack:) forControlEvents:UIControlEventTouchUpInside];
    [actionContainer addSubview:backButton];
    [self.backButtonList addObject:backButton];
    
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
//        [self.alertViewList removeLastObject];
    }else{
        return;
    }
}


-(WKWebView *)createWebView
{
    int pos_y = 44;
    if(self.isSubWebView){
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
        NSDictionary *msgData = message.body;
        NSLog(@"openNew alertViewList: %@", [self alertViewList]);
        CustomIOSAlertView *getAlertView = [self alertViewList].lastObject;
        NSLog(@"openNew getAlertView: %@", getAlertView);
        NSString *openFromWhere = @"webview";
        NSString *jsStr = [NSString stringWithFormat:@"cordova.plugins.openWebview.open({url:'%@', fromWhere:'%@'})",msgData[@"url"], openFromWhere];
        if(self.webViewEngine){
            [self.webViewEngine evaluateJavaScript:jsStr completionHandler:^(id object, NSError * _Nullable error) {
                NSLog(@"obj:%@---error:%@", object, error);
            }];
        }
    }
}

#pragma mark - WKNavigationDelegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"WKNavigationDelegate canGoBack: %@", webView.canGoBack? @"YES": @"NO");
    NSLog(@"WKNavigationDelegate Tag: %li", webView.tag);
    NSLog(@"WKNavigationDelegate didStartProvisionalNavigation: %@", @"didStartProvisionalNavigation");
}
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    NSLog(@"WKNavigationDelegate didCommitNavigation: %@", @"didCommitNavigation");
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    NSLog(@"WKNavigationDelegate canGoBack: %@", webView.canGoBack? @"YES": @"NO");
    NSInteger index = [self.webvieViewList indexOfObject:webView];
    NSLog(@"WKNavigationDelegate index: %li", index);
    UIButton* backButton = [self.backButtonList objectAtIndex:index];
    NSLog(@"WKNavigationDelegate backButton: %@", backButton);
    NSLog(@"WKNavigationDelegate didFinishNavigation: %@", @"didFinishNavigation");
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"WKNavigationDelegate didFailProvisionalNavigation: %@", @"didFailProvisionalNavigation");
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
