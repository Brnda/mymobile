//
//  VideoControllerViewView.h
//  owalMobile
//
//  Created by Yakov Okshtein on 11/7/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "VideoControllerView.h"

@interface VideoControllerViewView : UIView

///The URI to play
@property (nonatomic, assign) NSString *uri;

///The controller
@property (nonatomic, strong) VideoControllerView *controller;

@end
