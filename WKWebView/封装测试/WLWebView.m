//
//  WLWebView.m
//  WKWebView
//
//  Created by DuBenBen on 2020/3/29.
//  Copyright © 2020 DuWenliang. All rights reserved.
//

#import "WLWebView.h"


#define APP_HEIGHT          [[UIScreen mainScreen] bounds].size.height
#define IS_IPHONE           (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_PAD              (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define APP_NAV_HEIGHT      ((APP_HEIGHT >= 812 && IS_IPHONE) ? 88 : (IS_PAD ? 70 : 64))
static const CGFloat kProgressWidth = 2.0;


@interface WLWebView () <WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *wkWebView;

@property (nonatomic, strong) WKWebViewConfiguration *webConfig;
@property (nonatomic, strong) WKPreferences *preferences;
@property (nonatomic, strong) NSArray<NSString *> *jsObjects;
@property (nonatomic, strong) NSMutableArray<WKUserScript *> *userScripts;
@property (nonatomic, strong) WKUserContentController *userContentController;

@property (nonatomic, assign) BOOL setUIDelegate;

@property (nonatomic, assign) BOOL setNavigationDelegate;

@property (nonatomic, assign) BOOL setWebTitle;

@property (nonatomic, assign) BOOL setProgress;
@property (nonatomic, strong) UIProgressView *webProgress;
@property (nonatomic, strong) UIColor *progressColor;

@end


@implementation WLWebView

#pragma mark - 指定初始化

- (instancetype)initWithFrame:(CGRect)frame webConfig:(WKWebViewConfiguration *)webConifg setJSObjectsInteractiveOC:(NSArray <NSString *> *)jsObjects setOCInteractiveJSUserScripts:(NSArray<WKUserScript *> *)userScripts setUIDelegate:(BOOL) setUIDelegate setNavigationDelegate:(BOOL)setNavigationDelegate setWebTitle:(BOOL)setWebTitle setProgress:(BOOL)setProgress progressColor:(UIColor *)progressColor {
    if (self = [super initWithFrame:frame]) {
        _webConfig = webConifg;
        _jsObjects = jsObjects;
        [self.userScripts addObjectsFromArray:userScripts];
        _setUIDelegate = setUIDelegate;
        _setNavigationDelegate = setNavigationDelegate;
        _setWebTitle = setWebTitle;
        _setProgress = setProgress;
        _progressColor = progressColor;
        
        [self initWebView];
    }
    return self;
}

- (void)initWebView {
    if (_jsObjects.count) {
        self.webConfig.userContentController = self.userContentController;
        //注入新对象，用来和JS交互
        for (NSString *jsObject in _jsObjects) {
            [_userContentController addScriptMessageHandler:[WLWeakScriptMessageDelegate weakDelegae:self] name:jsObject];
        }
    }
    if (_userScripts.count) {
        self.webConfig.userContentController = self.userContentController;
        //注入JS，执行JS代码
        for (WKUserScript *userScript in _userScripts) {
            [_userContentController addUserScript:userScript];
        }
    }
    [self addSubview:self.wkWebView];
    
    if (_setUIDelegate) {
        _wkWebView.UIDelegate = self;
    }
    
    if (_setNavigationDelegate) {
        _wkWebView.navigationDelegate = self;
    }
    
    if (_setWebTitle) {
        //添加监测网页标题title的观察者
        [_wkWebView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    if (_setProgress) {
        //添加监测网页加载进度的观察者
        [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:nil];
    }
}

- (void)layoutSubviews {
    _wkWebView.frame = self.bounds;
    if (_webProgress.superview == self) {
        _webProgress.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), kProgressWidth);
    } else {
        UIViewController *vc = [self findViewController];
        _webProgress.frame = CGRectMake(0, APP_NAV_HEIGHT -kProgressWidth, CGRectGetWidth(vc.navigationController.view.bounds), kProgressWidth);
    }
}

#pragma mark - 四种加载内容的方式

- (void)loadRequest:(NSURLRequest *)request {
    [_wkWebView loadRequest:request];
}
 
- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL {
    [_wkWebView loadHTMLString:string baseURL:baseURL];
}

- (void)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL {
    [_wkWebView loadFileURL:URL allowingReadAccessToURL:readAccessURL];
}

- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL {
    [_wkWebView loadData:data MIMEType:MIMEType characterEncodingName:characterEncodingName baseURL:baseURL];
}

#pragma mark - 其他功能性方法

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    [_wkWebView evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

- (void)wlGoWebHistory{
    if ([_wkWebView canGoBack]) {
        [_wkWebView goBack];
    }
    else{
        [self wlPopViewController];
    }
}

- (void)wlPopViewController{
    [[self findViewController].navigationController popViewControllerAnimated:YES];
}

- (void)wlPopRootViewController{
    [[self findViewController].navigationController popToRootViewControllerAnimated:YES];
}

- (void)wlReload {
    if (!_wkWebView.isLoading) {
        [_wkWebView reload];
    }
}

#pragma mark - WKScriptMessageHandler

//JS 调用 OC 时( JS 端可通过 window.webkit.messageHandlers.<name>.postMessage(<messageBody>) 发送消息调用OC代码)，下面的方法就会被执行。
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    NSLog(@"js 调用了 oc");
    
    if ([self.delegate respondsToSelector:@selector(userContentController:didReceiveScriptMessage:)]) {
        [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
    }
}

#pragma mark - WKUIDelegate : 主要处理JS脚本，确认框，警告框等

/*
 *  对应js的alert方法
 *  web界面中弹出警告框时调用。注意：只能有一个按钮（js中alert下面只有一个按钮，要对应）
 *
 *  @param webView           实现该代理的webview
 *  @param message           警告框中的内容
 *  @param frame             可用于区分哪个窗口调用的
 *  @param completionHandler 警告框消失调用，回调给JS
 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    //拦截到web页面的alert，使用原生alert代替展示
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提醒" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         completionHandler();
    }])];
    [[self findViewController] presentViewController:alertController animated:YES completion:nil];
}

/*
 *  对应js的confirm方法
 *  webView中弹出选择框时调用。 两个按钮
 *
 *  @param webView              webView description
 *  @param message              提示信息
 *  @param frame                可用于区分哪个窗口调用的
 *  @param completionHandler    确认框消失的时候调用, 回调给JS, 参数为选择结果: YES or NO
 */
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提醒" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
         completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         completionHandler(YES);
    }])];
    [[self findViewController] presentViewController:alertController animated:YES completion:nil];
}

/*
 *  对应js的prompt方法
 *  webView中弹出输入框时调用。 两个按钮 和 一个输入框
 
 *  @param webView              webView description
 *  @param prompt               提示信息
 *  @param defaultText          默认提示文本
 *  @param frame                可用于区分哪个窗口调用的
 *  @param completionHandler    输入框消失的时候调用, 回调给JS, 参数为输入的内容
 */
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
         textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
         completionHandler(alertController.textFields[0].text?:@"");
    }])];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(defaultText);
    }]];
    [[self findViewController] presentViewController:alertController animated:YES completion:nil];
}

// 页面是弹出窗口 _blank 处理（创建新的webView）
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark - WKNavigationDelegate

// 1，在发送请求之前，决定是否允许或取消导航。（可拦截即将发送的 HTTP 请求头信息和其他相关信息）
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSString *urlStr = navigationAction.request.URL.absoluteString;
    NSLog(@"发送跳转请求：%@",urlStr);
    decisionHandler(WKNavigationActionPolicyAllow); //允许导航继续
    
    if ([self.delegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.delegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    }
}

// 2，web视图开始加载web内容时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    
    NSLog(@"web开始加载");
    
    if ([self.delegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [self.delegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

// 3，收到服务器重定向之后调用 (接收到服务器跳转请求)
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    
    NSLog(@"重定向调用");
    
    if ([self.delegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [self.delegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

// 4，收到响应后，决定是否允许或取消导航。（可拦截客户端收到的服务器“响应头”相关信息）
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    
    NSString * urlStr = navigationResponse.response.URL.absoluteString;
    NSLog(@"当前跳转地址：%@",urlStr);
    decisionHandler(WKNavigationResponsePolicyAllow); //允许导航继续

    if ([self.delegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [self.delegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    }
}

// 5，当web内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    
    NSLog(@"web内容开始返回");
    
    if ([self.delegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [self.delegate webView:webView didCommitNavigation:navigation];
    }
}

// 6.1，web视图加载完成之后调用（加载成功）
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    NSLog(@"web加载完成");
            
    if ([self.delegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [self.delegate webView:webView didFinishNavigation:navigation];
    }
}

// 6.2，web视图加载内容发生错误（加载失败）
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    NSLog(@"web加载失败");
    
    if ([self.delegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.delegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

#pragma mark - KVO 监听：进度条、网页标题

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == _wkWebView) {
        NSLog(@"网页加载进度 = %f",_wkWebView.estimatedProgress);
        self.webProgress.progress = _wkWebView.estimatedProgress;
        if (_webProgress.progress >= 1.0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [self->_webProgress removeFromSuperview];
               self->_webProgress = nil;
            });
        }
    } else if([keyPath isEqualToString:@"title"] && object == _wkWebView) {
        if ([self.delegate respondsToSelector:@selector(webTitleWithString:)]) {
            [self.delegate webTitleWithString:_wkWebView.title];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 封装方法调用集合

- (UIViewController *)findViewController {
    id target = self;
    while (target) {
        target = ((UIResponder *)target).nextResponder;
        if ([target isKindOfClass:[UIViewController class]])
            break;
    }
    return target;
}

#pragma mark - 懒加载

- (WKWebView *)wkWebView {
    if (!_wkWebView) {
        _wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:self.webConfig];
        // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
        _wkWebView.allowsBackForwardNavigationGestures = YES;
    }
    return _wkWebView;
}

- (WKWebViewConfiguration *)webConfig {
    if(_webConfig == nil) {
        _webConfig = [WKWebViewConfiguration new];
        _webConfig.preferences = self.preferences;
//        // HTML5视频是否内嵌播放(yes)或使用native全屏控制器播放(no)
//        _webConfig.allowsInlineMediaPlayback = YES;
//        //设置视频是否需要用户手动播放  设置为NO则会允许自动播放
//        _webConfig.requiresUserActionForMediaPlayback = YES;
//        //设置是否允许画中画技术 在特定设备上有效
//        _webConfig.allowsPictureInPictureMediaPlayback = YES;
        //设置请求的User-Agent信息中应用程序名称 iOS9后可用
        _webConfig.applicationNameForUserAgent = @"ChinaDailyForiPad";
    }
    return _webConfig;
}

- (WKPreferences *)preferences {
    if (!_preferences) {
        _preferences = [[WKPreferences alloc] init];
//        //最小字体大小 当将javaScriptEnabled属性设置为NO时，可以看到明显的效果
//        _preferences.minimumFontSize = 0;
//        //设置是否支持javaScript 默认是支持的
//        _preferences.javaScriptEnabled = YES;
//        // 在iOS上默认为NO，表示是否允许不经过用户交互由javaScript自动打开窗口
//        _preferences.javaScriptCanOpenWindowsAutomatically = YES;
    }
    return _preferences;
}

- (NSMutableArray<WKUserScript *> *)userScripts {
    if (!_userScripts) {
        NSString *jSString = @"document.documentElement.style.webkitTouchCallout='none';";
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
        _userScripts = [NSMutableArray arrayWithObjects:userScript, nil];
    }
    return _userScripts;
}

- (WKUserContentController *)userContentController {
    if (!_userContentController) {
        _userContentController = [WKUserContentController new];
    }
    return _userContentController;
}

- (UIProgressView *)webProgress {
    if (!_webProgress) {
        _webProgress = [[UIProgressView alloc] init];
        _webProgress.backgroundColor = [UIColor clearColor];
        _webProgress.progressTintColor = _progressColor ?: [UIColor whiteColor];
        _webProgress.trackTintColor = [UIColor clearColor];
        UIViewController *vc = [self findViewController];
        if (vc.navigationController.view) {
            //调用者需要保证，在开始加载内容之前（调用四种加载内容的方法），先添加WLWebView到父视图。如此才会进来
            [vc.navigationController.view addSubview:_webProgress];
        } else {
            //反之，会进来这里
            [self addSubview:_webProgress];
        }
    }
    return _webProgress;
}

#pragma mark - 方法重写

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    _wkWebView.opaque = NO;
    _wkWebView.backgroundColor = backgroundColor;
}

#pragma mark - dealloc

- (void)removeScriptMessageHandlers {
    if (_jsObjects.count) {
        for (NSString *jsObject in _jsObjects) {
            [_userContentController removeScriptMessageHandlerForName:jsObject];
        }
    }
}

- (void)removeKVO {
    if (_setWebTitle) {
        [_wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(title))];
    }
    
    if (_setProgress) {
        [_wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
}

- (void)dealloc {
    [self removeScriptMessageHandlers];
    [self removeKVO];

    NSLog(@"===== %@ release =====", [self class]);
}

@end
