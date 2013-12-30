//
// PieElement.m
// MagicPie
//
// Created by Alexandr on 03.11.13.
// Copyright (c) 2013 Alexandr Graschenkov ( https://github.com/Sk0rpion )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "PieElement.h"

NSString * const pieElementChangedNotificationIdentifier = @"PieElementChangedNotificationIdentifier";
NSString * const pieElementAnimateChangesNotificationIdentifier = @"PieElementAnimateChangesNotificationIdentifier";

static BOOL animateChanges;

@protocol PieLayerUpdateProtocol <NSObject>
- (void)pieElementUpdate;
- (void)pieElementWillAnimateUpdate;
@end

@interface PieElement()
{
    NSMutableArray* containsInLayers;
}
@property (nonatomic, assign) float titleAlpha;
@end

@implementation PieElement

+ (instancetype)pieElementWithValue:(float)val color:(UIColor *)color
{
    PieElement* result = [self new];
    result->_val = val;
    result->_color = color;
    return result;
}

- (id)copyWithZone:(NSZone *)zone
{
    PieElement *another = [[[self class] allocWithZone:zone] init];
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
    animateChanges = YES;
    changesBlock();
    animateChanges = NO;
}

- (NSArray*)animationValuesToPieElement:(PieElement*)anotherElement arrayCapacity:(NSUInteger)count
{
    if(count == 1) return @[anotherElement];
    
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        float v = i / (float)(count - 1);
        UIColor* newColor = [self colorBetweenColor1:self.color color2:anotherElement.color value:v];
        PieElement* newElem = [self copy];
        newElem.val_ = (anotherElement.val - self.val) * v + self.val;
        newElem.color_ = newColor;
        [newElem setCentrOffset_: (anotherElement.centrOffset - self.centrOffset) * v + self.centrOffset];
        newElem.titleAlpha = (anotherElement.titleAlpha - _titleAlpha) * v + _titleAlpha;
        newElem.showTitle = self.showTitle;
        [result addObject:newElem];
    }
    return result;
}

- (void)addedToPieLayer:(id<PieLayerUpdateProtocol>)pieLayer
{
    if(!containsInLayers)
        containsInLayers = [NSMutableArray new];
    NSValue* wraper = [NSValue valueWithNonretainedObject:pieLayer];
    [containsInLayers addObject:wraper];
}

- (void)removedFromLayer:(id<PieLayerUpdateProtocol>)pieLayer
{
    [containsInLayers removeObject:pieLayer];
}

- (void)notifyPerformForAnimation
{
    for(NSValue* notRetainedVal in containsInLayers)
        [notRetainedVal.nonretainedObjectValue pieElementWillAnimateUpdate];
}

- (void)notifyUpdated
{
    for(NSValue* notRetainedVal in containsInLayers)
        [notRetainedVal.nonretainedObjectValue pieElementUpdate];
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
    if(val == _val)
        return;
    
    if(animateChanges){
        [self notifyPerformForAnimation];
    }
    _val = val;
    if(!animateChanges){
        [self notifyUpdated];
    }
}
- (void)setVal_:(float)val
{
    _val = val;
}

- (void)setColor:(UIColor *)color
{
    if([color isEqual:_color])
        return;
    if(animateChanges){
        [self notifyPerformForAnimation];
    }
    _color = color;
    if(!animateChanges){
        [self notifyUpdated];
    }
}
- (void)setColor_:(UIColor *)color
{
    _color = color;
}

- (void)setCentrOffset:(float)centrOffset
{
    if(_centrOffset == centrOffset)
        return;
    
    if(animateChanges){
        [self notifyPerformForAnimation];
    }
    _centrOffset = centrOffset;
    if(!animateChanges){
        [self notifyUpdated];
    }
}
- (void)setCentrOffset_:(float)centrOffset
{
    _centrOffset = centrOffset;
}

- (void)setShowTitle:(BOOL)showTitle
{
    if(_showTitle == showTitle)
        return;
    
    if(animateChanges){
        [self notifyPerformForAnimation];
    }
    _showTitle = showTitle;
    if(!animateChanges){
        [self notifyUpdated];
    }
}

#pragma mark - Helpers
- (UIColor*)colorBetweenColor1:(UIColor*)color1 color2:(UIColor*)color2 value:(float)val
{
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

@end
