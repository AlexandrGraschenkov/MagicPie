//
//  Example2Controller.m
//  MagicPie
//
//  Created by Alexander on 30.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "Example4Controller.h"
#import "Example4PieView.h"
#import "MyPieElemntExample4.h"
#import "PieLayer.h"

@interface Example4Controller ()
{
    BOOL showPercent;
}
@property (nonatomic, weak) IBOutlet Example4PieView* pieView;
@property (weak, nonatomic) IBOutlet UILabel *indexPressed;

@end

@implementation Example4Controller
@synthesize pieView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // the values to be drawn in pie chart
    float vals[] = {505.0,505.0,0.0,70.0,0.0};
    
    for(int i = 0 ;  i<5 ; i++ ){
        float val = vals[i];
        MyPieElemntExample4* elem = [MyPieElemntExample4 pieElementWithValue:val indexValue:(NSInteger*)i color:[self randomColor]];
        elem.title = [NSString stringWithFormat:@"index %d", i];
        [pieView.layer addValues:@[elem] animated:NO];
    }
    
    //much easier do this with array outside
    showPercent = NO;
    pieView.layer.transformTitleBlock = ^(PieElement* elem, float percent){
        return [(MyPieElemntExample4*)elem title];
    };
    pieView.layer.showTitles = ShowTitlesAlways;
}

- (UIColor*)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}


- (IBAction)backPressed:(id)sender
{
    [self dismissModalViewControllerAnimated:YES];
}



@end