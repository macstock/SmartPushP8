//
//  Sec.h
//  SmartPush
//
//  Created by runlin on 2017/2/27.
//  Copyright © 2017年 www.skyfox.org. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SecType) {
    SecTypeCer,//cer 证书类型
    SecTypeP8// p8类型
};

@interface Sec2 : NSObject
//通用属性
@property (nonatomic) SecType type;//当前证书类型
@property (nonatomic,copy) NSString *name;
@property (nonatomic,strong) NSDate *date;
@property (nonatomic,copy)   NSString *expire;
//@property (nonatomic,assign)  BOOL fromFile;

//cer only
@property (nonatomic) SecCertificateRef certificateRef;
@property (nonatomic,copy) NSString *key;
@property (nonatomic,copy) NSString *topicName;

//p8 only
@property (nonatomic, copy) NSString *p8String;


@end
