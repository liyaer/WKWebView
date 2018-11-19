//
//  WKUIDelegateVC.m
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import "WKUIDelegateVC.h"


@interface WKUIDelegateVC ()//未写WKUIDelegate和设置代理关系，因为父类实现了这一过程，虽然可以使用代理方法，但是并不会出现方法提示

@property (nonatomic,strong) WKUserContentController *userViewController;
@property (nonatomic,strong) WKUserScript *userScript;

@end


@implementation WKUIDelegateVC

#pragma mark - 懒加载

//这个类主要用来做native与JavaScript的交互管理
- (WKUserContentController *)userViewController
{
    if(_userViewController == nil)
    {
        _userViewController = [WKUserContentController new];
        [_userViewController addUserScript:self.userScript];
    }
    return _userViewController;
}

//用于进行JavaScript注入（这里一般是注入一段额外的js代码，进行一些全局性的配置，比如我们常说的文字大小、图片适配等。本质上不属于oc和js的交互，注意区分）
-(WKUserScript *)userScript
{
    if (!_userScript)
    {
        NSString *jSString = @"var count = document.images.length;for (var i = 0; i < count; i++) {var image = document.images[i];image.style.width=220;};window.alert('找到' + count + '张图');";
        _userScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    }
    return _userScript;
}




#pragma mark - 初始化

- (void)viewDidLoad
{
    self.webConfig.userContentController = self.userViewController;
    
    _url = [NSURL URLWithString:@"https://mbd.baidu.com/newspage/data/landingsuper?context=%7B%22nid%22%3A%22news_9454146075587313245%22%7D&n_type=0&p_from=1"];//@"http://www.baidu.com"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:_url]];
    
    //先执行子类 viewDidLoad，后执行父类 viewDidLoad（因为Demo需要 webView 的初始化需要在配置 webConfig 中的userViewController 之后）
    [super viewDidLoad];
}




#pragma mark - WKUIDelegate : 主要处理JS脚本，确认框，警告框等

/**
 *  web界面中有alert(js代码写的alert)时调用
 *
 *  @param webView           实现该代理的webview
 *  @param message           警告框中的内容
 *  @param completionHandler 警告框消失调用
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

#warning 以下方法未测试出，何时调用
// 确认框
//JavaScript调用confirm方法后回调的方法 confirm是js中的确定框，需要在block中把用户选择的情况传递进去
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

// 输入框
//JavaScript调用prompt方法后回调的方法 prompt是js中的输入框 需要在block中把用户输入的信息传入
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
    [self presentViewController:alertController animated:YES completion:nil];
}

// 页面是弹出窗口 _blank 处理
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame)
    {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}



@end
