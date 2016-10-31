//
//  EventNotificationCenter.m
//  owalMobile
//
//  Created by Mateo Barraza on 10/26/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "EventNotificationCenter.h"

@implementation EventNotificationCenter

- (instancetype)init {
  self = [super init];
  
  return self;
}

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents{
  return @[@"closeVideoManager"];
}

- (void)startObserving
{
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(emitEventInternal:)
                                               name:@"event-emitted"
                                             object:nil];
}

- (void)stopObserving
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)emitEventInternal:(NSNotification *)notification
{
  [self sendEventWithName:@"closeVideoManager"
                     body:notification.userInfo];
}

+ (void)emitEventWithName:(NSString *)name andPayload:(NSDictionary *)payload
{
  [[NSNotificationCenter defaultCenter] postNotificationName:@"event-emitted"
                                                      object:self
                                                    userInfo:payload];
}


@end
