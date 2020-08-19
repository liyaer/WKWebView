//
//  BaseURLTestVC.m
//  WKWebView
//
//  Created by DuBenBen on 2020/4/7.
//  Copyright © 2020 DuWenliang. All rights reserved.
//

#import "BaseURLTestVC.h"
#import <WebKit/WebKit.h>


#define cese 1


@interface BaseURLTestVC ()

@end


/*
    首先，要了解 黄色文件夹 和 蓝色文件夹 的区别：
        黄色：
        蓝色：
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
#if (case == 1 || case == 2)
    //case1：文件、资源都在黄色文件夹，且在同一级目录。baseURL 传 [[NSBundle mainBundle] bundleURL]] 即可（传 [NSURL fileURLWithPath:localPath]也可以）
    //case2：文件、资源都在黄色文件夹，但不在同一级目录。同case1
/*  错误的访问方式，localPath = null
    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html" inDirectory:@"Resources"];
    NSLog(@"%@", localPath);
    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSLog(@"%@", localPath);
 */
    //文件在黄，通过该方法，使用 相对路径 访问
    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html"];
    NSLog(@"%@", localPath);
#elif (case == 3)
    //case3：文件、资源都在蓝色文件夹，且在同一级目录。baseURL 传 [NSURL fileURLWithPath:localPath]（文件路径） 即可
/*  错误的访问方式，localPath = null
    localPath = [[NSBundle mainBundle] pathForResource:@"index2" ofType:@"html"];
    NSLog(@"%@", localPath);
 */
    //文件在蓝，通过下面方法二选一，使用 绝对路径 访问
    localPath = [[NSBundle mainBundle] pathForResource:@"ReadHtml/index2" ofType:@"html"];
    NSLog(@"%@", localPath);
//    localPath = [[NSBundle mainBundle] pathForResource:@"index2" ofType:@"html" inDirectory:@"ReadHtml"];
//    NSLog(@"%@", localPath);
#endif
    fileUrl = [NSURL fileURLWithPath:localPath];
//    [webView loadFileURL:fileUrl allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
//    [webView loadFileURL:fileUrl allowingReadAccessToURL:[fileUrl URLByDeletingLastPathComponent]];
    
    [webView loadRequest:[NSURLRequest requestWithURL:fileUrl]];
    
//----------------------------------奇葩情况------------------------------------
    
    //case4：文件、资源都在蓝色文件夹，但不在同一级目录。
/*
    localPath = [[NSBundle mainBundle] pathForResource:@"index3" ofType:@"html" inDirectory:@"HanPi"];
    NSString *srcPath = [[NSBundle mainBundle] pathForResource:@"2" ofType:@"jpg" inDirectory:@"ReadHtml"];
    [webView loadFileURL:[NSURL fileURLWithPath:localPath] allowingReadAccessToURL:[NSURL fileURLWithPath:srcPath]];
 */

    //case5：文件在黄，资源在蓝
    
    //case5：文件在蓝，资源在黄
    
    //这些都无法成功，应该需要修改html中的 相对路径 为 绝对路径，未测试！
}

//条件编译
//loadFileURL（先） 和 loadRequest（后）
//allowingReadAccessToURL、baseUrl 是html内引用的资源所在的目录地址

@end
