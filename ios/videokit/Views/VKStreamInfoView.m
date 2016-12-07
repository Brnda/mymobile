//
//  VKStreamInfoView.m
//  VideoKit
//
//  Created by Murat Sudan
//  Copyright (c) 2014 iOS VideoKit. All rights reserved.
//  Elma DIGITAL
//

#import "VKStreamInfoView.h"
#import "VKDecodeManager.h"

#import <QuartzCore/QuartzCore.h>

@implementation VKStreamInfoView {
    
    CALayer *_styleLayer;
    UILabel *_labelTitleGeneral;
    UILabel *_labelConnection;
    UILabel *_labelConnectionValue;
    UILabel *_labelDownload;
    UILabel *_labelDownloadValue;
    UILabel *_labelBitrate;
    UILabel *_labelBitrateValue;

    UILabel *_labelTitleAudio;
    UITextView *_textViewAudio;

    UILabel *_labelTitleVideo;
    UITextView *_textViewVideo;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor colorWithRed:.3 green:.3 blue:.3 alpha:.6];

        _styleLayer = [[CALayer alloc] init];
        _styleLayer.cornerRadius = 8.0;
        _styleLayer.shadowColor= [[UIColor redColor] CGColor];
        _styleLayer.shadowOffset = CGSizeMake(0, 0);
        _styleLayer.shadowOpacity = 0.5;
        _styleLayer.borderWidth = 1;
        _styleLayer.borderColor = [[UIColor whiteColor] CGColor];
        self.layer.cornerRadius = _styleLayer.cornerRadius;
        [self.layer addSublayer:_styleLayer];
        
        /* _labelTitleGeneral */
        _labelTitleGeneral = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelTitleGeneral.translatesAutoresizingMaskIntoConstraints = NO;
        _labelTitleGeneral.opaque = NO;
        _labelTitleGeneral.backgroundColor = [UIColor clearColor];
        _labelTitleGeneral.text = TR(@"General");
        _labelTitleGeneral.textAlignment = NSTextAlignmentLeft;
        _labelTitleGeneral.textColor = [UIColor whiteColor];
        _labelTitleGeneral.font = [UIFont boldSystemFontOfSize:15.0];
        [self addSubview:_labelTitleGeneral];
        
        // align _labelTitleGeneral from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_labelTitleGeneral(==240)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelTitleGeneral)]];
        // align _labelTitleGeneral from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[_labelTitleGeneral(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelTitleGeneral)]];

        /* _labelConnection */
        _labelConnection = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelConnection.translatesAutoresizingMaskIntoConstraints = NO;
        _labelConnection.numberOfLines = 1;
        _labelConnection.opaque = NO;
        _labelConnection.backgroundColor = [UIColor clearColor];
        _labelConnection.text = TR(@"Connection");
        _labelConnection.textColor = [UIColor whiteColor];
        _labelConnection.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:_labelConnection];
        
        // align _labelTitleGeneral from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_labelConnection(==92)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelConnection)]];
        // align _labelTitleGeneral from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-29-[_labelConnection(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelConnection)]];
        

        /* _labelConnectionValue */
        _labelConnectionValue = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelConnectionValue.translatesAutoresizingMaskIntoConstraints = NO;
        _labelConnectionValue.numberOfLines = 1;
        _labelConnectionValue.opaque = NO;
        _labelConnectionValue.backgroundColor = [UIColor clearColor];
        _labelConnectionValue.textColor = [UIColor colorWithWhite:1.000 alpha:1.000];
        _labelConnectionValue.adjustsFontSizeToFitWidth = YES;
        _labelConnectionValue.lineBreakMode = NSLineBreakByTruncatingTail;
        _labelConnectionValue.minimumScaleFactor = 0.2;
        _labelConnectionValue.font = [UIFont systemFontOfSize:13.0];
        _labelConnectionValue.text = TR(@"-");
        [self addSubview:_labelConnectionValue];
        
        // align _labelConnectionValue from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-120-[_labelConnectionValue(==140)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelConnectionValue)]];
        // align _labelConnectionValue from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-29-[_labelConnectionValue(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelConnectionValue)]];

        /* _labelDownload */
        _labelDownload = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelDownload.translatesAutoresizingMaskIntoConstraints = NO;
        _labelDownload.numberOfLines = 1;
        _labelDownload.opaque = NO;
        _labelDownload.backgroundColor = [UIColor clearColor];
        _labelDownload.text = TR(@"Download");
        _labelDownload.textColor = [UIColor whiteColor];
        _labelDownload.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:_labelDownload];
        
        // align _labelDownload from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_labelDownload(==92)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelDownload)]];
        // align _labelDownload from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-50-[_labelDownload(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelDownload)]];

        /* _labelDownloadValue */
        _labelDownloadValue = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelDownloadValue.translatesAutoresizingMaskIntoConstraints = NO;
        _labelDownloadValue.numberOfLines = 1;
        _labelDownloadValue.opaque = NO;
        _labelDownloadValue.backgroundColor = [UIColor clearColor];
        _labelDownloadValue.textColor = [UIColor colorWithWhite:1.000 alpha:1.000];
        _labelDownloadValue.adjustsFontSizeToFitWidth = YES;
        _labelDownloadValue.lineBreakMode = NSLineBreakByTruncatingTail;
        _labelDownloadValue.minimumScaleFactor = 0.2;
        _labelDownloadValue.font = [UIFont systemFontOfSize:13.0];
        _labelDownloadValue.text = TR(@"-");
        [self addSubview:_labelDownloadValue];
        // align _labelDownloadValue from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-120-[_labelDownloadValue(==140)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelDownloadValue)]];
        // align _labelDownloadValue from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-50-[_labelDownloadValue(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelDownloadValue)]];
        
        /* _labelBitrate */
        _labelBitrate = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelBitrate.translatesAutoresizingMaskIntoConstraints = NO;
        _labelBitrate.numberOfLines = 1;
        _labelBitrate.opaque = NO;
        _labelBitrate.backgroundColor = [UIColor clearColor];
        _labelBitrate.text = TR(@"Bitrate");
        _labelBitrate.textColor = [UIColor whiteColor];
        _labelBitrate.font = [UIFont systemFontOfSize:13.0];
        [self addSubview:_labelBitrate];
        
        // align _labelBitrate from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_labelBitrate(==92)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelBitrate)]];
        // align _labelBitrate from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-71-[_labelBitrate(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelBitrate)]];
        
        /* _labelBitrateValue */
        _labelBitrateValue = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelBitrateValue.translatesAutoresizingMaskIntoConstraints = NO;
        _labelBitrateValue.numberOfLines = 1;
        _labelBitrateValue.opaque = NO;
        _labelBitrateValue.backgroundColor = [UIColor clearColor];
        _labelBitrateValue.textColor = [UIColor colorWithWhite:1.000 alpha:1.000];
        _labelBitrateValue.adjustsFontSizeToFitWidth = YES;
        _labelBitrateValue.lineBreakMode = NSLineBreakByTruncatingTail;
        _labelBitrateValue.minimumScaleFactor = 0.2;
        _labelBitrateValue.font = [UIFont systemFontOfSize:13.0];
        _labelBitrateValue.text = TR(@"-");
        [self addSubview:_labelBitrateValue];
        
        // align _labelBitrateValue from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-120-[_labelBitrateValue(==140)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelBitrateValue)]];
        // align _labelBitrateValue from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-71-[_labelBitrateValue(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelBitrateValue)]];
        
        /* _labelTitleAudio */
        _labelTitleAudio = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelTitleAudio.translatesAutoresizingMaskIntoConstraints = NO;
        _labelTitleAudio.opaque = NO;
        _labelTitleAudio.backgroundColor = [UIColor clearColor];
        _labelTitleAudio.text = TR(@"Audio");
        _labelTitleAudio.textAlignment = NSTextAlignmentLeft;
        _labelTitleAudio.textColor = [UIColor whiteColor];
        _labelTitleAudio.font = [UIFont boldSystemFontOfSize:15.0];
        [self addSubview:_labelTitleAudio];
        
        // align _labelTitleAudio from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_labelTitleAudio(==240)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelTitleAudio)]];
        // align _labelTitleAudio from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-97-[_labelTitleAudio(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelTitleAudio)]];

        /* _textViewAudio */
        _textViewAudio = [[UITextView alloc] initWithFrame:CGRectZero];
        _textViewAudio.translatesAutoresizingMaskIntoConstraints = NO;
        _textViewAudio.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.000];
#if !TARGET_OS_TV
        _textViewAudio.editable = NO;
        _textViewAudio.pagingEnabled = YES;
#endif
        _textViewAudio.opaque = NO;
        _textViewAudio.backgroundColor = [UIColor clearColor];
        _textViewAudio.scrollEnabled = YES;
        _textViewAudio.showsHorizontalScrollIndicator = NO;
        _textViewAudio.showsVerticalScrollIndicator = YES;
        _textViewAudio.textAlignment = NSTextAlignmentLeft;
        _textViewAudio.textColor = [UIColor whiteColor];
        _textViewAudio.font = [UIFont systemFontOfSize:12.0];
        [self addSubview:_textViewAudio];
        
        // align _textViewAudio from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_textViewAudio(==240)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_textViewAudio)]];
        // align _textViewAudio from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-115-[_textViewAudio(==44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_textViewAudio)]];
        
        /* _labelTitleVideo */
        _labelTitleVideo = [[UILabel alloc] initWithFrame:CGRectZero];
        _labelTitleVideo.translatesAutoresizingMaskIntoConstraints = NO;
        _labelTitleVideo.opaque = NO;
        _labelTitleVideo.backgroundColor = [UIColor clearColor];
        _labelTitleVideo.text = TR(@"Video");
        _labelTitleVideo.textAlignment = NSTextAlignmentLeft;
        _labelTitleVideo.textColor = [UIColor whiteColor];
        _labelTitleVideo.font = [UIFont boldSystemFontOfSize:15.0];
        [self addSubview:_labelTitleVideo];
        
        // align _labelTitleVideo from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_labelTitleVideo(==240)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelTitleVideo)]];
        // align _labelTitleVideo from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-161-[_labelTitleVideo(==16)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_labelTitleVideo)]];

        /* _textViewVideo */
        _textViewVideo = [[UITextView alloc] initWithFrame:CGRectZero];
        _textViewVideo.translatesAutoresizingMaskIntoConstraints = NO;
        _textViewVideo.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.000];
#if !TARGET_OS_TV
        _textViewVideo.editable = NO;
        _textViewVideo.pagingEnabled = YES;
#endif
        _textViewVideo.opaque = NO;
        _textViewVideo.backgroundColor = [UIColor clearColor];
        _textViewVideo.scrollEnabled = YES;
        _textViewVideo.showsHorizontalScrollIndicator = NO;
        _textViewVideo.showsVerticalScrollIndicator = YES;
        _textViewVideo.textAlignment = NSTextAlignmentLeft;
        _textViewVideo.textColor = [UIColor whiteColor];
        _textViewVideo.font = [UIFont systemFontOfSize:12.0];
        _textViewVideo.text = TR(@"...");
        [self addSubview:_textViewVideo];
        
        // align _textViewVideo from the left
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[_textViewVideo(==240)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_textViewVideo)]];
        // align _textViewVideo from the top
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-179-[_textViewVideo(==44)]" options:0 metrics:nil views:NSDictionaryOfVariableBindings(_textViewVideo)]];
    }
    return self;
}

- (void)updateSubviewsWithInfo:(NSDictionary *)info {
    NSString *strValConnection = [info objectForKey:STREAMINFO_KEY_CONNECTION];
    if (strValConnection) {
        _labelConnectionValue.text = strValConnection;
    }

    NSNumber *numValDownload = [info objectForKey:STREAMINFO_KEY_DOWNLOAD];
    if (numValDownload) {
        _labelDownloadValue.text = [NSString stringWithFormat:@"%lu KB",[numValDownload unsignedLongValue]/1000];
    }

    NSNumber *numValBitrate = [info objectForKey:STREAMINFO_KEY_BITRATE];
    if (numValBitrate) {
        _labelBitrateValue.text = [NSString stringWithFormat:@"%lld kb/s",[numValBitrate longLongValue]/1000];
    }

    NSString *strValAudio = [info objectForKey:STREAMINFO_KEY_AUDIO];
    if (strValAudio) {
        _textViewAudio.text = strValAudio;
    }

    NSString *strValVideo = [info objectForKey:STREAMINFO_KEY_VIDEO];
    if (strValVideo) {
        _textViewVideo.text = strValVideo;
    }
}

#pragma mark - UIView callbacks

- (void)layoutSubviews {
    [super layoutSubviews];
    _styleLayer.frame = self.bounds;
}

#pragma mark - Memory deallocation

- (void)dealloc {
    [_styleLayer release];
    [_labelTitleGeneral release];
    [_labelConnection release];
    [_labelConnectionValue release];
    [_labelDownload release];
    [_labelDownloadValue release];
    [_labelBitrate release];
    [_labelBitrateValue release];
    [_labelTitleAudio release];
    [_textViewAudio release];
    [_labelTitleVideo release];
    [_textViewVideo release];
    [super dealloc];
}

@end
