//
//  NetworkManager.m
//  SmartPush
//
//  Created by shao on 2021/8/24.
//  Copyright © 2021 www.skyfox.org. All rights reserved.
//

#import "NetworkManager.h"
static dispatch_once_t _onceToken;
static NetworkManager *_sharedManager = nil;

@implementation NetworkManager

+ (NetworkManager*)sharedManager {
    
    dispatch_once(&_onceToken, ^{
        _sharedManager = [[self alloc] init];
        
    });
    
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)disconnect {
    
}
#pragma mark - Public
- (void)setIdentity:(SecIdentityRef)identity {
    
    if (_identity != identity) {
        if (_identity != NULL) {
            CFRelease(_identity);
        }
        if (identity != NULL) {
            _identity = (SecIdentityRef)CFRetain(identity);
            
            // Create a new session
            NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
            self.session = [NSURLSession sessionWithConfiguration:conf
                                                         delegate:self
                                                    delegateQueue:[NSOperationQueue mainQueue]];
            
        } else {
            _identity = NULL;
        }
    }
}

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
              exeFailed:(void(^)(NSString *error))exeFailed {
    
    
    NSInteger apiIndex = 0;
    NSString *url;
    if (lineTypeIsSandbox) {//api.sandbox
        url = [NSString stringWithFormat:@"https://api%@.push.apple.com/3/device/%@", envIsDev ? @".sandbox" : @"", token];
    } else {//api.development
        url = [NSString stringWithFormat:@"https://api%@.push.apple.com/3/device/%@", envIsDev ? @".development" : @"", token];
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 10;
    request.HTTPBody = [payload dataUsingEncoding:NSUTF8StringEncoding];
    
    if (topic.length) {
        [request addValue:topic forHTTPHeaderField:@"apns-topic"];
    }
    if (collapseID.length) {
        [request addValue:collapseID forHTTPHeaderField:@"apns-collapse-id"];
    }
    if (priority.length) {
        [request addValue:[NSString stringWithFormat:@"%@", priority] forHTTPHeaderField:@"apns-priority"];
    }
    if (p8Token.length) {
        [request addValue:[NSString stringWithFormat:@"bearer %@", p8Token] forHTTPHeaderField:@"authorization"];
    }
    [request addValue:pushType forHTTPHeaderField:@"apns-push-type"];
    
    NSURLSession *session = self.session;
    if (session == nil) {
        session = [NSURLSession sharedSession];
    }
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
            if (r == nil ||  error) {
                if (exeFailed) {
                    exeFailed(error.debugDescription);
                }
            } else {
                NSError *perror;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&perror];
                if (r.statusCode == 200 && !error) {
                    if (exeSuccess) {
                        exeSuccess(dict);
                    }
                } else {
                    NSString *reason = dict[@"reason"];
                    NSLog(@"reason:%@",reason);
                    exeFailed(reason);
                }
            }
        });
        
    }];
    [task resume];
}

#pragma mark - NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session task:(nonnull NSURLSessionTask *)task didReceiveChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    SecCertificateRef certificate;
    if (self.identity) {
        SecIdentityCopyCertificate(self.identity, &certificate);
        NSURLCredential *cred = [[NSURLCredential alloc] initWithIdentity:self.identity
                                                             certificates:@[(__bridge_transfer id)certificate]
                                                              persistence:NSURLCredentialPersistenceForSession];
        completionHandler(NSURLSessionAuthChallengeUseCredential, cred);
    } else {
        NSURLCredential *credential;
        if (!challenge) {
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, credential);
        }
    }
    
}

@end
