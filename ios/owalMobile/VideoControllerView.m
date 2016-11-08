//
//  VideoController.m
//  owalMobile
//
//  Created by Mateo Barraza on 10/14/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "VideoControllerView.h"
#import "VKPlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import "VideoControllerViewView.h"

@interface VideoControllerView() <VKPlayerControllerDelegate> {
  NSDictionary *_options;
  VKPlayerControllerBase *_playerController;
  BOOL _allowAirPlay;
  BOOL _fillScreen;
}
@end

@implementation VideoControllerView

@synthesize barTitle = _barTitle;
@synthesize statusBarHidden = _statusBarHidden;
@synthesize delegate = _delegate;
@synthesize allowAirPlay = _allowAirPlay;
@synthesize fillScreen = _fillScreen;
@synthesize username = _username;
@synthesize secret = _secret;

- (id)initWithDecoderOptions:(NSDictionary *)options {
  
  self = [super init];
  if (self) {
    // Custom initialization
    _options = options;
    _playerController = [[VKPlayerController alloc] init];
    
    _playerController.barTitle = @"My Floor";
    _playerController.decoderOptions = _options;
    
//  _playerController.delegate = self;
    _username = @"sol@owal.io";
    _secret = @"a285d4025ca53fd8bd75ab3402d0f88e";
    return self;
  }
  return nil;
}


- (void)player:(VKPlayerControllerBase *)player didChangeState:(VKDecoderState)state errorCode:(VKError)errCode {
  NSLog(@"Error is %u", errCode);
}

- (void)player:(VKPlayerControllerBase *)player didStartRecordingWithPath:(NSString *)recordPath {
  
}

- (void)player:(VKPlayerControllerBase *)player didStopRecordingWithPath:(NSString *)recordPath error:(VKErrorRecorder)error {
  
}

#pragma mark View life cycle


- (void)loadView {
  CGRect bounds = CGRectZero;

  bounds = [[UIScreen mainScreen] bounds];
  
//  if (UIDeviceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
//    bounds =  CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.height, bounds.size.width);
//  }
  
  VideoControllerViewView *view = [[VideoControllerViewView alloc] initWithFrame:bounds];
  view.controller = self;
  self.view = view;
  self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
    //running on iOS 7.0 or higher
    self.edgesForExtendedLayout = UIRectEdgeNone;
  }
  _playerController.username = _username;
  _playerController.secret = _secret;
  
  UIView *playerView = _playerController.view;
  playerView.translatesAutoresizingMaskIntoConstraints = NO;
  //_playerController.containerVc = self;
  [_playerController setFullScreen:YES];
  [self.view addSubview:playerView];
  
  // align _playerController.view from the left and right
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
  
  // align _playerController.view from the top and bottom
  [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[playerView]-0-|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(playerView)]];
  
  //[_playerController play];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
  [super viewDidDisappear:animated];
}

#pragma mark View controller rotation methods & callbacks

- (BOOL)shouldAutorotate {
  return YES;
}

-(UIInterfaceOrientationMask)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return  YES;//(interfaceOrientation != UIDeviceOrientationPortraitUpsideDown);
}

- (void)playUri:(NSString *)uri {
  
  NSLog(@"Playing uri: %@", uri);
  _playerController.contentURLString = uri;
  [_playerController play];
}

@end
