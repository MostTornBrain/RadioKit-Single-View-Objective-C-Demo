//
//  SRKFlipsideViewController.m
//  RadioKit XCode 5 Demo
//
//  Created by Brian Stormont on 9/21/13.
//  Copyright (c) 2013 Stormy Productions. All rights reserved.
//

#import "SRKFlipsideViewController.h"

@interface SRKFlipsideViewController ()

@end

@implementation SRKFlipsideViewController

@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
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

#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

@end
