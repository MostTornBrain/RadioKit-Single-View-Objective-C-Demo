//
//  SRKMainViewController.m
//  RadioKit Single View Demo
//
//  Created by Brian Stormont.
//  Copyright (c) 2015 Stormy Productions. All rights reserved.
//

#import "SRKMainViewController.h"

@interface SRKMainViewController ()

@end

#define RADIO_CONNECTED_STR @"RadioKit is now playing..."
#define RADIO_STOPPED_STR @"Press play button to listen."
#define RADIO_PAUSED_STR @"Radio is paused. Press play button to listen."
#define STREAM_URL @"http://www.radioparadise.com/musiclinks/rp_64aac.m3u"  // TODO: insert the pls, m3u or direct URL for your radio stream
#define PLAY_BUTTON @"play.png"
#define STOP_BUTTON @"pause.png"

#define VISUAL_SAMPLE_RATE (1.0f/15.0f)


@implementation SRKMainViewController

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	static bool bDoOnce = YES;
	
    [super viewDidLoad];
	
	if (bDoOnce){
		bDoOnce = NO;
		
		radioKit = [[RadioKit alloc] init];
        
        // TODO - enter a real license key here
		[radioKit authenticateLibraryWithKey1:0x1234 andKey2:0x1234];
		NSLog(@"RadioKit version: %@", radioKit.version);
	}
	
	// Handle Audio Remote Control events (only available under iOS 4 and later
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(beginReceivingRemoteControlEvents)]){
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	}
	
}

-(void) viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	// This is necessary in order to get notified of the Audio Remote Control events
	[self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	
	[self resignFirstResponder];
}


-(BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	//NSLog(@"UIEventTypeRemoteControl: %d - %d", event.type, event.subtype);
	
	
	if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
		//NSLog(@"UIEventSubtypeRemoteControlTogglePlayPause");
		[self playOrStop:nil];
	}
	if (event.subtype == UIEventSubtypeRemoteControlPlay) {
		//NSLog(@"UIEventSubtypeRemoteControlPlay");
		[self playOrStop:nil];
	}
	if (event.subtype == UIEventSubtypeRemoteControlPause) {
		//NSLog(@"UIEventSubtypeRemoteControlPause");
		[self playOrStop:nil];
	}
	if (event.subtype == UIEventSubtypeRemoteControlStop) {
		//NSLog(@"UIEventSubtypeRemoteControlStop");
		[self playOrStop:nil];
	}
	if (event.subtype == UIEventSubtypeRemoteControlNextTrack) {
		//NSLog(@"UIEventSubtypeRemoteControlNextTrack");
		[self fastForward];
	}
	if (event.subtype == UIEventSubtypeRemoteControlPreviousTrack) {
		//NSLog(@"UIEventSubtypeRemoteControlPreviousTrack");
		[self rewind];
	}
}


- (void)startLiveStream
{
	radioKit.delegate = self;
	
    [radioKit setBufferWaitTime:15];
    [radioKit setDataTimeout:10];
	[radioKit setStreamUrl:STREAM_URL isFile:NO];
    [self updateAudioButtons];
	[self updateStatusString];
	
	// If your station uses AudioVault XML for "now playing" info, uncomment lines below and define the XML url and time zone
	
	//[radioKit setXMLMetaURL:XML_META_URL];
	//[radioKit setStationTimeZone: STATION_TIME_ZONE];
	//[radioKit setXmlDelay: 20.0f];
	//[radioKit beginXMLMeta];
}


- (void)viewWillAppear:(BOOL)animated 
{
	static bool bDoOnce = YES;
	
    [super viewWillAppear:animated];
	
	[self performSelectorInBackground:@selector(startLiveStream) withObject:nil];
    
	if (bDoOnce){
		bDoOnce = NO;
		
		// Display the visualization of the buffer
		// (This is not necessary, but displaying the buffer be helpful in some applications)
		[self startBufferViewThread];
        [self startAudioVisualizationThread];
        visualizer.radioKit = radioKit;
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(SRKFlipsideViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void)SaveAlbumInfo: (NSString *)titleInfo URL: (NSString *)artURL
{
    if (titleInfo){
		albumInfo = [NSString stringWithString: titleInfo];
	}else{
		albumInfo = @"";
	}
}



- (void) showNoNetworkAlert
{
	UIAlertView *baseAlert = [[UIAlertView alloc] 
							  initWithTitle:@"No Network" message:@"A network connection is required.  Please verify your network settings and try again." 
							  delegate:nil cancelButtonTitle:nil 
							  otherButtonTitles:@"OK", nil];	
	[playButton setImage:[UIImage imageNamed:PLAY_BUTTON]  forState:UIControlStateNormal];	
	[baseAlert show];
}


#pragma mark Audio Control Buttons

- (void) setButtonToPlayImage
{
	[playButton setImage:[UIImage imageNamed:PLAY_BUTTON]  forState:UIControlStateNormal];	
}


- (void) setButtonToStopImage
{
	[playButton setImage:[UIImage imageNamed:STOP_BUTTON]  forState:UIControlStateNormal];	
}


- (IBAction) playOrStop: (id) sender {
	
	int currStatus = [radioKit getStreamStatus];
	
	if (currStatus == SRK_STATUS_STOPPED || currStatus == SRK_STATUS_PAUSED){
		[radioKit startStream];
	}else if (currStatus == SRK_STATUS_PLAYING){
		[radioKit pauseStream];
	}else{
		// If we aren't playing (i.e we're connecting, buffering, etc. we do a full stop instead of a pause)
		[radioKit stopStream];
	}
	[self updateAudioButtons];
}


- (void) updateAudioButtons
{
	// Check if the stream is currently playing.  If so, adjust the play control buttons
	if ([radioKit getStreamStatus] != SRK_STATUS_STOPPED && 
		[radioKit getStreamStatus] != SRK_STATUS_PAUSED){
		
		[self setButtonToStopImage];
		rewButton.enabled = YES;
        
		if ([radioKit isFastForwardAllowed:10]){
            ffButton.enabled = YES;
		}else{
            ffButton.enabled = NO;
		}
	}else{
		[self setButtonToPlayImage];
		rewButton.enabled = NO;
		ffButton.enabled = NO;
	}
}

- (void) rewind
{	
	[radioKit rewind: 10];		  // Rewind 10 seconds
	[self updateAudioButtons];
}

- (IBAction) rewindDown: (id) sender
{
	[self rewind];
	rewOrFFTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(rewind) userInfo:nil repeats:YES];		
}


- (IBAction) rewindUp: (id) sender
{
	if (rewOrFFTimer != nil) 
		[rewOrFFTimer invalidate];
	rewOrFFTimer = nil;
}

- (void) fastForward
{
	[radioKit fastForward: 10];
	[self updateAudioButtons];
}


- (IBAction) fastForwardDown: (id) sender
{
	[self fastForward];
	rewOrFFTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(fastForward) userInfo:nil repeats:YES];		
}


- (IBAction) fastForwardUp: (id) sender
{
	if (rewOrFFTimer != nil) 
		[rewOrFFTimer invalidate];
	rewOrFFTimer = nil;
}


- (void) updateStatusString
{
	switch([radioKit getStreamStatus]){
			
		case SRK_STATUS_STOPPED:
			[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:RADIO_STOPPED_STR waitUntilDone:NO];
			break;
		case SRK_STATUS_CONNECTING:
			[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Connecting..." waitUntilDone:NO];
			break;
		case SRK_STATUS_BUFFERING:
			[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Buffering..." waitUntilDone:NO];
			break;
		case SRK_STATUS_PLAYING:
			if (radioKit.currTitle != nil){
				[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:radioKit.currTitle waitUntilDone:NO];
			}else{
				[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:RADIO_CONNECTED_STR waitUntilDone:NO];
			}
			break;
		case SRK_STATUS_PAUSED:
			break;
	}				
}



#pragma mark simple audio Visualizer
- (void) audioVisualizationThread
{
	[visualizer updateData];
}

- (void)stopAudioVisualizationThread
{
	if (audioVisualTimer){
		[audioVisualTimer invalidate];
		audioVisualTimer = nil;
	}
}

- (void)startAudioVisualizationThread
{
	audioVisualTimer = [NSTimer scheduledTimerWithTimeInterval:VISUAL_SAMPLE_RATE target:self selector:@selector(audioVisualizationThread) userInfo:nil repeats:YES];
}


#pragma mark Buffer Visualizer

- (void)startBufferViewThread
{
	bufferViewTimer = [NSTimer scheduledTimerWithTimeInterval:0.2f target:self selector:@selector(bufferVisualThread) userInfo:nil repeats:YES];
}


- (void)stopBufferViewThread
{
	[bufferViewTimer invalidate];
	bufferViewTimer = nil;
}


- (void) bufferVisualThread
{
	bufferView.bufferSizeSRK = [radioKit maxBufferSize];
	bufferView.bufferCountSRK = [radioKit currBufferUsage];
	bufferView.currBuffPtr = [radioKit currBufferPlaying];
	bufferView.bufferByteOffset = [radioKit bufferByteOffset];
	
	[bufferView performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];	
	
	if ([radioKit getStreamStatus] == SRK_STATUS_BUFFERING){
		// Display the buffer count
		NSInteger buffTimeBeforeStart = [radioKit bufferWaitTime] - [radioKit currBufferUsageInSeconds];
		if (buffTimeBeforeStart > 0){
			[bufferLabel performSelectorOnMainThread:@selector(setText:) 
										  withObject:[NSString stringWithFormat:@"Buffering: %ld", (long)buffTimeBeforeStart]
									   waitUntilDone:YES];
		}else{
			[bufferLabel performSelectorOnMainThread:@selector(setText:) 
										  withObject:@"" 
									   waitUntilDone:YES];
		}
	}else if (![bufferLabel.text isEqualToString:@""]){
		[bufferLabel performSelectorOnMainThread:@selector(setText:) 
									  withObject:@"" 
								   waitUntilDone:YES];
	}		
	
}

#pragma Last.fm API interface for fetching artwork based on song meta data

//#define ENABLE_LAST_FM_ALBUM_ARTWORK 1
#if ENABLE_LAST_FM_ALBUM_ARTWORK

- (Boolean) fetchXML: (NSString *)url
{
	self->lastFMImageUrl = nil;
	self->lastFMAlbumUrl = nil;
	self->lastFMArtistUrl = nil;
	
	NSURL *xmlUrl = [NSURL URLWithString: url];
	NSError *error;
	NSData *data = [NSData dataWithContentsOfURL:xmlUrl options:NSUncachedRead error:&error];
	if (data != nil){
		
		// Test code for using the filesystem rather than the network
		//NSString *rssPath = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] resourcePath], url];
		
		[self parseXMLFile:data];
		
		return TRUE;
	}else{
		NSLog(@"xml retrieval failed! Error - %@ %@",
				 [error localizedDescription],
				 [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
		return FALSE;
		
	}
	
	return FALSE;
}

// This sets up the XML parser.  The hard work is handled by the parser: protocol methods
- (void)parseXMLFile:(NSData *)data {
 	
	parserStartAlbum = NO;
	parserStartArtist = NO;
	
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    [parser setDelegate:self];
    [parser setShouldResolveExternalEntities:NO];
    [parser parse];
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
	
	//NSLog(@"element: %@", elementName);
	
	if ([elementName isEqualToString:@"album"]){
		parserStartAlbum = YES;
		return;
	}
	
	if ([elementName isEqualToString:@"artist"]){
		parserStartArtist = YES;
		return;
	}
    
	// currentStringValue is an instance variable
    currentStringValue = nil;
	
    // .... continued for remaining elements ....
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (!currentStringValue) {
        // currentStringValue is an NSMutableString instance variable
        currentStringValue = [[NSMutableString alloc] initWithCapacity:50];
    }
    [currentStringValue appendString:string];
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
	
	
	// Schedule Parsing
	
    if ([elementName isEqualToString:@"album"]){
		parserStartAlbum = NO;
	}
    
	if ([elementName isEqualToString:@"artist"]){
		parserStartArtist = NO;
	}
	
    if (parserStartAlbum && [elementName isEqualToString:@"image"] ){
		lastFMImageUrl = currentStringValue;
		//NSLog(@"imageURL = %@", lastFMImageUrl);
	}
  	
	if (parserStartAlbum && [elementName isEqualToString:@"url"] ){
		lastFMAlbumUrl = currentStringValue;
	}
    
	if (parserStartArtist && [elementName isEqualToString:@"url"] ){
		lastFMArtistUrl = currentStringValue;
	}
	
	// currentStringValue is an instance variable
    currentStringValue = nil;
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)error
{
	NSLog(@"Parser failed! Error - %@ %@",
			 [error localizedDescription],
			 [[error userInfo] objectForKey:NSXMLParserErrorDomain]);
}

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	//NSLog(@"parser done...");
}


#define LAST_FM_API_KEY @"ENTERYOURLASTFMAPIKEYHERE"

-(UIImage *) getLastFMArtwork
{
	NSString *lastFMtemplate = @"http://ws.audioscrobbler.com/2.0/?method=track.getinfo&api_key=%@&artist=%@&track=%@&autocorrect=1";
	
	//NSLog(@"hmmm... albumInfo is [%@]", albumInfo);
	
	NSRange range = [albumInfo rangeOfString:@" - "];
	if (range.location != NSNotFound){
		NSString *newArtist = [[[[albumInfo substringToIndex:range.location] stringByReplacingOccurrencesOfString:@"&" withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
		NSString *newSongName = [[[[albumInfo substringFromIndex:(range.location + range.length)] stringByReplacingOccurrencesOfString:@"&" withString:@"+"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"-" withString:@"+"];
		
		if (newArtist && newSongName){
			NSString *request = [NSString stringWithFormat:lastFMtemplate, LAST_FM_API_KEY, newArtist, newSongName];
			
			//NSLog(@"Looking for artwork: %@", request);
			
			if ([self fetchXML:request] && lastFMImageUrl){
				// load the lastFMImageUrl
				UIImage *img = nil;
				
                img = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:lastFMImageUrl]]];
				
				return img;
			}
		}
	}
	return nil;
}
#endif

#pragma mark Stormy Radio Kit (SRK) Protocol 

- (void)SRKConnecting
{
	//	[self.busyIcon performSelectorOnMainThread : @ selector(startAnimating ) withObject:nil waitUntilDone:NO /* was YES */];				
	[self performSelectorOnMainThread:@selector(updateAudioButtons) withObject:nil waitUntilDone:NO];
	[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Connecting..." waitUntilDone:NO];
	
}


- (void)SRKIsBuffering
{
	[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:@"Buffering..." waitUntilDone:NO];
	
}


- (void)SRKPlayStarted
{
    [radioKit enableLevelMetering];

	//	[self.busyIcon performSelectorOnMainThread : @ selector(stopAnimating ) withObject:nil waitUntilDone:NO /* was  YES*/];
	if (radioKit.currTitle != nil){
		[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:radioKit.currTitle waitUntilDone:NO];
	}else{
		[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:RADIO_CONNECTED_STR waitUntilDone:NO];
	}
	
	// In case we were paused, we want to update the buttons.
	[self performSelectorOnMainThread:@selector(updateAudioButtons) withObject:nil waitUntilDone:NO];
}


- (void)SRKPlayStopped
{
    NSLog(@"SRKPlayStopped");
	//	[self.busyIcon performSelectorOnMainThread : @ selector(stopAnimating ) withObject:nil waitUntilDone:NO /*YES*/];				
	[self performSelectorOnMainThread:@selector(updateAudioButtons) withObject:nil waitUntilDone:NO];
	[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:RADIO_STOPPED_STR waitUntilDone:NO];
}

- (void)SRKPlayPaused
{
	[self performSelectorOnMainThread:@selector(updateAudioButtons) withObject:nil waitUntilDone:NO];	
	[netStatusLabel performSelectorOnMainThread:@selector(setText:) withObject:RADIO_PAUSED_STR waitUntilDone:NO];
}


- (void)SRKNoNetworkFound
{
	// Don't display a no network warning unless we have no network for 2 seconds or more and have no more data in our buffer
	
	if (prevNoNetworkWarning == 0){
		prevNoNetworkWarning = time(NULL);
		return;
	}
	if (time(NULL) - prevNoNetworkWarning < 2.0f || [radioKit isAudioPlaying]){
		return;
	}
	
	[radioKit stopStream];
	[self performSelectorOnMainThread : @ selector(showNoNetworkAlert) withObject:nil waitUntilDone:YES];						
}

- (void)SRKChangeNowPlayingInfoCenter
{
    Class MPNowPlayingClass = (NSClassFromString(@"MPNowPlayingInfoCenter"));
    if (MPNowPlayingClass != nil) {
        /* we're on iOS 5 or later, so set up the now playing center */ 
        
        // TODO: replace the next line with actual album artwork lookup.
        //       There is no standard method for fetching album artwork.
        //       You will need to implement something yourself, or use
        //       a service like http://last.fm/api
        UIImage *albumArtImage = [UIImage imageNamed:@"RadioKitImage.png"];

#if ENABLE_LAST_FM_ALBUM_ARTWORK
        UIImage *img = [self getLastFMArtwork];
        
        if (img){
            albumArtImage = img;
            [albumArtwork setImage:img];
        }
#endif
        
        MPMediaItemArtwork *pmAlbumArt = [[MPMediaItemArtwork alloc] initWithImage:albumArtImage];
        
        NSDictionary *currentlyPlayingTrackInfo;
        
        NSString *msg = albumInfo;
        NSString *newArtist;
        NSString *newSongName;
        
        NSRange range = [msg rangeOfString:@" - "];
        if (range.location != NSNotFound){
            newArtist = [msg substringToIndex:range.location];
            newSongName = [msg substringFromIndex:(range.location + range.length)];
        }
        
        if (newArtist != nil){
            currentlyPlayingTrackInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:newArtist, newSongName, pmAlbumArt, nil] forKeys:[NSArray arrayWithObjects:MPMediaItemPropertyArtist, MPMediaItemPropertyTitle, MPMediaItemPropertyArtwork, nil]];
        }else{
            currentlyPlayingTrackInfo = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:msg, pmAlbumArt, nil] forKeys:[NSArray arrayWithObjects:MPMediaItemPropertyTitle, MPMediaItemPropertyArtwork, nil]];            
        }
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = currentlyPlayingTrackInfo;
    }
}

-(void)SRKURLNotFound
{
    NSLog(@"ERROR: bad URL!");
}

- (void)SRKMetaChanged
{  	        
    NSLog(@"SRKMetaChanged: [%@] withUrl: [%@]", radioKit.currTitle, radioKit.currUrl);

    if (radioKit.currTitle && [radioKit.currTitle length] > 2){
        [netStatusLabel performSelectorOnMainThread : @ selector(setText : ) withObject:radioKit.currTitle waitUntilDone:YES];						
    }
    
    if (radioKit.currUrl && [radioKit.currUrl length] > 2){	
        // TODO: Some stations use the URL metadata to provide a line to album artwork.
        //       IF this were the case with your station, you would want to implement 
        //       a method to fetch the artwork image based on the URL
        // [self performSelectorInBackground:@selector(loadAlbumArt:) withObject:radioKit.currUrl];	
    }	
    
    [self SaveAlbumInfo: radioKit.currTitle  URL: radioKit.currUrl];   // save this in case we need to reload the view in the future due to memory issues
    
    // Perform the routine to send the song info to the lock screen or to an airplay device
    [self performSelectorOnMainThread:@selector(SRKChangeNowPlayingInfoCenter) withObject:Nil waitUntilDone:NO];
}

- (void) SRKRealtimeMetaChanged: (NSString *)title withUrl: (NSString *) url
{
    NSLog(@"SRKRealtimeMetaChanged: [%@] withUrl: [%@]", title, url);
}

- (void) SRKAudioWillBeSuspended
{
	NSLog(@"WillBeSuspended");
}


- (void) SRKAudioSuspended
{
	NSLog(@"Suspended");
}

- (void) SRKAudioResumed
{
	NSLog(@"Resumed");
}


- (void) SRKFileComplete
{
	NSLog(@"*** Finished playing file ***");
}

@end
