//
//  WeakScriptMessageDelegate.h
//  MobileTYCJ
//
//  Created by DuBenBen on 2020/4/23.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface WLWeakScriptMessageDelegate : NSObject <WKScriptMessageHandler>

+ (instancetype)weakDelegae:(id<WKScriptMessageHandler>)scriptMessageDelegate;

@end

NS_ASSUME_NONNULL_END
