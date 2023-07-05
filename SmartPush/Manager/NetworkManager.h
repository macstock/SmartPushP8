//
//  NetworkManager.h
//  SmartPush
//
//  Created by shao on 2021/8/24.
//  Copyright © 2021 www.skyfox.org. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NetworkManager : NSObject<NSURLSessionDelegate>
@property (nonatomic, strong, nullable) __attribute__((NSObject)) SecIdentityRef identity;
@property (nonatomic, strong) NSURLSession *session;

+ (NetworkManager*)sharedManager;
//https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns?language=objc
- (void)postWithPayload:(NSString *)payload
            toToken:(NSString *)token
          withTopic:(nullable NSString *)topic
           priority:(nullable NSString *)priority
         collapseID:(nullable NSString *)collapseID
           pushType:(NSString *)pushType
            p8Token:(NSString *)p8Token
              isDev:(BOOL)envIsDev
  lineTypeIsSandbox:(BOOL)lineTypeIsSandbox
         exeSuccess:(void(^)(id responseObject))exeSuccess
          exeFailed:(void(^)(NSString *error))exeFailed;
- (void)disconnect;
@end

NS_ASSUME_NONNULL_END
