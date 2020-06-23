//
//  WKWebBaseVC.m
//  WKWebView
//
//  Created by Mac on 2018/11/16.
//  Copyright © 2018 DuWenliang. All rights reserved.
//

#import "WKWebBaseVC.h"


//遵守了协议，未实现代理方法，出现警告。没关系，我们在子类实现了代理方法（这里只是记录可以这么写，但是最好还是写到具体的子类里，因为这么写，子类不提示代理方法）
@interface WKWebBaseVC ()<WKNavigationDelegate,WKUIDelegate,WKScriptMessageHandler> {
    id _content;
}

@property (nonatomic,strong) WKPreferences *preferences;

@end


@implementation WKWebBaseVC

#pragma mark - 懒加载

- (WKWebView *)webView {
    if (!_webView) {
        _webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:self.webConfig];   
        _webView.UIDelegate = self;
        _webView.navigationDelegate = self;
        // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
        _webView.allowsBackForwardNavigationGestures = YES;
        //可返回的页面列表, 存储已打开过的网页，类似 Nav 的 viewControllers
//        WKBackForwardList *backForwardList = [_webView backForwardList];
        //背景色设置方式
        _webView.opaque = NO;
        _webView.backgroundColor = [UIColor redColor];
    }
    return _webView;
}

- (WKWebViewConfiguration *)webConfig {
    if(_webConfig == nil) {
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

- (WKPreferences *)preferences {
    if (!_preferences) {
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

- (void)loadContentWithType:(WKContentType)contentType {
#warning 这里以最常用的HTML文件为例。若文件是doc docx pdf，方式3自然是不能使用的，方式1、2没问题，方式4乱码（具体测试详见下面的两处注释）
    NSString *localPath = [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html"];
//    localPath = [[NSBundle mainBundle] pathForResource:@"tre.docx" ofType:nil];

    //方式3、4需要传 baseURL 才可以；方式1传allowingReadAccessToURL，和baseURL类似
    switch (contentType) {
        //方式1：加载本地URL（加载本地专用）
        case WKContentLocalURL:
        {
            _content = [NSURL fileURLWithPath:localPath];
            [self.webView loadFileURL:_content allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
        }
            break;
        //方式2：加载本地、网络的 URL（以本地为例，网络的同理）
        case WKContentNetURL:
        {
            _content = [NSURL fileURLWithPath:localPath];
            [self.webView loadRequest:[NSURLRequest requestWithURL:_content]];
        }
            break;
        //方式3：加载本地、网络请求下来的 htmlStr（以本地为例，网络的同理）
        case WKContentHtmlString:
        {
            _content = [[NSString alloc] initWithContentsOfFile:localPath encoding:NSUTF8StringEncoding error:nil];
            [self.webView loadHTMLString:_content baseURL:[[NSBundle mainBundle] bundleURL]];
        }
            break;
        //方式4：加载本地、网络请求下来的 data（以本地为例，网络的同理）
        case WKContentData:
        {
            _content = [[NSData alloc] initWithContentsOfFile:localPath];
            [self.webView loadData:_content MIMEType:@"text/html" characterEncodingName:@"UTF-8" baseURL:[[NSBundle mainBundle] bundleURL]];
//            [self.webView loadData:_content MIMEType:@"application/vnd.openxmlformats-officedocument.wordprocessingml.document" characterEncodingName:@"UTF-8" baseURL:[[NSBundle mainBundle] bundleURL]];
        }
            break;
        default:
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.translucent = NO;
    
    [self.view addSubview:self.webView];
    
    NSLog(@"父类 viewDidLoad 调用完毕");
}

@end
