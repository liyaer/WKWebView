//
//  WKNavDelgateVC.m
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import "WKNavDelgateVC.h"


#define DScreenWidth [UIScreen mainScreen].bounds.size.width


@interface WKNavDelgateVC ()//未写WKNavigationDelegate和设置代理关系，因为父类实现了这一过程，虽然可以使用代理方法，但是并不会出现方法提示

@property (nonatomic,strong) UIProgressView *webProgress;

@end


@implementation WKNavDelgateVC

#pragma mark - 懒加载

-(UIProgressView *)webProgress
{
    if (!_webProgress)
    {
        _webProgress = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, DScreenWidth, 1)];
        _webProgress.progressTintColor = [UIColor redColor];
//        _webProgress.trackTintColor = [UIColor whiteColor];
        [self.view addSubview:_webProgress];
    }
    return _webProgress;
}




#pragma mark - 初始化

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    //加载本地、网络的 URL
    NSString *localPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    _url = [NSURL fileURLWithPath:localPath];
    _url = [NSURL URLWithString:@"https://mbd.baidu.com/newspage/data/landingsuper?context=%7B%22nid%22%3A%22news_9454146075587313245%22%7D&n_type=0&p_from=1"];
//    _url = [NSURL URLWithString:@"http://www.baidu.com"];
    [self.webView loadRequest:[NSURLRequest requestWithURL:_url]];
    
//    [self.webView loadHTMLString:@"<html><head><title></title><script language='javascript'>location.href='http://mob.cnki.net/EditorB3N/EditorWorkPlace/ReferDown.aspx?mid=yanshi3&downID=l4Nn%2fWscihnFWEifytU5nResR%2bSB47VLVNhQyFg%2bJar1NPOObG3a1V4WYxQ%2brwXf5N6%2fgIh%2b%2fFVo7xWkoO5KOSnBka4%2bUl0tQcPOvT%2bwEPpGwUQRK88zsuuzq0le0r9eyvSrXYshurZt90cdwtLoyaMlwZ4yTk69yJwUA6VTkFH7FXd4BTGJoUmFxMnUrWuZggzEDIE5X9RPOOm58m5c0ljHnncsdO8X4tt22KI16RCVqYLqwzitPXF5uQ8CreCTR4gq9gXE7ecdGNfTSi2XSQtGXcy1gO%2ba&paperNum=20180120&paperTitle=%E6%97%A9%E6%9C%9F%E8%BF%90%E5%8A%A8%E7%96%97%E6%B3%95%E7%BB%93%E5%90%88%E7%89%A9%E7%90%86%E7%96%97%E6%B3%95%E5%AF%B9%E8%80%81%E5%B9%B4%E4%B8%8B%E8%82%A2%E9%AA%A8%E6%8A%98%E6%9C%AF%E5%90%8E%E6%82%A3%E8%80%85%E8%BF%90%E5%8A%A8%E5%8A%9F%E8%83%BD%E7%9A%84%E5%BD%B1%E5%93%8D';</script></head><body></body></html>" baseURL:nil];
    
    
    //添加监测网页加载进度的观察者
    [self.webView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(estimatedProgress))//或者像下面一样这样写：@"estimatedProgress"
                      options:0//或者像下面一样这样写：NSKeyValueObservingOptionNew
                      context:nil];
    //添加监测网页标题title的观察者
    [self.webView addObserver:self
                   forKeyPath:@"title"
                      options:NSKeyValueObservingOptionNew
                      context:nil];
}

//kvo 监听进度 必须实现此方法
-(void)observeValueForKeyPath:(NSString *)keyPath
                     ofObject:(id)object
                       change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                      context:(void *)context
{
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.webView)
    {
        NSLog(@"网页加载进度 = %f",self.webView.estimatedProgress);
        self.webProgress.progress = self.webView.estimatedProgress;
        if (self.webView.estimatedProgress >= 1.0f)
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
           {
#warning Xcode9.3版本以后会出现，修改方法笔记中已记载，但是这不修改是想回忆self->访问成员变量的用法
               self->_webProgress.progress = 0;
           });
        }
    }
    else if([keyPath isEqualToString:@"title"] && object == self.webView)
    {
        self.navigationItem.title = self.webView.title;
    }
    else
    {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}




#pragma mark - WKNavigationDelegate : 主要处理一些跳转拦截、加载过程的各个状态的操作

/*
    调用顺序：
        没有重定向: 1 - 2 - 4 - （5） - 6（若是6.2，那么可能不经过5）
        有重定向(以一次重定向为例): 1 - 2 - 1(重定向的拦截) - 3 - 4 -(5) - 6
 
    个别方法说明：
        1，4 通常用于处理跨域的链接能否导航（WebKit对跨域进行了安全检查限制，不允许跨域，因此我们要对不能跨域的链接单独处理）
 */

// 1，在发送请求之前，决定是否允许或取消导航。（可拦截即将发送的 HTTP 请求头信息和其他相关信息）
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *urlStr = navigationAction.request.URL.absoluteString;
    NSLog(@"发送跳转请求：%@",urlStr);
    //自己定义的协议头
    NSString *htmlHeadString = @"http";
    if([urlStr hasPrefix:htmlHeadString])
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"WKNavigationDelegate 通过截取 请求头 进行某些操作" message:@"这是一个网络连接，是否继续?" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action)
         {
             decisionHandler(WKNavigationActionPolicyCancel);//终止跳转（导航）
         }])];
        [alertController addAction:([UIAlertAction actionWithTitle:@"打开" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action)
         {
             decisionHandler(WKNavigationActionPolicyAllow);//继续跳转（导航）
         }])];
        [self presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        decisionHandler(WKNavigationActionPolicyAllow);//继续跳转（导航）
    }
}

// 2，web视图开始加载web内容时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"web开始加载");
}

// 3，收到服务器重定向之后调用 (接收到服务器跳转请求)
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"重定向调用");
}

// 4，收到响应后，决定是否允许或取消导航。（可拦截客户端收到的服务器“响应头”相关信息）
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSString * urlStr = navigationResponse.response.URL.absoluteString;
    NSLog(@"当前跳转地址：%@",urlStr);
    //自己定义的协议头
    NSString *htmlHeadString = @"http://";
    if([urlStr hasPrefix:htmlHeadString])
    {
        decisionHandler(WKNavigationResponsePolicyCancel);//不允许跳转
    }
    else
    {
        decisionHandler(WKNavigationResponsePolicyAllow);//允许跳转
    }
}

// 5，当web内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"web内容开始返回");
}

// 6.1，web视图加载完成之后调用（加载成功）
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    NSLog(@"web加载完成");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
   {
       [self->_webProgress removeFromSuperview];
       self->_webProgress = nil;
   });
    
    // 禁用选中效果（禁止复制粘贴选项）实测这一句就可以，也可以使用WKUserScript注入的方式
    [self.webView evaluateJavaScript:@"document.documentElement.style.webkitUserSelect='none'" completionHandler:nil];
//    [self.webView evaluateJavaScript:@"document.documentElement.style.webkitTouchCallout='none'" completionHandler:nil];
}

// 6.2，web视图加载内容发生错误（加载失败）
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"web加载失败");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
   {
       [self->_webProgress removeFromSuperview];
       self->_webProgress = nil;
   });
}

#warning 以下方法未测试出，何时调用

// web视图导航过程中发生错误时调用。
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"web视图导航发生错误");
}

// web视图的Web内容进程终止时调用。
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    NSLog(@"web内容终止");
}

//需要响应身份验证时调用 同样在block中需要传入用户身份凭证
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler
{
    //使用场景一：
    //用户身份信息
    NSURLCredential * newCred = [[NSURLCredential alloc] initWithUser:@"user123" password:@"123" persistence:NSURLCredentialPersistenceNone];
    //为 challenge 的发送方提供 credential
    [challenge.sender useCredential:newCred forAuthenticationChallenge:challenge];
    completionHandler(NSURLSessionAuthChallengeUseCredential,newCred);
    
    //使用场景二：
    //当使用 Https 协议加载web内容时，使用的证书不合法或者证书过期时需要使用该方法
//    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
//    {
//        if ([challenge previousFailureCount] == 0)
//        {
//            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]; completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
//        }
//        else
//        {
//            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
//        }
//    }
//    else
//    {
//        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
//    }
}




#pragma mark - dealloc

-(void)dealloc
{
    //移除观察者
    [self.webView removeObserver:self
                  forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [self.webView removeObserver:self
                  forKeyPath:NSStringFromSelector(@selector(title))];
}

@end
