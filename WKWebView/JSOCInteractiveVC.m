//
//  JSOCInteractiveVC.m
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import "JSOCInteractiveVC.h"


@interface JSOCInteractiveVC ()//未写WKScriptMessageHandler，因为父类实现了这一过程，虽然可以使用代理方法，但是并不会出现方法提示
{
    NSString *_htmlStr;
    NSData *_data;
}

@property (nonatomic,strong) WKUserContentController *userViewController;

@end


@implementation JSOCInteractiveVC

#pragma mark - 懒加载

//这个类主要用来做native与JavaScript的交互管理
- (WKUserContentController *)userViewController
{
    if(_userViewController == nil)
    {
        _userViewController = [WKUserContentController new];
    }
    return _userViewController;
}




#pragma mark - 初始化

- (void)viewDidLoad
{
    self.webConfig.userContentController = self.userViewController;
    
    NSString *localPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    /*
         三种初始化方式和 JS 交互的说明：（一般都是和网络的网页交互，本地的话没必要。这里以本地为例进行测试）
            若是本地的网页：方式一可以；方式二、三需要传 baseURL 才可以，传nil的话可以展示，但无法交互
            若是网络的网页：同上（未验证）
     
        小问题：对于方式二、三，baseUrl该传什么？两种方式采用不同写法，进行对比
     */
    //方式一：加载本地、网络的 URL（以本地为例，网络的同理）
//    _url = [NSURL fileURLWithPath:localPath];
//    [self.webView loadRequest:[NSURLRequest requestWithURL:_url]];
    
    //方式二：加载本地、网络请求下来的 htmlStr（以本地为例，网络的同理）
//    _htmlStr = [[NSString alloc] initWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:nil];
//    [self.webView loadHTMLString:_htmlStr baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath] /* localPath */]];
    
    //方式三：加载本地、网络请求下来的 data（以本地为例，网络的同理）
    _data = [[NSData alloc] initWithContentsOfFile:localPath];
    [self.webView loadData:_data MIMEType:@"text/html" characterEncodingName:@"UTF-8" baseURL:[NSURL fileURLWithPath:localPath /* [[NSBundle mainBundle] bundlePath] */]];
    
    
    //先执行子类 viewDidLoad，后执行父类 viewDidLoad（因为Demo需要 webView 的初始化需要在配置 webConfig 中的userViewController 之后）
    [super viewDidLoad];
}




#pragma mark - 使用WKUserContentController注入的交互协议, 需要遵循WKScriptMessageHandler协议, 在其协议方法中获取JavaScript端传递的事件和参数。

//self.userViewController 注入新对象，用来和JS交互。(可以注入多个对象，通过对象名称，来判断执行。)
- (void)viewWillAppear:(BOOL)animated
{
    [self.userViewController addScriptMessageHandler:self name:@"Native"];
}

//注意：addScriptMessageHandler容易引起循环引用，导致控制器无法被释放。(类似NSTimer，不能在dealloc中释放)
- (void)viewWillDisappear:(BOOL)animated
{
    [self.userViewController removeScriptMessageHandlerForName:@"Native"];
}




#pragma mark - WKScriptMessageHandler

//JS 调用 OC 时( JS 端可通过 window.webkit.messageHandlers.<name>.postMessage(<messageBody>) 发送消息调用OC代码)，下面的方法就会被执行。
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    NSLog(@"js 调用了 oc");

    // name 是自己注册协议时的 name
    if ([@"Native" isEqualToString:message.name])
    {
        // body 中是 JS 代码中的调用 OC 方法的名称（这个方法名一般会和 JS 端约定好）
        if ([@"changeText_oc" isEqualToString:message.body])
        {
            [self changeText_oc];
        }
        if([@"pushVC_oc" isEqualToString:message.body])
        {
            [self pushVC_oc];
        }
    }
}

- (void)changeText_oc
{
    //字符串内容描述的是 JS 的函数调用
    NSString *changeStr = @"changeButtonWithText('这是一个测试')";//@"changeColor()";
    // OC 调用 JS ，使用- evaluateJavaScript:completionHandler
    [self.webView evaluateJavaScript:changeStr completionHandler:^(id _Nullable result, NSError * _Nullable error)
     {
         NSLog(@"oc 调用了 js");
         NSLog(@"%@----%@",result, error);
     }];
}

-(void)pushVC_oc
{
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
