//
//  PieLayer.h
//  infoAnalytucalPortal
//
//  Created by Alexandr on 09.07.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface MagicPieElement : NSObject

+ (MagicPieElement*)pieElementWithValue:(float)val color:(UIColor*)color;
@property (nonatomic, assign) float val;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, assign) float centrOffset;
@property (nonatomic, assign) BOOL animateChanges;//default YES
@property (nonatomic, assign) BOOL showTitle;//default NO

@end


typedef enum ShowTitles
{
    ShowTitlesNever = 0,
    ShowTitlesIfEnable = 1,
    ShowTitlesAlways = 2
}ShowTitle;

@interface MagicPieLayer : CALayer

@property (nonatomic, strong, readonly) NSArray* values;
- (void)addValues:(NSArray*)addingNewValues animated:(BOOL)animated;
- (void)deleteValues:(NSArray*)valuesToDelete animated:(BOOL)animated;
- (void)insertValues:(NSArray *)array atIndexes:(NSArray*)indexes animated:(BOOL)animated;

@property (nonatomic, assign) float maxRadius;//default 100
@property (nonatomic, assign) float minRadius;//default 0
@property (nonatomic, assign) float startAngle;//default 0
@property (nonatomic, assign) float endAngle;//default 360
@property (nonatomic, assign) float animationDuration;//default 0.6
@property (nonatomic, assign) ShowTitle showTitles;//defaul ShowTitleNever

@property (nonatomic, assign) NSString*(^transformValueBlock)(MagicPieElement* val);//default x => [NSSring stringWithFormat:@"%.2f", x.val]

- (void)setMaxRadius:(float)maxRadius minRadius:(float)minRadius animated:(BOOL)isAnimated;
- (void)setStartAngle:(float)startAngle endAngle:(float)endAngle animated:(BOOL)isAnimated;

- (MagicPieElement*)pieElemInPoint:(CGPoint)point;

@end
