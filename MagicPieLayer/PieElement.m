//
//  PieEl.m
//  MagicPie
//
//  Created by Alexandr on 03.11.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "PieElement.h"

inline UIColor* colorBetween2Colors(UIColor* color1, UIColor* color2, float val){
    val = MIN(MAX(val, 0.0), 1.0);
    CGFloat red1 = 0.0, green1 = 0.0, blue1 = 0.0, alpha1 =0.0;
    [color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
    CGFloat red2 = 0.0, green2 = 0.0, blue2 = 0.0, alpha2 =0.0;
    [color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
    
    return [UIColor colorWithRed:(red2-red1)* val + red1
                           green:(green2-green1)*val + green1
                            blue:(blue2-blue1)*val + blue1
                           alpha:(alpha2-alpha1)*val + alpha1];
}

NSString * const pieElementChangedNotificationIdentifier = @"PieElementChangedNotificationIdentifier";

static BOOL animateChanges;
static NSMutableArray* elementsToAnimate;

@interface PieElement(){
    PieElement* beginAnimationState;
}
@property (nonatomic, assign) float titleAlpha;
@property (nonatomic, assign) int retainCount2;
@end

@implementation PieElement

+ (PieElement*)pieElementWithValue:(float)val color:(UIColor *)color
{
    PieElement* result = [PieElement new];
    result->_val = val;
    result->_color = color;
    return result;
}

-(id)copyWithZone:(NSZone *)zone
{
    PieElement *another = [[PieElement allocWithZone:zone] init];
    [another fillWithPieElement:self];
    
    return another;
}

- (void)fillWithPieElement:(PieElement*)elem
{
    _val = elem.val;
    _color = elem.color;
    _centrOffset = elem.centrOffset;
    _showTitle = elem.showTitle;
    _titleAlpha = elem.titleAlpha;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"[%@: %f]", NSStringFromClass(self.class), self.val];
}

+ (void)animateChanges:(void (^)())changesBlock
{
    elementsToAnimate = [NSMutableArray new];
    animateChanges = YES;
    changesBlock();
    animateChanges = NO;
    for(PieElement* elem in elementsToAnimate){
        [elem commitChanges];
    }
    elementsToAnimate = nil;
}

- (NSArray*)animationValuesToPieElement:(PieElement*)anotherElement arrayCapacity:(NSUInteger)count
{
    if(count == 1) return @[anotherElement];
    
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        float v = i / (float)(count - 1);
        PieElement* newElem = [PieElement pieElementWithValue:(anotherElement.val - self.val) * v + self.val
                                                        color:colorBetween2Colors(self.color, anotherElement.color, v)];
        [newElem setCentrOffset_: (anotherElement.centrOffset - self.centrOffset) * v + self.centrOffset];
        newElem.titleAlpha = (anotherElement.titleAlpha - _titleAlpha) * v + _titleAlpha;
        newElem.showTitle = self.showTitle;
        [result addObject:newElem];
    }
    return result;
}

- (void)commitChanges
{
    if(_retainCount2 <= 0)
        return;
    
    NSDictionary* userInfo = nil;
    if(beginAnimationState){
        userInfo = @{@"begunState" : beginAnimationState};
        beginAnimationState = nil;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:pieElementChangedNotificationIdentifier object:self userInfo:userInfo];
}



#pragma mark - Setters
- (void)setVal:(float)val
{
    if(val < 0){
#ifdef DEBUG
        NSLog(@"[%@ %@]- Negative values not allowed: val=%f => 0.0", NSStringFromClass(self.class), NSStringFromSelector(_cmd), val);
#endif
        val = 0.0;
    }
    _val = val;
    if(animateChanges){
        if(![elementsToAnimate containsObject:self])
            [elementsToAnimate addObject:self];
    } else {
        [self commitChanges];
    }
}
- (void)setVal_:(float)val
{
    _val = val;
}

- (void)setColor:(UIColor *)color
{
    _color = color;
    if(animateChanges){
        if(![elementsToAnimate containsObject:self])
            [elementsToAnimate addObject:self];
    } else {
        [self commitChanges];
    }
}
- (void)setColor_:(UIColor *)color
{
    _color = color;
}

- (void)setCentrOffset:(float)centrOffset
{
    _centrOffset = centrOffset;
    if(animateChanges){
        if(![elementsToAnimate containsObject:self])
            [elementsToAnimate addObject:self];
    } else {
        [self commitChanges];
    }
}
- (void)setCentrOffset_:(float)centrOffset
{
    _centrOffset = centrOffset;
}

- (void)setShowTitle:(BOOL)showTitle
{
    _showTitle = showTitle;
    if(animateChanges){
        if(![elementsToAnimate containsObject:self])
            [elementsToAnimate addObject:self];
    } else {
        [self commitChanges];
    }
}

@end