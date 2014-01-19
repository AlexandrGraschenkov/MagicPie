//
//  ViewController.m
//  MagicPie
//
//  Created by Alexander on 30.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "ViewController.h"
#import "Example1Controller.h"
#import "Example2Controller.h"
#import "Example3Controller.h"

@interface ViewController ()

@end

@implementation ViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)example1Pressed:(id)sender
{
    Example1Controller* exContr = [Example1Controller new];
    [self presentModalViewController:exContr animated:YES];
}

- (IBAction)example2Pressed:(id)sender
{
    Example2Controller* exContr = [Example2Controller new];
    [self presentModalViewController:exContr animated:YES];
}

- (IBAction)example3Pressed:(id)sender
{
    Example3Controller* exContr = [Example3Controller new];
    [self presentModalViewController:exContr animated:YES];
}

@end
