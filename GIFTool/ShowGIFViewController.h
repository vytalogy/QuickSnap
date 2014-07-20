//
//  ShowGIFViewController.h
//  GIFTool
//
//  Created by Haris on 6/26/14.
//  Copyright (c) 2014 HarisHussain. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OLImageView;

@interface ShowGIFViewController : UIViewController

@property (nonatomic, retain) NSString *imagePath;

@property (strong, nonatomic) IBOutlet OLImageView *imageView;

- (IBAction)share:(id)sender;

@end