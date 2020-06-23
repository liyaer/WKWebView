//
//  WKWebBaseVC.h
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>


NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, WKContentType) {
    WKContentLocalURL,
    WKContentNetURL,
    WKContentHtmlString,
    WKContentData
};


@interface WKWebBaseVC : UIViewController

@property (nonatomic,strong) WKWebView *webView;
@property (nonatomic,strong) WKWebViewConfiguration *webConfig;


- (void)loadContentWithType:(WKContentType)contentType;

@end

NS_ASSUME_NONNULL_END
