//
//  VideoController.h
//  owalMobile
//
//  Created by Mateo Barraza on 10/14/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VKPlayerViewController.h"

@interface VideoControllerView : UIViewController

- (void)player:(VKPlayerControllerBase *)player didChangeState:(VKDecoderState)state errorCode:(VKError)errCode;
- (id)initWithDecoderOptions:(NSDictionary *)options;

///The bar title of Video Player
@property (nonatomic, retain) NSString *barTitle;

///Specify YES to hide status bar, default is NO
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

///Set your Parent View Controller as delegate If you want to be notified for state changes of VKPlayerViewController
@property (nonatomic, assign) id<VKPlayerViewControllerDelegate> delegate;

///Specify YES to show video in extended screen, default is NO
@property (nonatomic, assign) BOOL allowAirPlay;

///Specify YES to fit video frames fill to the player view, default is NO
@property (nonatomic, assign) BOOL fillScreen;

#ifdef VK_RECORDING_CAPABILITY
///Specify YES to enable recording functionality, default is NO
@property (nonatomic, assign, getter = isRecordingEnabled) BOOL recordingEnabled;
#endif

#pragma mark License management properties

///If license-form is not accessible, fill this parameter with your username taken from our server
@property (nonatomic, retain) NSString *username;

///If license-form is not accessible, fill this parameter with your secret taken from our server
@property (nonatomic, retain) NSString *secret;

- (void)playUri:(NSString *)uri;

@end
