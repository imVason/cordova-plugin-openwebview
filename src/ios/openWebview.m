/********* openWebview.m Cordova Plugin Implementation *******/

#import <objc/runtime.h>
#import <Cordova/CDV.h>
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "CustomIOSAlertView.h"


@interface openWebview : CDVPlugin {
  // Member variables go here.
}

@property (nonatomic, strong) NSMutableArray *alertViewList;

- (void)open:(CDVInvokedUrlCommand*)command;


@end

@implementation openWebview

- (void)open:(CDVInvokedUrlCommand*)command
{
    CDVPluginResult* pluginResult = nil;
    NSDictionary* options = [command.arguments objectAtIndex:0];

    if (options != nil) {
        NSString *redirectUrl = options[@"url"];
        NSLog(@"redirectUrl: %@", redirectUrl);
        int alertViewListCount = (int)[self.alertViewList count];
        if(alertViewListCount == 2){
            return;
        };
        if ([redirectUrl hasPrefix:@"http://"] || [redirectUrl hasPrefix:@"https://"]) {
            CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
            UIView *outContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
            if (alertViewListCount == 0) {
                self.alertViewList = [[NSMutableArray alloc]init];
            }
            [self.alertViewList addObject:alertView];
            
            UIView *actionBar = [self createActionBar];
            WKWebView *aWebView = [self createWebView];
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
    UIView *actionContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [self getStatusBarHeight] + 44)];
    actionContainer.layer.backgroundColor = [[UIColor colorWithRed:211.0/255.0 green:17.0/255.0 blue:69.0/255.0 alpha:1.0f] CGColor];
    
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    closeButton.frame = CGRectMake(0, [self getStatusBarHeight], 80, 40);
    [closeButton setTitle:@"CLOSE" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeDialog:) forControlEvents:UIControlEventTouchUpInside];
    [actionContainer addSubview:closeButton];
    
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


-(WKWebView *)createWebView
{
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    //实例化对象
    configuration.userContentController = [WKUserContentController new];
    //调用JS方法
    [configuration.userContentController addScriptMessageHandler:self name:@"openNew"];
    // 创建WKWebView
    WKWebView *webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, [self getStatusBarHeight] + 44, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - [self getStatusBarHeight] - 44) configuration:configuration];
    return webView;
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{//    message.body  --  Allowed types are NSNumber, NSString, NSDate, NSArray,NSDictionary, and NSNull.
    if(message.body == nil){
        return;
    }
    if ([message.name isEqualToString:@"openNew"]) {
        NSDictionary *msgData = message.body;
        NSLog(@"openNew alertViewList: %@", [self alertViewList]);
        CustomIOSAlertView *getAlertView = [self alertViewList].lastObject;
        NSLog(@"openNew getAlertView: %@", getAlertView);
        NSString *jsStr = [NSString stringWithFormat:@"cordova.plugins.openWebview.open({url:'%@'})",msgData[@"url"]];
        if(self.webViewEngine){
            [self.webViewEngine evaluateJavaScript:jsStr completionHandler:^(id object, NSError * _Nullable error) {
                NSLog(@"obj:%@---error:%@", object, error);
            }];
        }
    }
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

@end
