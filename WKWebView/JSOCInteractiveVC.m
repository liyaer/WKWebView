//
//  JSOCInteractiveVC.m
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import "JSOCInteractiveVC.h"


//未遵循<WKScriptMessageHandler>，因为父类实现了这一过程，虽然可以使用代理方法，但是并不会出现方法提示
@interface JSOCInteractiveVC ()

@property (nonatomic,strong) WKUserContentController *userViewController;

@end


@implementation JSOCInteractiveVC

#pragma mark - 懒加载

//这个类主要用来做native与JavaScript的交互管理
- (WKUserContentController *)userViewController {
    if(_userViewController == nil) {
        _userViewController = [WKUserContentController new];
    }
    return _userViewController;
}

#pragma mark - 初始化

- (void)viewDidLoad {
    self.webConfig.userContentController = self.userViewController;
    
//    [self loadContentWithType:WKContentLocalURL];
//    [self loadContentWithType:WKContentNetURL];
//    [self loadContentWithType:WKContentHtmlString];
    [self loadContentWithType:WKContentData];
    
    //先执行子类 viewDidLoad，后执行父类 viewDidLoad（因为Demo需要 webView 的初始化需要在配置 webConfig 中的userViewController 之后）
    [super viewDidLoad];
}

#pragma mark - 使用WKUserContentController注入的交互协议, 需要遵循WKScriptMessageHandler协议, 在其协议方法中获取JavaScript端传递的事件和参数。

//可以注入多个对象，通过对象名称，来判断执行
- (void)viewWillAppear:(BOOL)animated {
    [self.userViewController addScriptMessageHandler:self name:@"changeText_oc"];
    [self.userViewController addScriptMessageHandler:self name:@"pushVC_oc"];
}

//注意：addScriptMessageHandler容易引起循环引用，导致控制器无法被释放。(类似NSTimer，不能在dealloc中释放)
- (void)viewWillDisappear:(BOOL)animated {
    [self.userViewController removeScriptMessageHandlerForName:@"changeText_oc"];
    [self.userViewController removeScriptMessageHandlerForName:@"pushVC_oc"];
}

#pragma mark - WKScriptMessageHandler

//JS 调用 OC (JS端通过 window.webkit.messageHandlers.<name>.postMessage(<messageBody>) 发送消息时，下面的方法就会被执行。）
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"js 调用了 oc");

    // name 是自己注册协议时的 name
    if ([@"changeText_oc" isEqualToString:message.name]) {
        // body 中是 JS 携带过来的可用参数
        [self changeText_oc:(NSString *)message.body];
    } else if ([@"pushVC_oc" isEqualToString:message.name]) {
        [self pushVC_oc];
    }
}

- (void)changeText_oc:(NSString *)sourceString {
    NSLog(@"需要改变的内容是：%@", sourceString);
    
    //字符串内容描述的是 JS 的函数调用
    NSString *changeStr = @"changeButtonWithText('我的名字叫中国');changeColor()";
    // OC 调用 JS ，使用- evaluateJavaScript:completionHandler
    [self.webView evaluateJavaScript:changeStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
         NSLog(@"oc 调用了 js");
         NSLog(@"%@----%@",result, error);
    }];
}

- (void)pushVC_oc {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
