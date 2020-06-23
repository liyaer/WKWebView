//
//  BaseURLTestVC.m
//  WKWebView
//
//  Created by DuBenBen on 2020/4/7.
//  Copyright © 2020 DuWenliang. All rights reserved.
//

#import "BaseURLTestVC.h"
#import <WebKit/WebKit.h>


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
    
    
    //测试须知：文件：html文件   资源：html文件内引用的外部资源（图片等）
    //测试前提：文件内引用资源使用的是相对路径

//----------------------------------常规情况------------------------------------
    
    //case1：文件、资源都在黄色文件夹，且在同一级目录。baseURL 传 [[NSBundle mainBundle] bundleURL]] 即可（传 [NSURL fileURLWithPath:localPath]也可以）
    //case2：文件、资源都在黄色文件夹，但不在同一级目录。同case1
//    localPath = [[NSBundle mainBundle] pathForResource:@"index1" ofType:@"html"];
//    [webView loadFileURL:[NSURL fileURLWithPath:localPath] allowingReadAccessToURL:[[NSBundle mainBundle] bundleURL]];
    
    //case3：文件、资源都在蓝色文件夹，且在同一级目录。baseURL 传 [NSURL fileURLWithPath:localPath]（文件路径） 即可
    //只有文件在蓝色文件夹中时，该方法返回正确路径；文件在黄色文件夹内时返回nil
    localPath = [[NSBundle mainBundle] pathForResource:@"index2" ofType:@"html" inDirectory:@"ReadHtml"];
    [webView loadFileURL:[NSURL fileURLWithPath:localPath] allowingReadAccessToURL:[NSURL fileURLWithPath:localPath]];
    
//----------------------------------奇葩情况------------------------------------
    
    //case4：文件、资源都在蓝色文件夹，但不在同一级目录。
    
    //case5：文件在黄，资源在蓝
    
    //case5：文件在蓝，资源在黄
    
    //这些都无法成功，应该需要修改html中的 相对路径 为 绝对路径，未测试！
}

@end
