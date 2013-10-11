//
//  ViewController.h
//  MagicPie
//
//  Created by Alexandr on 30.09.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExamplePieView;
@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet ExamplePieView* pieView;

- (IBAction)addPressed:(id)sender;
- (IBAction)deletePressed:(id)sender;
- (IBAction)animateChangeVal:(id)sender;
- (IBAction)animateStartEnd;

@end
