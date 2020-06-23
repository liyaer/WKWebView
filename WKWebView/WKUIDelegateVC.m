//
//  WKUIDelegateVC.m
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import "WKUIDelegateVC.h"


//未遵循<WKUIDelegate>和设置代理关系，因为父类实现了这一过程，虽然可以使用代理方法，但是并不会出现方法提示
@interface WKUIDelegateVC ()

@property (nonatomic,strong) WKUserContentController *userViewController;
@property (nonatomic,strong) WKUserScript *userScript;

@end


@implementation WKUIDelegateVC

#pragma mark - 懒加载

//这个类主要用来做native与JavaScript的交互管理
- (WKUserContentController *)userViewController {
    if(_userViewController == nil) {
        _userViewController = [WKUserContentController new];
        [_userViewController addUserScript:self.userScript];
    }
    return _userViewController;
}

//OC 调用 JS（常用于WKWebView初始化，一般是注入一段额外的js代码，进行一些全局性的配置，比如我们常说的文字大小、图片适配等。当然evaluateJavaScript也可以完成这些操作，evaluateJavaScript使用范围更广阔）
- (WKUserScript *)userScript {
    if (!_userScript) {
        NSString *jSString = @"var count = document.images.length; for (var i = 0; i < count; i++) {var image = document.images[i];image.style.width=280;}; window.alert('找到' + count + '张图'); document.documentElement.style.webkitUserSelect='none'";
        _userScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    }
    return _userScript;
}

#pragma mark - 初始化

- (void)viewDidLoad {
    self.webConfig.userContentController = self.userViewController;
    
    [self loadContentWithType:WKContentNetURL];
    
    //先执行子类 viewDidLoad，后执行父类 viewDidLoad（因为Demo需要 webView 的初始化需要在配置 webConfig 中的userViewController 之后）
    [super viewDidLoad];
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
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    //拦截到web页面的alert，使用原生alert代替展示
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"WKUIDelegate HTML的弹出框使用原生alert代替" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
     {
         completionHandler();
     }])];
    [self presentViewController:alertController animated:YES completion:nil];
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
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
     {
         completionHandler(NO);
     }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
     {
         completionHandler(YES);
     }])];
    [self presentViewController:alertController animated:YES completion:nil];
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
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField)
     {
         textField.text = defaultText;
     }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
     {
         completionHandler(alertController.textFields[0].text?:@"");
     }])];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
    {
        completionHandler(defaultText);
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

// 页面是弹出窗口 _blank 处理（创建新的webView）
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

/*
    关于<createWebViewWithConfiguration>的调用时机：（网上的资料，自己未验证）
 
情景再现：当html源代码中，一个可点击的标签带有 target='_blank' 时，导致WKWebView无法加载点击后的网页的问题（就是点击某个按钮无反应）。
 
问题出现的原因：_blank 标签，众所周知，是让浏览器新开一个页面来打开链接，而不是在原网页上打开。在UIWebView上，只有一个页面，所以会自动在原来的页面上打开新链接。但是在WKWebView上就不是这样了。
 
WKWebView的处理机制：WKWebView 的 WKNavigationDelegate 有一个
 - (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;
 方法。用户点击网页上的链接，需要打开新页面时，将先调用这个方法。这个方法的参数 WKNavigationAction 中有两个属性：sourceFrame和targetFrame，分别代
 表这个action的出处和目标。类型是 WKFrameInfo 。WKFrameInfo有一个 mainFrame 的属性，正是这个属性标记着这个frame是在主frame里还是新开一个frame。
 如果 targetFrame 的 mainFrame 属性为NO，表明这个 WKNavigationAction 将会新开一个页面。 WKWebView遇到这种情况，将会调用 它的 WKUIDelegate 代理中的
 - (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures;
 方法。开发者实现这个方法，返回一个新的WKWebView，让 WKNavigationAction 在新的webView中打开。如果你没有设置 WKUIDelegate代理，或者没有实现这个协
 议。那么WKWebView将什么事情都不会做，也就是你点那个按钮没反应。

 注意：返回的这个WKWebView不能和原来的WKWebView是同一个。如果你返回了原来的webView，将会抛出异常。
 
 apple设置这个协议的作用就是要求开发者新开一个webView。但实际使用中，我们的应用中webView也就拿来简简单单显示网页罢了，写那么复杂没必要。
 解决办法：
    方式一：就是上面所写的那样。 这样处理的话，相当于放弃掉原来的点击事件，强制让webView加载打开的链接。
    缺点：有时候navigationAction.request 竟然是空的！request的URL是空的！（我没遇到过，未能验证）
 
    方式二：在这里，将网页上所有的_blank标签都去掉了。一劳永逸。。。。。。
 - (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
 {
     if (!navigationAction.targetFrame.isMainFrame)
     {
        [webView evaluateJavaScript:@"var a = document.getElementsByTagName('a');for(var i=0;i<a.length;i++){a[i].setAttribute('target','');}" completionHandler:nil];
     }
     decisionHandler(WKNavigationActionPolicyAllow);
 }
 
 */


@end
