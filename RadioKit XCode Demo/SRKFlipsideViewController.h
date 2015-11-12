//
//  SRKFlipsideViewController.h
//  RadioKit XCode 5 Demo
//
//  Created by Brian Stormont on 9/21/13.
//  Copyright (c) 2013 Stormy Productions. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SRKFlipsideViewController;

@protocol SRKFlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(SRKFlipsideViewController *)controller;
@end

@interface SRKFlipsideViewController : UIViewController

@property (weak, nonatomic) id <SRKFlipsideViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
