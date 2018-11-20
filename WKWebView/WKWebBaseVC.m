//
//  WKWebBaseVC.m
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import "WKWebBaseVC.h"


@interface WKWebBaseVC () <WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler>

@property (nonatomic,strong) WKPreferences *preferences;

@end


@implementation WKWebBaseVC//遵守了协议，未实现代理方法，出现警告。没关系，我们在子类实现了代理方法（这里只是记录可以这么写，但是最好还是写到具体的子类里，因为这么写，子类不提示代理方法）

#pragma mark - 懒加载

-(WKWebView *)webView
{
    if (!_webView)
    {
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:self.webConfig];
        // UI代理
        _webView.UIDelegate = self;
        // 导航代理
        _webView.navigationDelegate = self;
        // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
        _webView.allowsBackForwardNavigationGestures = YES;
        //可返回的页面列表, 存储已打开过的网页，类似 Nav 的 viewControllers
//        WKBackForwardList *backForwardList = [_webView backForwardList];
    }
    return _webView;
}

//添加WKWebView配置信息
- (WKWebViewConfiguration *)webConfig
{
    if(_webConfig == nil)
    {
        _webConfig = [WKWebViewConfiguration new];
        _webConfig.preferences = self.preferences;
        // HTML5视频是否内嵌播放(yes)或使用native全屏控制器播放(no)
        _webConfig.allowsInlineMediaPlayback = YES;
        //设置视频是否需要用户手动播放  设置为NO则会允许自动播放
        _webConfig.requiresUserActionForMediaPlayback = YES;
        //设置是否允许画中画技术 在特定设备上有效
        _webConfig.allowsPictureInPictureMediaPlayback = YES;
        //设置请求的User-Agent信息中应用程序名称 iOS9后可用
        _webConfig.applicationNameForUserAgent = @"ChinaDailyForiPad";
    }
    return _webConfig;
}

// 创建设置对象
-(WKPreferences *)preferences
{
    if (!_preferences)
    {
        _preferences = [[WKPreferences alloc] init];
        //最小字体大小 当将javaScriptEnabled属性设置为NO时，可以看到明显的效果
        _preferences.minimumFontSize = 0;
        //设置是否支持javaScript 默认是支持的
        _preferences.javaScriptEnabled = YES;
        // 在iOS上默认为NO，表示是否允许不经过用户交互由javaScript自动打开窗口
        _preferences.javaScriptCanOpenWindowsAutomatically = YES;
    }
    return _preferences;
}




#pragma mark -初始化

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.translucent = NO;
    
    [self.view addSubview:self.webView];
    
    NSLog(@"父类 viewDidLoad 调用完毕");
}


@end
