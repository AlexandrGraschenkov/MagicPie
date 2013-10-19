//
//  PieLayer.m
//  infoAnalytucalPortal
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

#import "MagicPieLayer.h"
#define ANIM_KEY_PER_SECOND 40

//[0..1]
static inline float translateValue(float x){
    //1/(1+e^((0.5-x)*12))
    return 1/(1+powf(M_E, (0.5-x)*12));
}

static inline UIColor* colorBetween2Colors(UIColor* color1, UIColor* color2, float val){
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

static inline void insertObjectsToArray(NSMutableArray* arr, NSArray* insertArr, NSArray* indexesArr){
    NSMutableArray* dataArray = [NSMutableArray array];
    for(int i = 0; i < insertArr.count; i++){
        [dataArray addObject:@{@"Object" : insertArr[i], @"Index" : indexesArr[i]}];
    }
    
    [dataArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Index" ascending:YES]]];
    
    float displace = 0;
    for(NSDictionary* dicWrap in dataArray){
        int pos = displace + [dicWrap[@"Index"] integerValue];
        [arr insertObject:dicWrap[@"Object"] atIndex:pos];
        if(pos+1 < arr.count)
            displace++;
    }
}

static inline NSArray* indexesOfObjects(NSArray* arr1, NSArray* arr2){
    NSMutableArray* result = [NSMutableArray array];
    for(id obj in arr2)
        [result addObject:@([arr1 indexOfObject:obj])];
    return [NSArray arrayWithArray:result];
}

NSString * const pieElementChangedNotificationIdentifier = @"PieElementChangedNotificationIdentifier";

@implementation MagicPieElement{
    BOOL hasChanges;
@public
    float titleAlpha;
    int retainCount;
}

- (id)init
{
    self = [super init];
    if(self){
        self.animateChanges = YES;
        hasChanges = NO;
        titleAlpha = 1.0;
    }
    return self;
}

-(id)copyWithZone:(NSZone *)zone
{
    MagicPieElement *another = [[MagicPieElement allocWithZone:zone] init];
    [another fillWithPieElement:self];
    
    return another;
}

- (void)fillWithPieElement:(MagicPieElement*)elem
{
    _val = elem.val;
    _color = elem.color;
    _centrOffset = elem.centrOffset;
    _showTitle = elem.showTitle;
    titleAlpha = elem->titleAlpha;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"[%@: %f]", NSStringFromClass(self.class), self.val];
}

+ (MagicPieElement*)pieElementWithValue:(float)val color:(UIColor *)color
{
    MagicPieElement* result = [MagicPieElement new];
    [result setVal_:val];
    [result setColor_:color];
    return result;
}

- (NSArray*)animationValuesToPieElement:(MagicPieElement*)anotherElement arrayCapacity:(NSUInteger)count
{
    if(count == 1) return @[anotherElement];
    
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:count];
    for (int i = 0; i < count; i++) {
        float v = i / (float)(count - 1);
        MagicPieElement* newElem = [MagicPieElement pieElementWithValue:(anotherElement.val - self.val) * v + self.val
                                                                  color:colorBetween2Colors(self.color, anotherElement.color, v)];
        [newElem setCentrOffset_: (anotherElement.centrOffset - self.centrOffset) * v + self.centrOffset];
        newElem->titleAlpha = (anotherElement->titleAlpha - titleAlpha) * v + titleAlpha;
        newElem.showTitle = self.showTitle;
        [result addObject:newElem];
    }
    return result;
}

#pragma mark - Setters
- (void)setVal:(float)val
{
    [self prepareDelayedChangeNotification];
    if(val < 0){
#ifdef DEBUG
        NSLog(@"[%@ %@]- Negative values not allowed: val=%f => 0.0", NSStringFromClass(self.class), NSStringFromSelector(_cmd), val);
#endif
        val = 0.0;
    }
    _val = val;
}
- (void)setVal_:(float)val
{
    _val = val;
}

- (void)setColor:(UIColor *)color
{
    [self prepareDelayedChangeNotification];
    _color = color;
}
- (void)setColor_:(UIColor *)color
{
    _color = color;
}

- (void)setCentrOffset:(float)centrOffset
{
    [self prepareDelayedChangeNotification];
    _centrOffset = centrOffset;
}
- (void)setCentrOffset_:(float)centrOffset
{
    _centrOffset = centrOffset;
}

- (void)setShowTitle:(BOOL)showTitle
{
    [self prepareDelayedChangeNotification];
    _showTitle = showTitle;
}

- (void)prepareDelayedChangeNotification
{
    if(hasChanges || retainCount <= 0)
        return;
    MagicPieElement* copyElement = [self copy];
    hasChanges = YES;
    [self performSelector:@selector(sendChangeNotification:) withObject:copyElement afterDelay:0.0];
}

- (void)sendChangeNotification:(MagicPieElement*)begunState
{
    [[NSNotificationCenter defaultCenter] postNotificationName:pieElementChangedNotificationIdentifier object:self userInfo:@{@"begunState" : begunState}];
    hasChanges = NO;
}

@end

@interface MagicPieLayer ()
{
    BOOL isInitalized;
}
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong, readwrite) NSArray* values;
@property (nonatomic, strong) NSMutableArray* deletingIndexes;
@property (nonatomic, assign) BOOL isFakeAngleAnimation;
@end

@implementation MagicPieLayer
@dynamic values, deletingIndexes, maxRadius, minRadius, font, transformValueBlock, startAngle, endAngle, isFakeAngleAnimation, showTitles;
@synthesize animationDuration;

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

- (void)setup
{
    self.maxRadius = 100;
    self.minRadius = 0;
    self.startAngle = 0.0;
    self.endAngle = 360.0;
    self.animationDuration = 0.6;
    self.showTitles = ShowTitlesNever;
    self.font = [UIFont systemFontOfSize:15];
    if ([self respondsToSelector:@selector(setContentsScale:)])
    {
        self.contentsScale = [[UIScreen mainScreen] scale];
    }
}

#pragma mark - Adding, inserting and deleting
- (void)addValues:(NSArray *)addingNewValues animated:(BOOL)animated
{
    int count = addingNewValues.count;
    int currCount = self.values.count;
    NSMutableArray* indexes = [NSMutableArray arrayWithCapacity:addingNewValues.count];
    for(int i = 0; i < count; i++){
        [indexes addObject:@(i+currCount)];
    }
    [self insertValues:addingNewValues atIndexes:indexes animated:animated];
}

- (void)insertValues:(NSArray *)array atIndexes:(NSArray *)indexes animated:(BOOL)animated
{
    NSAssert2(array.count == indexes.count, @"Array sizes must be equal: values.count = %d; indexes.count = %d;", array.count, indexes.count);
    for(MagicPieElement* elem in array){
        elem->retainCount++;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pieElementUpdated:) name:pieElementChangedNotificationIdentifier object:elem];
    }
    
    NSMutableArray* newValues = [NSMutableArray arrayWithArray:self.values];
    insertObjectsToArray(newValues, array, indexes);
    
    if(animated){
        BOOL const isAnimating = [self animationForKey:@"animationValues"] != nil;
        NSArray* currValues = isAnimating? [self.presentationLayer values] : self.values;
        NSMutableArray* deletingIndexes = isAnimating? [NSMutableArray arrayWithArray:[self.presentationLayer deletingIndexes]] : [NSMutableArray array];
        [deletingIndexes sortUsingSelector:@selector(compare:)];
        BOOL isCountMatch = deletingIndexes.count + self.values.count == currValues.count;
        if(!isCountMatch){
            if(self.values.count == currValues.count){//try solve problem
                self.deletingIndexes = nil;
                deletingIndexes = [NSMutableArray array];
            } else {
#ifdef DEBUG
                NSLog(@"[%@] Insert animation disabled. Error occured", NSStringFromClass(self.class));
#endif
                self.deletingIndexes = nil;
                [self removeAnimationForKey:@"animationValues"];
                self.values = [NSArray arrayWithArray:newValues];
                return;
            }
        }
        
        NSMutableArray* indexesWithDeletingElements = [NSMutableArray array];
        for(NSNumber* indxNumber in indexes){
            int indx = [indxNumber integerValue];
            for(NSNumber* delIndex in deletingIndexes){
                if([delIndex integerValue] <= indx)
                    indx++;
            }
            [indexesWithDeletingElements addObject:@(indx)];
        }
        
        //_______ fromValues _______
        NSMutableArray* fromValues = [NSMutableArray arrayWithArray:currValues];
        NSMutableArray* copyInsertArr = [[NSMutableArray alloc] initWithArray:array copyItems:YES];
        for(MagicPieElement* elem in copyInsertArr){
            [elem setVal_:0.0];
            elem->titleAlpha = 0.0;
        }
        insertObjectsToArray(fromValues, copyInsertArr, indexesWithDeletingElements);
        
        //_______ toValues _______
        NSMutableArray* toValues = [[NSMutableArray alloc]initWithArray:self.values copyItems:YES];
        for(NSNumber* deleteIndex in deletingIndexes){
            MagicPieElement* elem = [currValues[deleteIndex.integerValue] copy];
            [elem setVal_:0.0];
            elem->titleAlpha = 0.0;
            [toValues insertObject:elem atIndex:deleteIndex.integerValue];
        }
        insertObjectsToArray(toValues, array, indexesWithDeletingElements);
        
        //_______ new deleting elements _______
        NSArray* sortedIndexes = [indexesWithDeletingElements sortedArrayUsingSelector:@selector(compare:)];
        for(NSNumber* insertIndex in sortedIndexes){
            for(int i = 0; i < deletingIndexes.count; i++){
                int deleteIndexPos = [deletingIndexes[i] integerValue];
                if(deleteIndexPos >= [insertIndex integerValue]){
                    deletingIndexes[i] = @(deleteIndexPos + 1);
                }
            }
        }
        self.deletingIndexes = deletingIndexes;
        
        [self removeAnimationForKey:@"animationValues"];
        NSString* timingFunction = isAnimating? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseInEaseOut;
        [self animateFromValues:fromValues toValues:toValues timingFunction:timingFunction];
    } else {
        [self removeAnimationForKey:@"animationValues"];
    }
    self.values = [NSArray arrayWithArray:newValues];
}

- (void)deleteValues:(NSArray *)valuesToDelete animated:(BOOL)animated
{
    for(MagicPieElement* elem in valuesToDelete){
        elem->retainCount--;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:pieElementChangedNotificationIdentifier object:elem];
    }
    NSMutableArray* newValues = [[NSMutableArray alloc] initWithArray:self.values];
    [newValues removeObjectsInArray:valuesToDelete];
    
    if(animated){
        BOOL const isAnimating = [self animationForKey:@"animationValues"] != nil;
        NSArray* currValues = isAnimating? [self.presentationLayer values] : self.values;
        NSMutableArray* deletingIndexes = isAnimating? [NSMutableArray arrayWithArray:[self.presentationLayer deletingIndexes]] : [NSMutableArray array];
        [deletingIndexes sortUsingSelector:@selector(compare:)];
        BOOL isCountMatch = deletingIndexes.count + self.values.count == currValues.count;
        if(!isCountMatch){
            if(self.values.count == currValues.count){//try solve problem
                self.deletingIndexes = nil;
                deletingIndexes = [NSMutableArray array];
            } else {
#ifdef DEBUG
                NSLog(@"[%@] Delete animation disabled. Error occured", NSStringFromClass(self.class));
#endif
                self.deletingIndexes = nil;
                [self removeAnimationForKey:@"animationValues"];
                self.values = [NSArray arrayWithArray:newValues];
                return;
            }
        }
        
        int i = 0;//index of deleting objects
        for(MagicPieElement* elem in self.values){
            while ([deletingIndexes containsObject:@(i)]) {
                i++;
            }
            if([valuesToDelete containsObject:elem]){
                [deletingIndexes addObject:@(i)];
            }
            i++;
        }
        [deletingIndexes sortUsingSelector:@selector(compare:)];
        self.deletingIndexes = deletingIndexes;
        
        NSMutableArray* toValues = [NSMutableArray arrayWithArray:newValues];
        for(NSNumber* deleteIndex in deletingIndexes){
            int pos = [deleteIndex integerValue];
            MagicPieElement* deleteElement = [currValues[pos] copy];
            [deleteElement setVal_:0.0];
            deleteElement->titleAlpha = 0.0;
            [toValues insertObject:deleteElement atIndex:pos];
        }
        [self removeAnimationForKey:@"animationValues"];
        NSString* timingFunction = isAnimating? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseInEaseOut;
        [self animateFromValues:currValues toValues:toValues timingFunction:timingFunction];
    } else {
        [self removeAnimationForKey:@"animationValues"];
    }
    self.values = newValues;
}

#pragma mark - Animate setters

- (void)animateFromValues:(NSArray*)fromValues toValues:(NSArray*)toValues timingFunction:(NSString*)timingFunction
{
    NSAssert2(fromValues.count == toValues.count, @"Array sizes must be equal: fromValues.count = %d; toValues.count = %d;", fromValues.count, toValues.count);
    float fromSum = [[fromValues valueForKeyPath:@"@sum.val"] floatValue];
    float toSum = [[toValues valueForKeyPath:@"@sum.val"] floatValue];
    if(fromSum <= 0 || toSum <= 0){
        [self animateStartAngleEndAngleFillUp:(fromSum==0) timingFunction:timingFunction];
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
    [self addAnimation:valuesAnim forKey:@"animationValues"];
}

- (void)animateStartAngleEndAngleFillUp:(BOOL)fillUp timingFunction:(NSString*)timingFunction
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
        [self animateFromStartAngle:(isAnimating?[self.presentationLayer startAngle] : self.startAngle)
                       toStartAngle:self.startAngle
                       fromEndAngle:(isAnimating?[self.presentationLayer endAngle] : self.endAngle)
                         toEndAngle:self.startAngle];
        self.isFakeAngleAnimation = YES;
        
        //we don't have values in self.values, so make animation with 2 key for save values when animating
        NSArray* currValues = [self.presentationLayer values];
        CAKeyframeAnimation* valuesAnim = [CAKeyframeAnimation animationWithKeyPath:@"values"];
        valuesAnim.values = @[currValues, currValues];
        valuesAnim.timingFunction = [CAMediaTimingFunction functionWithName:timingFunction];
        valuesAnim.duration = animationDuration;
        valuesAnim.repeatCount = 1;
        valuesAnim.fillMode = kCAFillModeRemoved;
        valuesAnim.delegate = self;
        
        NSMutableArray* deletingIndexes = [NSMutableArray array];
        for(int i = 0; i < currValues.count; i++)
            [deletingIndexes addObject:@(i)];
        self.deletingIndexes = deletingIndexes;
        [self removeAnimationForKey:@"animationValues"];
        [self addAnimation:valuesAnim forKey:@"animationValues"];
    }
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)finished
{
    if(finished && [self animationForKey:@"animationValues"] == anim){
        self.deletingIndexes = nil;
    } else if([self animationForKey:@"animationStartEndAngle"] == anim){
        self.isFakeAngleAnimation = NO;
    }
}

- (void)pieElementUpdated:(NSNotification*)notif
{
    MagicPieElement* newElem = notif.object;
    MagicPieElement* prevValue = notif.userInfo[@"begunState"];
    int indxOfObject = [self.values indexOfObject:newElem];
    BOOL const isAnimating = [self animationForKey:@"animationValues"] != nil;
    
    if(isAnimating || newElem.animateChanges){
        NSArray* currValues = isAnimating? [self.presentationLayer values] : self.values;
        NSMutableArray* deletingIndexes = isAnimating? [NSMutableArray arrayWithArray:[self.presentationLayer deletingIndexes]] : [NSMutableArray array];
        [deletingIndexes sortedArrayUsingSelector:@selector(compare:)];
        BOOL isCountMatch = deletingIndexes.count + self.values.count == currValues.count;
        if(!isCountMatch){
            if(self.values.count == currValues.count){//try solve problem
                self.deletingIndexes = nil;
                deletingIndexes = [NSMutableArray array];
            } else {
#ifdef DEBUG
                NSLog(@"[%@] Change val animation disabled. Error occured", NSStringFromClass(self.class));
#endif
                self.deletingIndexes = nil;
                [self removeAnimationForKey:@"animationValues"];
                [self setNeedsDisplay];
                return;
            }
        }
        
        NSMutableArray* fromValues = [NSMutableArray arrayWithArray:currValues];
        if(!isAnimating){
            fromValues[indxOfObject] = prevValue;
        }
        NSMutableArray* toValues = [[NSMutableArray alloc]initWithArray:self.values copyItems:YES];
        for(NSNumber* deleteIndex in deletingIndexes){
            MagicPieElement* elem = [currValues[deleteIndex.integerValue] copy];
            [elem setVal_:0.0];
            elem->titleAlpha = 0.0;
            [toValues insertObject:elem atIndex:deleteIndex.integerValue];
        }
        
        [self removeAnimationForKey:@"animationValues"];
        NSString* timingFunction = isAnimating? kCAMediaTimingFunctionEaseOut : kCAMediaTimingFunctionEaseInEaseOut;
        [self animateFromValues:fromValues toValues:toValues timingFunction:timingFunction];
    } else {
        [self setNeedsDisplay];
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
    if( [key isEqualToString:@"values"] || [key isEqualToString:@"maxRadius"] || [key isEqualToString:@"minRadius"] || [key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"] || [key isEqualToString:@"showTitles"])
        return YES;
    
    return [super needsDisplayForKey:key];
}

- (void)drawInContext:(CGContextRef)ctx
{
    if(self.values.count == 0 || self.minRadius >= self.maxRadius)
        return;
    CGPoint centr = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    float sum = [[self.values valueForKeyPath:@"@sum.val"] floatValue];
    if(sum <= 0)
        return;
    
    CGContextSaveGState(ctx);
    CGContextTranslateCTM(ctx, 0, self.bounds.size.height);
    CGContextScaleCTM(ctx, 1, -1);
    
    float angleStart = self.startAngle * M_PI / 180.0;
    float angleInterval = (self.endAngle - self.startAngle) * M_PI / 180.0;
    for(MagicPieElement* elem in self.values){
        float angleEnd = angleStart + angleInterval * elem.val / sum;
        float centrAngle = (angleEnd + angleStart) * 0.5;
        CGPoint centrWithOffset = elem.centrOffset > 0? CGPointMake(cosf(centrAngle) * elem.centrOffset + centr.x, sinf(centrAngle) * elem.centrOffset + centr.y) : centr;
        CGPoint minRadiusStart = CGPointMake(centrWithOffset.x + self.minRadius*cosf(angleStart), centrWithOffset.y + self.minRadius*sinf(angleStart));
        CGPoint maxRadiusEnd = CGPointMake(centrWithOffset.x + self.maxRadius*cosf(angleEnd), centrWithOffset.y + self.maxRadius*sinf(angleEnd));
        
        CGContextSaveGState(ctx);
        
        CGContextBeginPath(ctx);
        CGContextMoveToPoint(ctx, minRadiusStart.x, minRadiusStart.y);
        CGContextAddArc(ctx, centrWithOffset.x, centrWithOffset.y, self.minRadius, angleStart, angleEnd, NO);
        CGContextAddLineToPoint(ctx, maxRadiusEnd.x, maxRadiusEnd.y);
        CGContextAddArc(ctx, centrWithOffset.x, centrWithOffset.y, self.maxRadius, angleEnd, angleStart, YES);
        CGContextClosePath(ctx);
        CGContextClip(ctx);
        
        UIColor* color = elem.color?: [UIColor blackColor];
        [self fillSegment:color context:ctx];
        CGContextRestoreGState(ctx);
        
        angleStart = angleEnd;
    }
    CGContextRestoreGState(ctx);

    if(self.showTitles != ShowTitlesNever)
        [self drawValuesText:ctx];
}

- (void)fillSegment:(UIColor*)color context:(CGContextRef)ctx
{
    //хочешь градиентом, хочешь просто заливкой. Наследуйся, переопределяй
    CGContextSetFillColorWithColor(ctx, [color CGColor]);
    CGContextFillRect(ctx, self.bounds);
}

#pragma mark Titles
- (void)drawValuesText:(CGContextRef)ctx
{
    float sum = [[self.values valueForKeyPath:@"@sum.val"] floatValue];
    
    CGContextSetShadowWithColor(ctx, CGSizeMake(0,1), 3, [UIColor blackColor].CGColor);
    
    float angleStart = self.startAngle * M_PI / 180.0;
    float angleInterval = (self.endAngle - self.startAngle) * M_PI / 180.0;
    for(MagicPieElement* elem in self.values){
        float angleEnd = angleStart + angleInterval * elem.val / sum;
        BOOL showTitle = elem.showTitle || self.showTitles == ShowTitlesAlways;
        if(!showTitle || elem->titleAlpha <= 0.01){
            angleStart = angleEnd;
            continue;
        }
        UIColor* color = elem.color?: [UIColor blackColor];
        color = [color colorWithAlphaComponent:elem->titleAlpha];
        CGContextSetFillColorWithColor(ctx, color.CGColor);
        
        float angle = (angleStart + angleEnd) / 2.0;
        NSString* text = self.transformValueBlock? self.transformValueBlock(elem) : [NSString stringWithFormat:@"%.2f", elem.val];
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
    
    CGSize textSize = [text sizeWithFont:self.font];
    CGPoint anchorPoint;
    //clockwise
    if(angle >= -M_PI_4 && angle < M_PI_4){
        anchorPoint = CGPointMake(0, translateValue((M_PI_4-angle) / M_PI_2));
    } else if(angle >= M_PI_4 && angle < M_PI_2+M_PI_4){
        anchorPoint = CGPointMake(translateValue((angle-M_PI_4) / M_PI_2), 0);
    } else if(angle >= M_PI_2+M_PI_4 && angle < M_PI+M_PI_4){
        anchorPoint = CGPointMake(1, translateValue((angle - (M_PI_2+M_PI_4)) / M_PI_2));
    } else {
        anchorPoint = CGPointMake(translateValue(((2*M_PI - M_PI_4) - angle) / M_PI_2), 1);
    }
    
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    CGPoint pos = CGPointMake(center.x + radius*cosf(angle), center.y + radius*sinf(angle));
    
    CGRect frame = CGRectMake(pos.x - anchorPoint.x * textSize.width,
                              pos.y - anchorPoint.y * textSize.height,
                              textSize.width,
                              textSize.height);
    UIGraphicsPushContext(ctx);
    [text drawInRect:frame withFont:self.font];
    UIGraphicsPopContext();
}

#pragma mark - Hit

- (MagicPieElement*)pieElemInPoint:(CGPoint)point
{
    if(self.values.count == 0 || self.minRadius >= self.maxRadius)
        return nil;
    CGPoint centr = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    float sum = [[self.values valueForKeyPath:@"@sum.val"] floatValue];
    if(sum <= 0)
        return nil;
    
    point.y = self.frame.size.height - point.y;
    
    MagicPieLayer* presentingLayer = ([self animationKeys].count > 0)? self.presentationLayer : self;
    float minRadius = presentingLayer.minRadius;
    float maxRadius = presentingLayer.maxRadius;
    float startAngle = presentingLayer.startAngle;
    float endAngle = presentingLayer.endAngle;
    
    float angleStart = startAngle * M_PI / 180.0;
    float angleInterval = (endAngle - startAngle) * M_PI / 180.0;
    int realIdx = 0, presentIdx = 0;
    for(MagicPieElement* elem in presentingLayer.values){
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
        CGAffineTransform trans = CGAffineTransformIdentity;
        CGPathMoveToPoint(path, &trans, minRadiusStart.x, minRadiusStart.y);
        CGPathAddArc(path, &trans, centrWithOffset.x, centrWithOffset.y, minRadius, angleStart, angleEnd, NO);
        CGPathAddLineToPoint(path, &trans, maxRadiusEnd.x, maxRadiusEnd.y);
        CGPathAddArc(path, &trans, centrWithOffset.x, centrWithOffset.y, maxRadius, angleEnd, angleStart, YES);
        CGPathCloseSubpath(path);
        
        if(CGPathContainsPoint(path, &trans, point, NO)){
            return self.values[realIdx];
        }
        
        presentIdx++;
        realIdx++;
        angleStart = angleEnd;
    }

    return nil;
}

@end
