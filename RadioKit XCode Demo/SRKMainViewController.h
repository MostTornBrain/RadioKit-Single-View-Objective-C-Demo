//
//  SRKMainViewController.h
//  RadioKit XCode 5 Demo
//
//  Created by Brian Stormont on 9/21/13.
//  Copyright (c) 2013 Stormy Productions. All rights reserved.
//

#import "SRKFlipsideViewController.h"
#import "RadioKit.h"
#import "BufferView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "Visuallizer.h"

@interface SRKMainViewController : UIViewController <SRKFlipsideViewControllerDelegate,StormysRadioKitDelegate, NSXMLParserDelegate> {

    RadioKit *radioKit;

    IBOutlet MPVolumeView *volumeView;
    UISlider *volumeViewSlider;
    IBOutlet UILabel *netStatusLabel;

    IBOutlet BufferView *bufferView;
    NSTimer *bufferViewTimer;
	NSTimer *audioVisualTimer;
	IBOutlet Visuallizer *visualizer;

    IBOutlet UIButton	*playButton;
    IBOutlet UIButton	*rewButton;
    IBOutlet UIButton	*ffButton;
    IBOutlet UIActivityIndicatorView *busyIcon;
    IBOutlet UILabel	*bufferLabel;
    NSTimer *rewOrFFTimer;  // Handles holding down the rewind/FF button

    time_t prevNoNetworkWarning;

    NSString *albumURL;
    NSString *albumInfo;
    
    IBOutlet UIImageView *albumArtwork;
    NSString *lastFMImageUrl;
	NSString *lastFMAlbumUrl;
	NSString *lastFMArtistUrl;
    bool parserStartAlbum, parserStartArtist;
	NSMutableString *currentStringValue;

}

- (void)SaveAlbumInfo: (NSString *)titleInfo URL: (NSString *)artURL;
- (void) showNoNetworkAlert;
- (void) updateAudioButtons;

- (void) setButtonToPlayImage;
- (void) setButtonToStopImage;
- (IBAction) playOrStop: (id) sender;
- (void) rewind;
- (IBAction) rewindDown: (id) sender;
- (IBAction) rewindUp: (id) sender;
- (void) fastForward;
- (IBAction) fastForwardDown: (id) sender;
- (IBAction) fastForwardUp: (id) sender;
- (void) updateStatusString;

- (void)startBufferViewThread;
- (void)stopBufferViewThread;
- (void) bufferVisualThread;

@end
