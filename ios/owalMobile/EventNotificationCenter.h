//
//  EventNotificationCenter.h
//  owalMobile
//
//  Created by Mateo Barraza on 10/26/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RCTEventEmitter.h"
#import  "RCTBridge.h"
#import "RCTBridgeModule.h"

@interface EventNotificationCenter : RCTEventEmitter
+ (void)emitEventWithName:(NSString *)name andPayload:(NSDictionary *)payload;
@end
