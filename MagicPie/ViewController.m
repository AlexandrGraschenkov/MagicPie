//
//  ViewController.m
//  MagicPie
//
//  Created by Alexandr on 30.09.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "ViewController.h"
#import "MagicPieLayer.h"
#import "TestPieLayer.h"
#import "ExamplePieView.h"

//#define LOG_ACTION

static UIColor* randomColor(){
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    return [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
}

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)addPressed:(id)sender
{
    MagicPieElement* newElem = [MagicPieElement pieElementWithValue:(5 + arc4random() % 10) color:randomColor()];
//    newElem.showTitle = YES;
    int insertIndex = self.pieView.layer.values.count;//arc4random() % (pieLayer.values.count + 1);
    [self.pieView.layer insertValues:@[newElem] atIndexes:@[@(insertIndex)] animated:YES];
#ifdef LOG_ACTION
    NSLog(@"Insert values %@ to indixes %@", [self arrDesc:@[newElem]], [self arrDesc:@[@(insertIndex)]]);
#endif
}

- (IBAction)deletePressed:(id)sender
{
    if(self.pieView.layer.values.count <= 0)
        return;
    
    int deleteIndex = arc4random() % self.pieView.layer.values.count;
    [self.pieView.layer deleteValues:@[self.pieView.layer.values[deleteIndex]] animated:YES];
#ifdef LOG_ACTION
    NSLog(@"Delete values at indixes %@", [self arrDesc:@[@(deleteIndex)]]);
#endif
}

- (IBAction)animateChangeVal:(id)sender
{
    int randIndx = arc4random() % self.pieView.layer.values.count;
    [self.pieView.layer.values[randIndx] setVal:(5 + arc4random() % 10)];
#ifdef LOG_ACTION
    NSLog(@"Change values at indixes %@", [self arrDesc:@[@(randIndx)]]);
#endif
}

- (IBAction)animateStartEnd
{
    float startAngle = arc4random() % 360;
    float endAngle = arc4random() % 300 + 60 + startAngle;
    [self.pieView.layer setStartAngle:startAngle endAngle:endAngle animated:YES];
}

- (NSString*)arrDesc:(NSArray*)arr
{
    NSString* str = arr.description;
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return str;
}


@end
