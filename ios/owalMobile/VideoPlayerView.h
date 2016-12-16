//
//  VideoPlayerView.h
//  owalMobile
//
//  Created by Mateo Barraza on 12/13/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoPlayerView : UIView
@property (nonatomic, copy) NSString *uri;
- (void) play;
@end
