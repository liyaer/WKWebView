//
//  WeakScriptMessageDelegate.m
//  MobileTYCJ
//
//  Created by DuBenBen on 2020/4/23.
//

#import "WLWeakScriptMessageDelegate.h"


@interface WLWeakScriptMessageDelegate ()

@property (nonatomic, weak) id<WKScriptMessageHandler> scriptMessageDelegate;

@end


@implementation WLWeakScriptMessageDelegate

+ (instancetype)weakDelegae:(id<WKScriptMessageHandler>)scriptMessageDelegate {
    return [[self alloc] initWithDelegate:scriptMessageDelegate];
}

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)scriptMessageDelegate {
    if (self = [super init]) {
        _scriptMessageDelegate = scriptMessageDelegate;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    [_scriptMessageDelegate userContentController:userContentController didReceiveScriptMessage:message];
}

- (void)dealloc {
    NSLog(@"===== %@ release =====", [self class]);
}

@end
