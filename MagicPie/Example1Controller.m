//
//  ViewController.m
//  MagicPie
//
//  Created by Alexandr on 30.09.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "Example1Controller.h"
#import "MagicPieLayer.h"
#import "TestPieLayer.h"
#import "Example1PieView.h"
#import "NSMutableArray+pieEx.h"

#define LOG_ACTION

@interface Example1Controller()
@property (nonatomic, weak) IBOutlet Example1PieView* pieView;
@end

@implementation Example1Controller
@synthesize pieView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    pieView.elemTapped = ^(PieElement* elem){
        [PieElement animateChanges:^{
            elem.color = [self randomColor];
        }];
    };
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

- (IBAction)addPressed:(id)sender
{
    PieElement* newElem = [PieElement pieElementWithValue:(5 + arc4random() % 10) color:[self randomColor]];
//    newElem.showTitle = YES;
    int insertIndex = arc4random() % (self.pieView.layer.values.count + 1);
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
    if(self.pieView.layer.values.count == 0)return;
    NSUInteger randCount = MAX(MIN(self.pieView.layer.values.count, 2), arc4random() % self.pieView.layer.values.count);
    NSMutableArray* randIndexes = [NSMutableArray new];
    NSMutableArray* changeValArr = [NSMutableArray new];
    [PieElement animateChanges:^{
        for(int i = 0; i < randCount; i++){
            int randIndx = arc4random() % self.pieView.layer.values.count;
            while ([randIndexes containsObject:@(randIndx)]) {
                randIndx = arc4random() % self.pieView.layer.values.count;
            }
            [randIndexes addObject:@(randIndx)];
            int randVal = (5 + arc4random() % 10);
            int prevVal = [(PieElement*)self.pieView.layer.values[randIndx] val];
            [self.pieView.layer.values[randIndx] setVal:randVal];
            [changeValArr addObject:[NSString stringWithFormat:@"%d -> %d", prevVal, randVal]];
        }
    }];
#ifdef LOG_ACTION
    NSMutableString* logStr = [[NSMutableString alloc] initWithString:@"Update elements:\n"];
    for(int i = 0; i < randIndexes.count; i++){
        [logStr appendFormat:@"%@ element: %@\n", randIndexes[i], changeValArr[i]];
    }
    NSLog(@"%@", logStr);
#endif
}

- (IBAction)refreshData:(id)sender
{
    [self.pieView.layer setNeedsDisplay];
}

- (IBAction)performRandomActions:(id)sender
{
    while (arc4random() % 100 < 90) {
        switch (arc4random() % 3) {
            case 0:
                [self addPressed:nil];
                break;
            case 1:
                [self deletePressed:nil];
                break;
            case 2:
                [self animateChangeVal:nil];
                break;
                
                
            default:
                break;
        }
    }
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
