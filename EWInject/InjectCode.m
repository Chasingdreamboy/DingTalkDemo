//
//  InjectCode.m
//  EWInject
//
//  Created by Ericydong on 2020/1/8.
//  Copyright © 2020 EricyDong. All rights reserved.
//

#import "InjectCode.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/CaptiveNetwork.h>

@implementation InjectCode

BOOL (*ori_application_didFinishLaunchingWithOptions)(id, SEL,UIApplication *, NSDictionary *);
BOOL ericy_application_didFinishLaunchingWithOptions(id self, SEL _cmd, UIApplication * application, NSDictionary *options) {
    NSDictionary *infoDictionary =  [[NSBundle mainBundle] infoDictionary];
    [infoDictionary setValue:@"com.laiwang.DingTalk" forKey:@"CFBundleIdentifier"];
    ori_application_didFinishLaunchingWithOptions(self, _cmd, application, options);
    NSLog(@"infoDictionary == %@", infoDictionary);
    return true;
}

typedef void(^DTCallback)(NSDictionary *);
void (*ori_handleJavaScriptRequest_callback)(id, SEL, id, DTCallback);
void ericy_handleJavaScriptRequest_callback(id self, SEL _cmd, id request, DTCallback callback) {
    if (ori_handleJavaScriptRequest_callback) {
        DTCallback mycallback = ^(NSDictionary * params){
            NSString *action = request[@"action"];
            if ([action isEqualToString:@"getInterface"]) {
                NSDictionary *_params = @{
                    @"errorCode" : @"0",
                    @"errorMessage" : @"",
                    @"keep" : @"0",
                    @"result" :     @{
                            @"macIp" : @"88:25:93:e:b5:5f",
                            @"ssid" : @"xinshen 2.4",
                    }
                };
                params = _params;
            } else if ([action isEqualToString:@"start"]) {
                NSMutableDictionary *_params = params.mutableCopy;
                NSMutableDictionary *result = ((NSDictionary *)[_params objectForKey:@"result"]).mutableCopy;
                result[@"accuracy"] = /*@"146.403686473159"*/@"30";
                result[@"aMapCode"] = @(0);
                //                result[@"accuracy"] = @(89);
                result[@"latitude"] = @"30.26646864149306";
                result[@"longitude"] = @"120.0974801974826";
                result[@"netType"] = @"wifi";
                result[@"operatorType"] = @"CMCC";
                result[@"resultCode"] = @(0);
                result[@"resultMessage"] = @"";
                [_params setValue:result forKey:@"result"];
                params = (NSDictionary *)_params;
                
            }
            
            callback(params);
        };
        ori_handleJavaScriptRequest_callback(self, _cmd, request, mycallback);
    }
}

+ (void)load {
    //替换启动方法
    Class class = objc_getClass("DTAppDelegate");
    SEL sel = sel_registerName("application:didFinishLaunchingWithOptions:");
    Method method = class_getInstanceMethod(class, sel);
    ori_application_didFinishLaunchingWithOptions = (BOOL(*)(id, SEL, UIApplication *,NSDictionary *))method_setImplementation(method, (IMP)ericy_application_didFinishLaunchingWithOptions);
    

    Class class_LAPluginInstanceCollector = objc_getClass("LAPluginInstanceCollector");
    SEL sel_handleJavaScriptRequest_callback = sel_registerName("handleJavaScriptRequest:callback:");
    
    Method method_handleJavaScriptRequest_callback = class_getInstanceMethod(class_LAPluginInstanceCollector, sel_handleJavaScriptRequest_callback);
    ori_handleJavaScriptRequest_callback = (void(*)(id, SEL, id, DTCallback))method_setImplementation(method_handleJavaScriptRequest_callback, (IMP)ericy_handleJavaScriptRequest_callback);
}
@end
