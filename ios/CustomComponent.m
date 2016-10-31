//
//  CustomComponent.m
//  owalMobile
//
//  Created by Mateo Barraza on 2016-07-20.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "CustomComponent.h"

@implementation CustomComponent
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(writeFile:(NSString *)fileName
                  withContents:(NSString *)contents
                  errorCallback:(RCTResponseSenderBlock)failureCallback
                  callback:(RCTResponseSenderBlock)successCallback) {
  
  NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  
  successCallback(@[@"Write method called"]);
}


// Load data from disk and return the String.
RCT_EXPORT_METHOD(readFile:(NSString *)fileName
                  errorCallback:(RCTResponseSenderBlock)failureCallback
                  callback:(RCTResponseSenderBlock)successCallback) {
  
  NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
  
  successCallback(@[@"Read method called"]);
}
@end