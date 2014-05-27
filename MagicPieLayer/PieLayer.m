//
// PieLayer.m
// MagicPie
//
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

#import "PieLayer.h"
#import "PieElement.h"
#import "NSMutableArray+pieEx.h"
#define ANIM_KEY_PER_SECOND 36

//in [0..1], out [0..1]
static inline float easeInOut(float x){
    //1/(1+e^((0.5-x)*12))
    return 1/(1+powf(M_E, (0.5-x)*12));
}

extern NSString * const pieElementChangedNotificationIdentifier;
extern NSString * const pieElementAnimateChangesNotificationIdentifier;

@interface PieElement(hidden)
@property (nonatomic, assign) float titleAlpha;
- (void)addedToPieLayer:(id)pieLayer;
- (void)removedFromLayer:(id)pieLayer;
- (void)setVal_:(float)val;
- (void)setColor_:(UIColor *)color;
- (void)setCentrOffset_:(float)centrOffset;
- (NSArray*)animationValuesToPieElement:(PieElement*)anotherElement arrayCapacity:(NSUInteger)count;
@end

static NSString * const _animationValuesKey = @"animationValues";

#pragma mark - PieLayer
@interface PieLayer ()
{
    BOOL _isNotCopyForAnimation;
}
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong, readwrite) NSArray* values;
// present while performing animations
@property (nonatomic, strong) NSArray* presentValues;

@property (nonatomic, strong) NSMutableArray* deletingIndexes;
@property (nonatomic, assign) BOOL isFakeAngleAnimation;
@property (nonatomic, strong) NSMutableArray* animationBeginState; //perform animation
@property (nonatomic, strong) NSMutableArray* animationEndState;
@property (nonatomic, strong) NSMutableArray* animationDeletingIndexes;
@end

@implementation PieLayer
@dynamic values, presentValues, deletingIndexes, maxRadius, minRadius, font, transformTitleBlock, startAngle, endAngle, isFakeAngleAnimation, showTitles;
@synthesize animationDuration, animationBeginState, animationEndState, animationDeletingIndexes;

#pragma mark - Init
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

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if(self) {
        self.presentValues = nil;
    }
    return self;
}

- (void)setup
{
    _isNotCopyForAnimation = YES;
    self.maxRadius = 100;
    self.minRadius = 0;
    self.startAngle = 0.0;
    self.endAngle = 360.0;
    self.animationDuration = 0.6;
    self.showTitles = ShowTitlesNever;
    self.font = [UIFont systemFontOfSize:15];
    if ([self respondsToSelector:@selector(setContentsScale:)]){
        self.contentsScale = [[UIScreen mainScreen] scale];
    }
}

#pragma mark - Adding, inserting and deleting
- (void)addValues:(NSArray *)addingNewValues animated:(BOOL)animated
{
    NSInteger count = addingNewValues.count;
    NSInteger currCount = self.values.count;
    NSMutableArray* indexes = [NSMutableArray arrayWithCapacity:addingNewValues.count];
    for(NSInteger i = 0; i < count; i++){
        [indexes addObject:@(i+currCount)];
    }
    [self insertValues:addingNewValues atIndexes:indexes animated:animated];
}

- (BOOL)performDelayedAnimation
{
    if(self.animationBeginState && self.animationEndState)
        return YES;
    BOOL const isAnimating = [self animationForKey:_animationValuesKey] != nil;
    NSArray* currentValues = isAnimating? [self.presentationLayer values] : self.values;
    
    NSArray* deletingIndexes = isAnimating? [self.presentationLayer deletingIndexes] : nil;
    BOOL isCountMatch = deletingIndexes.count + self.values.count == currentValues.count;
    if(!isCountMatch){
        return NO;
    }
    animationDeletingIndexes = [NSMutableArray arrayWithArray:deletingIndexes];
    [animationDeletingIndexes sortUsingSelector:@selector(compare:)];
    animationBeginState = [[NSMutableArray alloc] initWithArray:currentValues copyItems:YES];
    animationEndState = [NSMutableArray arrayWithArray:self.values];
    for(NSNumber* delIdxNum in animationDeletingIndexes){
        NSInteger delIdx = delIdxNum.integerValue;
        PieElement* elem = [currentValues[delIdx] copy];
        [elem setVal_:0.0];
        elem.titleAlpha = 0.0;
        [animationEndState insertObject:elem atIndex:delIdx];
    }
    
    [self performSelector:@selector(delayedAnimateChanges) withObject:nil afterDelay:0.0];
    return YES;
}

- (void)insertValues:(NSArray *)array atIndexes:(NSArray *)indexes animated:(BOOL)animated
{
    NSAssert2(array.count == indexes.count, @"Array sizes must be equal: values.count = %d; indexes.count = %d;", (int)array.count, (int)indexes.count);
    for(PieElement* elem in array){
        [elem addedToPieLayer:self];
    }
    
    NSMutableArray* sortedArray = [array mutableCopy];
    [sortedArray sortWithIndexes:indexes];
    NSMutableArray* sortedIndexes = [indexes mutableCopy];
    [sortedIndexes sortUsingSelector:@selector(compare:)];
    
    NSMutableArray* newValues = [NSMutableArray arrayWithArray:self.values];
    [newValues insertSortedObjects:sortedArray indexes:sortedIndexes];
    
    if(!animated || ![self performDelayedAnimation]){
        for(PieElement* elem in array){
            elem.titleAlpha = 1.0;
        }
        [self removeAnimationForKey:_animationValuesKey];
        self.values = [NSArray arrayWithArray:newValues];
        return;
    }
    if(!self.presentValues) {
        self.presentValues = [[NSArray alloc] initWithArray:animationBeginState copyItems:YES];
    }
    self.values = [NSArray arrayWithArray:newValues];
    
    [sortedIndexes updateIndexesWithUnusedIndexes:animationDeletingIndexes];
    NSMutableArray* copyInsertArr = [[NSMutableArray alloc] initWithArray:sortedArray copyItems:YES];
    for(PieElement* elem in copyInsertArr){
        [elem setVal_:0.0];
        elem.titleAlpha = 0.0;
    }
    [animationBeginState insertSortedObjects:copyInsertArr indexes:sortedIndexes];
    [animationEndState insertSortedObjects:sortedArray indexes:sortedIndexes];
    [animationDeletingIndexes updateIndexesWithUnusedIndexes:sortedIndexes];
}

- (void)deleteValues:(NSArray *)valuesToDelete animated:(BOOL)animated
{
    for(PieElement* elem in valuesToDelete){
        [elem removedFromLayer:self];
    }
    
    NSMutableArray* newValues = [NSMutableArray arrayWithArray:self.values];
    [newValues removeObjectsInArray:valuesToDelete];
    
    if(!animated || ![self performDelayedAnimation]){
        [self removeAnimationForKey:_animationValuesKey];
        self.values = [NSArray arrayWithArray:newValues];
        return;
    }
    if(!self.presentValues) {
        self.presentValues = [[NSArray alloc] initWithArray:animationBeginState copyItems:YES];
    }
    self.values = [NSArray arrayWithArray:newValues];
    
    for(int i = 0; i < animationEndState.count; i++){
        PieElement* elem = animationEndState[i];
        if([valuesToDelete containsObject:elem]){
            PieElement* copyElem = [elem copy];
            [animationDeletingIndexes addObject:@(i)];
            [copyElem setVal_:0.0];
            copyElem.titleAlpha = 0.0;
            animationEndState[i] = copyElem;
        }
    }
    [animationDeletingIndexes sortUsingSelector:@selector(compare:)];
}

- (void)pieElementUpdate
{
    [self setNeedsDisplay];
}

- (void)pieElementWillAnimateUpdate
{
    if(![self performDelayedAnimation])
        [self setNeedsDisplay];
}

- (void)delayedAnimateChanges
{
    BOOL const isAnimating = [self animationForKey:_animationValuesKey] != nil;
    NSString* timingFunction = isAnimating? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseInEaseOut;
    [self animateFromValues:animationBeginState toValues:animationEndState timingFunction:timingFunction];
    self.deletingIndexes = animationDeletingIndexes;
    animationBeginState = nil;
    animationEndState = nil;
    animationDeletingIndexes = nil;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setPresentValues:) object:nil];
    [self performSelector:@selector(setPresentValues:) withObject:nil afterDelay:0];
}

#pragma mark - Animate setters

- (void)animateFromValues:(NSArray*)fromValues toValues:(NSArray*)toValues timingFunction:(NSString*)timingFunction
{
    NSAssert2(fromValues.count == toValues.count, @"Array sizes must be equal: fromValues.count = %d; toValues.count = %d;", (int)fromValues.count, (int)toValues.count);
    float fromSum = [[fromValues valueForKeyPath:@"@sum.val"] floatValue];
    float toSum = [[toValues valueForKeyPath:@"@sum.val"] floatValue];
    if(fromSum <= 0 || toSum <= 0){
        [self animateStartAngleEndAngleFillUp:(fromSum==0) values:fromValues timingFunction:timingFunction];
        return;
    }
    
    if(self.isFakeAngleAnimation){
        [self animateFromStartAngle:[self.presentationLayer startAngle]
                       toStartAngle:self.startAngle
                       fromEndAngle:[self.presentationLayer endAngle]
                         toEndAngle:self.endAngle];
        self.isFakeAngleAnimation = NO;
    }
    
    int keysCount = (int)(animationDuration*ANIM_KEY_PER_SECOND);
    
    NSMutableArray* animationKeys = [NSMutableArray new];
    for(int i = 0; i < keysCount; i++){
        [animationKeys addObject:[NSMutableArray new]];
    }
    for(int valNum = 0; valNum < fromValues.count; valNum++){
        NSArray* changeValueAnimation = [fromValues[valNum] animationValuesToPieElement:toValues[valNum] arrayCapacity:keysCount];

        for(int keyNum = 0; keyNum < keysCount; keyNum++){
            [animationKeys[keyNum] addObject:changeValueAnimation[keyNum]];
        }
    }
    
    CAKeyframeAnimation* valuesAnim = [CAKeyframeAnimation animationWithKeyPath:@"values"];
    valuesAnim.values = animationKeys;
    valuesAnim.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    valuesAnim.duration = animationDuration;
    valuesAnim.repeatCount = 1;
    valuesAnim.fillMode = kCAFillModeRemoved;
    valuesAnim.delegate = self;
    [self addAnimation:valuesAnim forKey:_animationValuesKey];
}

- (void)animateStartAngleEndAngleFillUp:(BOOL)fillUp values:(NSArray*)values timingFunction:(NSString*)timingFunction
{
    //make illusion deleting/inserting values
    //simple run animation change start and end angle
    BOOL const isAnimating = [self animationForKey:@"animationStartEndAngle"] != nil;
    if(fillUp){
        [self animateFromStartAngle:(isAnimating?[self.presentationLayer startAngle] : self.startAngle)
                       toStartAngle:self.startAngle
                       fromEndAngle:(isAnimating?[self.presentationLayer endAngle] : self.startAngle)
                         toEndAngle:self.endAngle];
        self.isFakeAngleAnimation = YES;
    } else {
        [self animateFromStartAngle:isAnimating?[self.presentationLayer startAngle] : self.startAngle
                       toStartAngle:self.startAngle
                       fromEndAngle:isAnimating?[self.presentationLayer endAngle] : self.endAngle
                         toEndAngle:self.startAngle];
        self.isFakeAngleAnimation = YES;
        
        //we don't have values in self.values, so make animation with 2 key for save values when animating
        CAKeyframeAnimation* valuesAnim = [CAKeyframeAnimation animationWithKeyPath:@"values"];
        valuesAnim.values = @[values, values];
        valuesAnim.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
        valuesAnim.duration = animationDuration;
        valuesAnim.repeatCount = 1;
        valuesAnim.fillMode = kCAFillModeRemoved;
        valuesAnim.delegate = self;
        
        NSMutableArray* deletingIndexes = [NSMutableArray array];
        for(int i = 0; i < values.count; i++)
            [deletingIndexes addObject:@(i)];
        self.deletingIndexes = deletingIndexes;
        [self removeAnimationForKey:_animationValuesKey];
        [self addAnimation:valuesAnim forKey:_animationValuesKey];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished
{
    if(!finished)
        return;
    
    BOOL isValuesAnimation = [anim isKindOfClass:[CAPropertyAnimation class]] &&
                             [((CAPropertyAnimation*)anim).keyPath isEqualToString:@"values"];
    if(isValuesAnimation){
        self.deletingIndexes = nil;
    } else {//angle animation
        self.isFakeAngleAnimation = NO;
    }
}

- (void)setMaxRadius:(float)maxRadius minRadius:(float)minRadius animated:(BOOL)isAnimated
{
    if(!isAnimated){
        self.maxRadius = maxRadius;
        self.minRadius = minRadius;
        return;
    }
    
    CAAnimationGroup* runingAnimation = (CAAnimationGroup*)[self animationForKey:@"animationMaxMinRadius"];
    if(runingAnimation){
        [self removeAnimationForKey:@"animationMaxMinRadius"];
        self.maxRadius = [self.presentationLayer maxRadius];
        self.minRadius = [self.presentationLayer minRadius];
    }
    
    NSString* timingFunction = runingAnimation? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseInEaseOut;
    
    CABasicAnimation* animMax = [CABasicAnimation animationWithKeyPath:@"maxRadius"];
    animMax.fillMode = kCAFillModeRemoved;
    animMax.duration = animationDuration;
    animMax.repeatCount = 1;
    animMax.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    animMax.fromValue = [NSNumber numberWithFloat:self.maxRadius];
    animMax.toValue = [NSNumber numberWithFloat:maxRadius];
    
    CABasicAnimation* animMin = [CABasicAnimation animationWithKeyPath:@"minRadius"];
    animMin.fillMode = kCAFillModeRemoved;
    animMin.duration = animationDuration;
    animMin.repeatCount = 1;
    animMin.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    animMin.fromValue = [NSNumber numberWithFloat:self.minRadius];
    animMin.toValue = [NSNumber numberWithFloat:minRadius];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.fillMode = kCAFillModeRemoved;
    group.duration = animationDuration;
    group.repeatCount = 1;
    group.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    group.animations = [NSArray arrayWithObjects:animMax, animMin, nil];
    
    [self addAnimation:group forKey:@"animationMaxMinRadius"];
    
    self.maxRadius = maxRadius;
    self.minRadius = minRadius;
}

- (void)animateFromStartAngle:(float)fromStartAngle
                 toStartAngle:(float)toStartAngle
                 fromEndAngle:(float)fromEndAngle
                   toEndAngle:(float)toEndAngle
{
    CAAnimationGroup* runingAnimation = (CAAnimationGroup*)[self animationForKey:@"animationStartEndAngle"];
    if(runingAnimation){
        [self removeAnimationForKey:@"animationStartEndAngle"];
    }
    
    NSString* timingFunction = runingAnimation? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseInEaseOut;
    
    CABasicAnimation* animStart = [CABasicAnimation animationWithKeyPath:@"startAngle"];
    animStart.fillMode = kCAFillModeRemoved;
    animStart.duration = animationDuration;
    animStart.repeatCount = 1;
    animStart.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    animStart.fromValue = [NSNumber numberWithFloat:fromStartAngle];
    animStart.toValue = [NSNumber numberWithFloat:toStartAngle];
    
    CABasicAnimation* animEnd = [CABasicAnimation animationWithKeyPath:@"endAngle"];
    animEnd.fillMode = kCAFillModeRemoved;
    animEnd.duration = animationDuration;
    animEnd.repeatCount = 1;
    animEnd.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    animEnd.fromValue = [NSNumber numberWithFloat:fromEndAngle];
    animEnd.toValue = [NSNumber numberWithFloat:toEndAngle];
    
    CAAnimationGroup *group = [CAAnimationGroup animation];
    group.fillMode = kCAFillModeRemoved;
    group.duration = animationDuration;
    group.repeatCount = 1;
    group.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
    group.animations = [NSArray arrayWithObjects:animStart, animEnd, nil];
    
    [self addAnimation:group forKey:@"animationStartEndAngle"];
}

- (void)setStartAngle:(float)startAngle endAngle:(float)endAngle animated:(BOOL)isAnimated
{
    if(isAnimated){
        [self animateFromStartAngle:[self.presentationLayer startAngle]
                       toStartAngle:startAngle
                       fromEndAngle:[self.presentationLayer endAngle]
                         toEndAngle:endAngle];
        self.isFakeAngleAnimation = NO;
    }
    
    self.startAngle = startAngle;
    self.endAngle = endAngle;
}

#pragma mark - Redraw
+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if( [key isEqualToString:@"values"] || [key isEqualToString:@"maxRadius"] || [key isEqualToString:@"minRadius"] || [key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"] || [key isEqualToString:@"showTitles"] || [key isEqualToString:@"transformTitleBlock"]) {
        return YES;
    }
    
    return [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)ctx
{
    NSArray *values = self.presentValues?: self.values;
    if(values.count == 0 || self.minRadius >= self.maxRadius)
        return;
    CGPoint centr = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    float sum = [[values valueForKeyPath:@"@sum.val"] floatValue];
    if(sum <= 0)
        return;
    
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
    CGContextScaleCTM(ctx, 1, -1);
    
    float angleStart = self.startAngle * M_PI / 180.0;
    float angleInterval = (self.endAngle - self.startAngle) * M_PI / 180.0;
    BOOL clockWise = self.startAngle > self.endAngle;
    
    for(PieElement* elem in values){
        float angleEnd = angleStart + angleInterval * elem.val / sum;
        float centrAngle = (angleEnd + angleStart) * 0.5;
        CGPoint centrWithOffset = elem.centrOffset > 0? CGPointMake(cosf(centrAngle) * elem.centrOffset + centr.x, sinf(centrAngle) * elem.centrOffset + centr.y) : centr;
        CGPoint minRadiusStart = CGPointMake(centrWithOffset.x + self.minRadius*cosf(angleStart), centrWithOffset.y + self.minRadius*sinf(angleStart));
        CGPoint maxRadiusEnd = CGPointMake(centrWithOffset.x + self.maxRadius*cosf(angleEnd), centrWithOffset.y + self.maxRadius*sinf(angleEnd));
        
        CGContextSaveGState(ctx);
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, minRadiusStart.x, minRadiusStart.y);
        CGContextAddArc(ctx, centrWithOffset.x, centrWithOffset.y, self.minRadius, angleStart, angleEnd, clockWise);
        CGContextAddLineToPoint(ctx, maxRadiusEnd.x, maxRadiusEnd.y);
        CGContextAddArc(ctx, centrWithOffset.x, centrWithOffset.y, self.maxRadius, angleEnd, angleStart, !clockWise);
        CGContextClosePath(ctx);
        CGContextClip(ctx);
        
        [self drawElement:elem context:ctx];
        CGContextRestoreGState(ctx);
        
        angleStart = angleEnd;
    }
    CGContextRestoreGState(ctx);

    if(self.showTitles != ShowTitlesNever)
        [self drawValuesText:ctx sumValues:sum];
}

- (void)drawElement:(PieElement*)elem context:(CGContextRef)ctx
{
    if(elem.color){
        CGContextSetFillColorWithColor(ctx, [elem.color CGColor]);
        CGContextFillRect(ctx, self.bounds);
    }
}

#pragma mark Titles
- (void)drawValuesText:(CGContextRef)ctx sumValues:(float)sum
{
    NSArray *values = self.presentValues?: self.values;
    CGContextSetShadowWithColor(ctx, CGSizeMake(0,1), 3, [UIColor blackColor].CGColor);
    
    float angleStart = self.startAngle * M_PI / 180.0;
    float angleInterval = (self.endAngle - self.startAngle) * M_PI / 180.0;
    
    for(PieElement* elem in values){
        float angleEnd = angleStart + angleInterval * elem.val / sum;
        BOOL showTitle = elem.showTitle || self.showTitles == ShowTitlesAlways;
        if(!showTitle || elem.titleAlpha <= 0.01){
            angleStart = angleEnd;
            continue;
        }
        UIColor* color = elem.color?: [UIColor blackColor];
        color = [color colorWithAlphaComponent:elem.titleAlpha];
        CGContextSetFillColorWithColor(ctx, color.CGColor);
        
        float angle = (angleStart + angleEnd) / 2.0;
        float percent = 0.0;
        if(sum != 0.0)
            percent = 100.0 * elem.val / sum;
        NSString* text = self.transformTitleBlock? self.transformTitleBlock(elem, percent) : [NSString stringWithFormat:@"%.2f", elem.val];
        float radius = self.maxRadius + elem.centrOffset;
        [self drawText:text angle:-angle radius:radius context:ctx];
        
        angleStart = angleEnd;
    }
}

- (void)drawText:(NSString*)text angle:(float)angle radius:(float)radius context:(CGContextRef)ctx
{
    while (angle < -M_PI_4) {
        angle += M_PI*2;
    }
    while (angle >= 2*M_PI - M_PI_4) {
        angle -= M_PI*2;
    }
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0)
    CGSize textSize = [text sizeWithFont:self.font];
#else
    CGSize textSize = [text sizeWithAttributes:@{NSFontAttributeName:self.font}];
#endif
    CGPoint anchorPoint;
    //clockwise
    if(angle >= -M_PI_4 && angle < M_PI_4){
        anchorPoint = CGPointMake(0, easeInOut((M_PI_4-angle) / M_PI_2));
    } else if(angle >= M_PI_4 && angle < M_PI_2+M_PI_4){
        anchorPoint = CGPointMake(easeInOut((angle-M_PI_4) / M_PI_2), 0);
    } else if(angle >= M_PI_2+M_PI_4 && angle < M_PI+M_PI_4){
        anchorPoint = CGPointMake(1, easeInOut((angle - (M_PI_2+M_PI_4)) / M_PI_2));
    } else {
        anchorPoint = CGPointMake(easeInOut(((2*M_PI - M_PI_4) - angle) / M_PI_2), 1);
    }
    
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    CGPoint pos = CGPointMake(center.x + radius*cosf(angle), center.y + radius*sinf(angle));
    
    CGRect frame = CGRectMake(pos.x - anchorPoint.x * textSize.width,
                              pos.y - anchorPoint.y * textSize.height,
                              textSize.width,
                              textSize.height);
    UIGraphicsPushContext(ctx);
#if (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0)
    [text drawInRect:frame withFont:self.font];
#else
    [text drawInRect:frame withAttributes:@{NSFontAttributeName:self.font}];
#endif
    
    UIGraphicsPopContext();
}

#pragma mark - Hit

- (PieElement*)pieElemInPoint:(CGPoint)point
{
    if(self.values.count == 0 || self.minRadius >= self.maxRadius)
        return nil;
    CGPoint centr = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    float sum = [[self.values valueForKeyPath:@"@sum.val"] floatValue];
    if(sum <= 0)
        return nil;
    
    point.y = self.frame.size.height - point.y;
    
    PieLayer* presentingLayer = ([self animationKeys].count > 0)? self.presentationLayer : self;
    float minRadius = presentingLayer.minRadius;
    float maxRadius = presentingLayer.maxRadius;
    float startAngle = presentingLayer.startAngle;
    float endAngle = presentingLayer.endAngle;
    
    float angleStart = startAngle * M_PI / 180.0;
    float angleInterval = (endAngle - startAngle) * M_PI / 180.0;
    int realIdx = 0, presentIdx = 0;
    for(PieElement* elem in presentingLayer.values){
        if([presentingLayer.deletingIndexes containsObject:@(presentIdx)]){
            presentIdx++;
            continue;
        }
        float angleEnd = angleStart + angleInterval * elem.val / sum;
        float centrAngle = (angleEnd + angleStart) * 0.5;
        CGPoint centrWithOffset = elem.centrOffset > 0? CGPointMake(cosf(centrAngle) * elem.centrOffset + centr.x, sinf(centrAngle) * elem.centrOffset + centr.y) : centr;
        CGPoint minRadiusStart = CGPointMake(centrWithOffset.x + minRadius*cosf(angleStart), centrWithOffset.y + minRadius*sinf(angleStart));
        CGPoint maxRadiusEnd = CGPointMake(centrWithOffset.x + maxRadius*cosf(angleEnd), centrWithOffset.y + maxRadius*sinf(angleEnd));
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, nil, minRadiusStart.x, minRadiusStart.y);
        CGPathAddArc(path, nil, centrWithOffset.x, centrWithOffset.y, minRadius, angleStart, angleEnd, NO);
        CGPathAddLineToPoint(path, nil, maxRadiusEnd.x, maxRadiusEnd.y);
        CGPathAddArc(path, nil, centrWithOffset.x, centrWithOffset.y, maxRadius, angleEnd, angleStart, YES);
        CGPathCloseSubpath(path);
        
        BOOL containsPoint = CGPathContainsPoint(path, nil, point, NO);
        CGPathRelease(path);
        if(containsPoint){
            return self.values[realIdx];
        }
        
        presentIdx++;
        realIdx++;
        angleStart = angleEnd;
    }

    return nil;
}

- (void)dealloc
{
    //only for pie created by user
    if(_isNotCopyForAnimation){
        for(PieElement* elem in self.values){
            [elem removedFromLayer:self];
        }
    }
}

@end
