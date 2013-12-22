//
//  ExamplePieView.m
//  MagicPie
//
//  Created by Alexandr on 10.10.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "ExamplePieView.h"
#import "MagicPieLayer.h"

@interface ExamplePieView ()
{
    CGPoint panNormalizedVector;
    PieElement* panPieElem;
    float panStartCenterOffsetElem;
    float panStartDotProduct;
}
@end

@implementation ExamplePieView

+ (Class)layerClass
{
    return [PieLayer class];
}

- (id)init
{
    self = [super init];
    if(self){
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self){
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self){
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.layer.maxRadius = 120;
    self.layer.minRadius = 30;
    self.layer.animationDuration = 0.6;
    self.layer.showTitles = ShowTitlesIfEnable;
    if ([self.layer.self respondsToSelector:@selector(setContentsScale:)])
    {
        self.layer.contentsScale = [[UIScreen mainScreen] scale];
    }

    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap];
    
    UIPanGestureRecognizer* pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    pan.maximumNumberOfTouches = 1;
    [self addGestureRecognizer:pan];
}

- (UIColor*)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (void)handleTap:(UITapGestureRecognizer*)tap
{
    if(tap.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint pos = [tap locationInView:tap.view];
    PieElement* elem = [self.layer pieElemInPoint:pos];
    elem.color = [self randomColor];
}

- (void)handlePan:(UIPanGestureRecognizer*)pan
{
    CGPoint pos = [pan locationInView:pan.view];
    CGPoint center = CGPointMake(pan.view.frame.size.width / 2, pan.view.frame.size.height / 2);
    if(pan.state == UIGestureRecognizerStateBegan){
        panPieElem = [self.layer pieElemInPoint:pos];
        panStartCenterOffsetElem = panPieElem.centrOffset;
        panPieElem.animateChanges = NO;
        
        CGPoint vec = CGPointMake(pos.x - center.x, pos.y - center.y);
        float distance = sqrtf(pow(vec.x, 2.0) + pow(vec.y, 2.0));
        panNormalizedVector = CGPointMake(vec.x / distance, vec.y / distance);
        panStartDotProduct = distance;
    } else if(pan.state == UIGestureRecognizerStateChanged){
        CGPoint currPoint = CGPointMake(pos.x - center.x, pos.y - center.y);
        float dotProduct = currPoint.x * panNormalizedVector.x + currPoint.y * panNormalizedVector.y;
        panPieElem.centrOffset = MAX(0.0, dotProduct - panStartDotProduct + panStartCenterOffsetElem);
    } else if(pan.state == UIGestureRecognizerStateEnded){
        panPieElem.animateChanges = YES;
        panPieElem = nil;
    }
}
@end
