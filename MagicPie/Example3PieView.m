//
//  Example3PieView.m
//  MagicPie
//
//  Created by Alexander on 18.01.14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import "Example3PieView.h"
#import "MagicPieLayer.h"
#import "MetrtTable.h"
#import "Example3PieLayer.h"
@import AVFoundation;

@interface Example3PieView ()
{
    CADisplayLink* displayLink;
    NSTimer* chageColorTimer;
    PieElement* pieElem;
    MeterTable* meterTable;
}
@property(nonatomic,readonly,retain) Example3PieLayer *layer;
@end

@implementation Example3PieView

+ (Class)layerClass
{
    return [Example3PieLayer class];
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

- (UIColor*)randomColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

- (void)setup
{
    self.layer.maxRadius = 40;
    self.layer.minRadius = 40;
    self.layer.animationDuration = 1.0;
    self.layer.colorsArr = @[[UIColor colorWithRed:0.472 green:0.652 blue:1.000 alpha:1.000],
                             [UIColor colorWithRed:0.529 green:0.392 blue:1.000 alpha:1.000],
                             [UIColor colorWithRed:0.710 green:0.214 blue:0.814 alpha:1.000],
                             [UIColor colorWithRed:0.896 green:0.256 blue:0.556 alpha:1.000],
                             [UIColor colorWithRed:0.798 green:0.000 blue:0.000 alpha:1.000]];
    pieElem = [PieElement pieElementWithValue:1 color:[self randomColor]];
    [self.layer addValues:@[pieElem] animated:NO];
    
    meterTable = [MeterTable new];
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    chageColorTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                       target:self
                                                     selector:@selector(updateColorAnimated:)
                                                     userInfo:nil
                                                      repeats:YES];
}

- (void)setEnableCustomDrawing:(BOOL)enableCustomDrawing
{
    self.layer.enableCustomDrawing = enableCustomDrawing;
}

- (BOOL)enableCustomDrawing
{
    return self.layer.enableCustomDrawing;
}

// helpfull tutorial http://www.raywenderlich.com/36475/how-to-make-a-music-visualizer-in-ios
- (void)update
{
    if(_player.playing){
        [_player updateMeters];
        
        float power = 0.0f;
        for (int i = 0; i < _player.numberOfChannels; i++) {
            power += [_player averagePowerForChannel:i];
        }
        power /= [_player numberOfChannels];
        
        float level = [meterTable valueAt:power];
        self.layer.maxRadius = self.layer.minRadius + 120*level;
    }
}

- (void)updateColorAnimated:(NSTimer*)timer
{
    [PieElement animateChanges:^{
        pieElem.color = [self randomColor];
    }];
}

- (void)dealloc
{
    [displayLink invalidate];
    [chageColorTimer invalidate];
}

@end
