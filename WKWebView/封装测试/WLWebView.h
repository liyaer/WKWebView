//
//  WLWebView.h
//  WKWebView
//
//  Created by DuBenBen on 2020/3/29.
//  Copyright © 2020 DuWenliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WLWeakScriptMessageDelegate.h"


NS_ASSUME_NONNULL_BEGIN


@protocol WLWebViewDelegate <NSObject>

@optional

#pragma mark  KVO WebTitle

- (void)webTitleWithString:(NSString *)webTitle;

#pragma mark  WLNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler;

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation;

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error;

#pragma mark  WLScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end


@interface WLWebView : UIView

#pragma mark 指定初始化

- (instancetype)initWithFrame:(CGRect)frame webConfig:(WKWebViewConfiguration *)webConifg setJSObjectsInteractiveOC:(NSArray <NSString *> *)jsObjects setOCInteractiveJSUserScripts:(NSArray<WKUserScript *> *)userScripts setUIDelegate:(BOOL) setUIDelegate setNavigationDelegate:(BOOL)setNavigationDelegate setWebTitle:(BOOL)setWebTitle setProgress:(BOOL)setProgress progressColor:(UIColor *)progressColor;

#pragma mark 代理属性

@property (nonatomic, weak) id<WLWebViewDelegate> delegate;

#pragma mark 四种加载内容的方式

- (void)loadRequest:(NSURLRequest *)request;

- (void)loadHTMLString:(NSString *)string baseURL:(nullable NSURL *)baseURL;

- (void)loadFileURL:(NSURL *)URL allowingReadAccessToURL:(NSURL *)readAccessURL API_AVAILABLE(macos(10.11), ios(9.0));

- (void)loadData:(NSData *)data MIMEType:(NSString *)MIMEType characterEncodingName:(NSString *)characterEncodingName baseURL:(NSURL *)baseURL API_AVAILABLE(macos(10.11), ios(9.0));

#pragma mark  其他功能性方法

//OC 调用 JS
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler;

//返回web的history---[wkWebView goBack]，没有历史的话执行popViewController;
- (void)wlGoWebHistory;

//返回上一个界面---popViewController
- (void)wlPopViewController;

//返回主界面---popToRootViewController
- (void)wlPopRootViewController;

//刷新
- (void)wlReload;

@end

NS_ASSUME_NONNULL_END
