//
//  Example2PieView.m
//  MagicPie
//
//  Created by Alexander on 30.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "Example2PieView.h"
#import "MagicPieLayer.h"

@interface Example2PieView () {
    NSInteger selectedIdx;
}
@end

@implementation Example2PieView

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
    self.layer.maxRadius = 100;
    self.layer.minRadius = 20;
    self.layer.animationDuration = 0.6;
    self.layer.startAngle = 360;
    self.layer.endAngle = 0;
    self.layer.showTitles = ShowTitlesIfEnable;
    if ([self.layer.self respondsToSelector:@selector(setContentsScale:)])
    {
        self.layer.contentsScale = [[UIScreen mainScreen] scale];
    }
    
    
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap];
}

- (void)setCenterDisplace:(BOOL)centerDisplace {
    _centerDisplace = centerDisplace;
    
    [self animateChanges];
}

- (void)handleTap:(UITapGestureRecognizer*)tap
{
    if(tap.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint pos = [tap locationInView:tap.view];
    PieElement* tappedElem = [self.layer pieElemInPoint:pos];
    if(!tappedElem)
        return;
    NSInteger newIdx = [self.layer.values indexOfObject:tappedElem];
    if (newIdx == selectedIdx) {
        selectedIdx = NSNotFound;
    } else {
        selectedIdx = newIdx;
    }
    
    [self animateChanges];
}

- (void)animateChanges
{
    [PieElement animateChanges:^{
        NSInteger i = 0;
        for(PieElement* elem in self.layer.values){
            elem.centrOffset = (i==selectedIdx && _centerDisplace) ? 20 : 0;
            elem.maxRadius = (i==selectedIdx && !_centerDisplace) ? @(120) : nil;
            i++;
        }
    }];
}

@end