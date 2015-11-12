//
//  Visuallizer.m
//  RadioThing
//
//  Created by Brian Stormont on 3/2/10.
//  Copyright 2010 Stormy Productions. All rights reserved.
//

#import "Visuallizer.h"
#import "RadioKit.h"

@implementation Visuallizer
@synthesize radioKit;

- (void)dealloc {
	self.radioKit = nil;
}


- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // Initialization code
    }
    return self;
}


- (void)drawRect:(CGRect)rect {
    CGSize size = [self bounds].size;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, false);
	
	CGContextSetGrayFillColor(context, 1.0, 1.0);
    CGContextFillRect(context, CGRectMake(0, size.height, 5, -(size.height * plot[0])));
    CGContextFillRect(context, CGRectMake(6, size.height, 5, -(size.height * plot[1])));
    CGContextFillRect(context, CGRectMake(15, size.height, 5, -(size.height * plot[2])));
    CGContextFillRect(context, CGRectMake(21, size.height, 5, -(size.height * plot[3])));
	
    CGContextSetAllowsAntialiasing(context, true);
	
	//NSLog(@"drawRect: %lf %lf %lf %lf", plot[0], plot[1], plot[2], plot[3]);
}

- (void) updateData{		
	// Do some rudimentary audio visualization
	Float32 avgLevel[2], peakLevel[2];
	[radioKit getAudioLevels:avgLevel peakLevels:peakLevel];
	//NSLog(@"level-l: %lf %lf", avgLevel[0], peakLevel[0]);
	//NSLog(@"level-r: %lf %lf", avgLevel[1], peakLevel[1]);
	plot[0] = avgLevel[0];
	plot[1] = peakLevel[0];
	plot[2] = avgLevel[1];
	plot[3] = peakLevel[1];

	[self setNeedsDisplay];
}

@end
