//
//  BaseURLTestVC.m
//  WKWebView
//
//  Created by DuBenBen on 2020/4/7.
//  Copyright © 2020 DuWenliang. All rights reserved.
//

#import "BaseURLTestVC.h"
#import <WebKit/WebKit.h>


#define case 2


@interface BaseURLTestVC ()

@end


/*
    首先，要了解 黄色文件夹 和 蓝色文件夹 的区别！
    算了，做成笔记吧！
 */
@implementation BaseURLTestVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:webView];
    NSString *localPath;
    NSURL *fileUrl;
    
    
    //测试须知：文件：html文件   资源：html文件内引用的外部资源（图片等）
    //测试前提：文件内引用资源使用的是相对路径

//----------------------------------常规情况------------------------------------
    
#if (case == 1)
    //case1：文件、资源都在黄色文件夹，是否在同一级目录无所谓
/*
 *错误的访问方式，localPath = null
    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html" inDirectory:@"Resources"];
    NSLog(@"%@", localPath);
    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSLog(@"%@", localPath);
 */
    //正确的访问方式，文件在黄，通过该方法，使用 相对路径 访问
    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html"];
    NSLog(@"%@", localPath);
#elif (case == 2)
    //case2：文件、资源都在蓝色文件夹，且在同一级目录
/*
 *错误的访问方式，localPath = null
    localPath = [[NSBundle mainBundle] pathForResource:@"index2" ofType:@"html"];
    NSLog(@"%@", localPath);
 */
    //正确的访问方式，文件在蓝，通过下面方法二选一，使用 绝对路径 访问
//    localPath = [[NSBundle mainBundle] pathForResource:@"ReadHtml/index2" ofType:@"html"];
//    NSLog(@"%@", localPath);
    localPath = [[NSBundle mainBundle] pathForResource:@"index2" ofType:@"html" inDirectory:@"ReadHtml"];
    NSLog(@"%@", localPath);
#endif
    
/*
 *allowingReadAccessToURL 和 baseUrl一样，代表html内引用的资源所在的目录地址
 *无论html文件内引用的资源是处在黄色还是蓝色文件夹，也无论各个资源所处的目录层级，最终都会被copy到mainBundle（关于这一点可以看笔记，蓝色：整体copy 黄色：仅copy资源文件），这就是为什么 BaseURL说明.png 中说一般传mainBundle路径即可
 *当然如果你明确资源的位置，可以适当缩小范围，不传mainBundle路径，而是像下面这样
    [webView loadFileURL:fileUrl allowingReadAccessToURL:[fileUrl URLByDeletingLastPathComponent]];
  甚至可以直接将fileUrl传进去
 */
    fileUrl = [NSURL fileURLWithPath:localPath];
    [webView loadFileURL:fileUrl allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
        
//----------------------------------奇葩情况------------------------------------
    
    //case3：文件、资源都在蓝色文件夹，但不在同一级目录
//    localPath = [[NSBundle mainBundle] pathForResource:@"index3" ofType:@"html" inDirectory:@"ReadHtml/HanPi"];
//    fileUrl = [NSURL fileURLWithPath:localPath];
////    [webView loadFileURL:fileUrl allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
//    NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpg" inDirectory:@"ReadHtml"];
//    [webView loadFileURL:fileUrl allowingReadAccessToURL:[[NSURL fileURLWithPath:srcPath] URLByDeletingLastPathComponent]];
 
    //case4：文件在黄，资源在蓝
//    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html"];
//    fileUrl = [NSURL fileURLWithPath:localPath];
//    [webView loadFileURL:fileUrl allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
////    NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpg" inDirectory:@"ReadHtml"];
////    [webView loadFileURL:fileUrl allowingReadAccessToURL:[[NSURL fileURLWithPath:srcPath] URLByDeletingLastPathComponent]];
    
    //case5：文件在蓝，资源在黄
//    localPath = [[NSBundle mainBundle] pathForResource:@"index2" ofType:@"html" inDirectory:@"ReadHtml"];
//    fileUrl = [NSURL fileURLWithPath:localPath];
//    [webView loadFileURL:fileUrl allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
    
    //这些都无法成功(已验证)，应该需要修改html中图片的 相对路径 为 绝对路径，未测试！
}

@end
