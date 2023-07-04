//
//  SecManager.h
//  SmartPush
//
//  Created by Jakey on 2017/2/22.
//  Copyright © 2017年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sec.h"
@interface SecManager : NSObject
+ (NSArray *)allPushCertificatesWithEnvironment:(BOOL)isDevelop;
+ (SecCertificateRef)certificatesWithPath:(NSString*)path;
+ (BOOL)isPushCertificate:(SecCertificateRef)sec;
+ (NSString *)subjectSummaryWithCertificate:(SecCertificateRef)certificate;
+ (NSDate *)expirationWithCertificate:(SecCertificateRef)certificate;
+ (NSArray *)allKeychainCertificatesWithError:(NSError *__autoreleasing *)error;
+ (Sec2*)secModelWithRef:(SecCertificateRef)sec;
+ (Sec2*)secModelWithP8Path:(NSString *)path;
@end
