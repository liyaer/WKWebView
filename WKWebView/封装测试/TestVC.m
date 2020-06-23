//
//  TestVC.m
//  WKWebView
//
//  Created by DuBenBen on 2020/3/29.
//  Copyright © 2020 DuWenliang. All rights reserved.
//

#import "TestVC.h"
#import "WLWebView.h"


@interface TestVC () <WLWebViewDelegate>

@property (nonatomic, strong) WLWebView *wlWebView;

@end


@implementation TestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBar.translucent = NO;

    [self loadWKWebView];
}

#pragma mark - WKWebView

- (void)loadWKWebView {
    WKUserScript *userScript1 = [[WKUserScript alloc] initWithSource:@"var count = document.images.length; for (var i = 0; i < count; i++) {var image = document.images[i];image.style.width=220;}; window.alert('找到' + count + '张图');" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserScript *userScript2 = [[WKUserScript alloc] initWithSource:@"document.documentElement.style.webkitUserSelect='none'" injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];

    _wlWebView = [[WLWebView alloc] initWithFrame:self.view.bounds webConfig:nil setJSObjectsInteractiveOC:@[@"changeText_oc", @"pushVC_oc"] setOCInteractiveJSUserScripts:@[userScript1, userScript2] setUIDelegate:YES setNavigationDelegate:NO setWebTitle:NO setProgress:YES progressColor:[UIColor greenColor]];
    _wlWebView.delegate = self;
    [self.view addSubview:_wlWebView];

    NSString *localPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
    NSURL *url = [NSURL fileURLWithPath:localPath];
    [_wlWebView loadFileURL:url allowingReadAccessToURL:url];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    if ([@"changeText_oc" isEqualToString:message.name]) {
        [self changeText_oc:message.body];
    }
    
    if ([@"pushVC_oc" isEqualToString:message.name]) {
        [self pushVC_oc];
    }
}

- (void)changeText_oc:(NSString *)changeString {
    //字符串内容描述的是 JS 的函数调用
    NSString *changeStr = [NSString stringWithFormat: @"changeButtonWithText('%@')", changeString];//@"changeColor()";
    // OC 调用 JS ，使用- evaluateJavaScript:completionHandler
    [_wlWebView evaluateJavaScript:changeStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
         NSLog(@"oc 调用了 js");
         NSLog(@"%@----%@",result, error);
     }];
}

- (void)pushVC_oc {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor whiteColor];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - dealloc

- (void)dealloc {
    NSLog(@"%@ release", [self class]);
}

@end
