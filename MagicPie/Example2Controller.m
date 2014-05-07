//
//  Example2Controller.m
//  MagicPie
//
//  Created by Alexander on 30.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "Example2Controller.h"
#import "Example2PieView.h"
#import "MyPieElement.h"
#import "PieLayer.h"

@interface Example2Controller ()
{
    BOOL showPercent;
}
@property (nonatomic, weak) IBOutlet Example2PieView* pieView;

@end

@implementation Example2Controller
@synthesize pieView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    for(int year = 2009; year <= 2014; year++){
        MyPieElement* elem = [MyPieElement pieElementWithValue:(5+arc4random()%8) color:[self randomColor]];
        elem.title = [NSString stringWithFormat:@"%d year", year];
        [pieView.layer addValues:@[elem] animated:NO];
    }
    
    //mutch easier do this with array outside
    showPercent = NO;
    pieView.layer.transformTitleBlock = ^(PieElement* elem, float percent){
        return [(MyPieElement*)elem title];
    };
    pieView.layer.showTitles = ShowTitlesAlways;
}

- (IBAction)changePercentValuesPressed:(id)sender
{
    showPercent = !showPercent;
    if(showPercent){
        pieView.layer.transformTitleBlock = ^(PieElement* elem, float percent){
            return [NSString stringWithFormat:@"%ld%%", (long)percent];
        };
    } else {
        pieView.layer.transformTitleBlock = ^(PieElement* elem, float percent){
            return [(MyPieElement*)elem title];
        };
    }
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

- (IBAction)randomValuesPressed:(id)sender
{
    [PieElement animateChanges:^{
        for(PieElement* elem in pieView.layer.values){
            elem.val = (5+arc4random()%8);
        }
    }];
}

- (IBAction)randomColorPressed:(id)sender
{
    [PieElement animateChanges:^{
        for(PieElement* elem in pieView.layer.values){
            elem.color = [self randomColor];
        }
    }];
}
@end
