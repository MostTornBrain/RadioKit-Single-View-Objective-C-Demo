//
//  Visuallizer.h
//  RadioThing
//
//  Created by Brian Stormont on 3/2/10.
//  Copyright 2010 Stormy Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RadioKit;

#define VISUAL_RESOLUTION 4

@interface Visuallizer : UIView {
	RadioKit *radioKit;
	
	Float32 plot[VISUAL_RESOLUTION];
	int currPlotPt;
    
}
@property(nonatomic,retain) RadioKit *radioKit;

- (void) updateData;

@end
