//
//  RuntimeStatus.m
//  IOSDuoduo
//
//  Created by Michael Scofield on 2014-07-31.
//  Copyright (c) 2014 dujia. All rights reserved.
//

#import "RuntimeStatus.h"
#import "MTTUserEntity.h"
#import "DDGroupModule.h"
#import "DDMessageModule.h"
#import "DDClientStateMaintenanceManager.h"
#import "NSString+Additions.h"
#import "ReceiveKickoffAPI.h"
#import "LogoutAPI.h"
#import "DDClientState.h"
#import "IMLogin.pb.h"
#import <AFNetworking.h>
#import "MTTSignNotifyAPI.h"
#import "MTTPCLoginStatusNotifyAPI.h"
#import "MTTUtil.h"

@interface RuntimeStatus()

@end

@implementation RuntimeStatus

+ (instancetype)instance
{
    static RuntimeStatus* g_runtimeState;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_runtimeState = [[RuntimeStatus alloc] init];
        
    });
    return g_runtimeState;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.user = [MTTUserEntity new];
        [self registerAPI];
        //[self checkUpdateVersion];
    }
    return self;
}

-(void)checkUpdateVersion
{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

    // 添加安全策略
    AFSecurityPolicy *securityPolicy = [[AFSecurityPolicy alloc] init];
    [securityPolicy setAllowInvalidCertificates:YES];
    [manager setSecurityPolicy:securityPolicy];
    
    [manager GET:@"http://tt.mogu.io/tt/ios.json" parameters:nil headers:nil progress:^(NSProgress * _Nonnull downloadProgress) {
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
        double version = [responseDictionary[@"version"] doubleValue];
        [MTTUtil setDBVersion:[responseDictionary[@"dbVersion"] intValue]];
        
        NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
        
        double app_Version = [[infoDictionary objectForKey:@"CFBundleShortVersionString"] doubleValue];
        if (app_Version < version) {
            self.updateInfo =@{@"haveupdate":@(YES),@"url":responseDictionary[@"url"]};
        }else{
              self.updateInfo =@{@"haveupdate":@(NO),@"url":@" "};
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
    }];
}
-(void)registerAPI
{
    //接收踢出
    ReceiveKickoffAPI *receiveKick = [ReceiveKickoffAPI new];
    [receiveKick registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DDNotificationUserKickouted object:object];
    }];
    //接收签名改变通知
    MTTSignNotifyAPI *receiveSignNotify = [MTTSignNotifyAPI new];
    [receiveSignNotify registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DDNotificationUserSignChanged object:object];
    }];
    //接收pc端登陆状态变化通知
    MTTPCLoginStatusNotifyAPI *receivePCLoginNotify = [MTTPCLoginStatusNotifyAPI new];
    [receivePCLoginNotify registerAPIInAPIScheduleReceiveData:^(id object, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DDNotificationPCLoginStatusChanged object:object];
    }];
}

-(void)updateData
{
    [DDMessageModule shareInstance];
    [DDClientStateMaintenanceManager shareInstance];
    [DDGroupModule instance];
}


@end
