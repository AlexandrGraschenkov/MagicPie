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

#import "PieLayer.h"
#import "PieElement.h"
#define ANIM_KEY_PER_SECOND 36

//[0..1]
inline float translateValue(float x){
    //1/(1+e^((0.5-x)*12))
    return 1/(1+powf(M_E, (0.5-x)*12));
}

inline void sortObjectsAndIndexesByIndex(NSMutableArray* objects, NSMutableArray* indexes){
    NSMutableArray* dataArray = [NSMutableArray array];
    for(int i = 0; i < indexes.count; i++){
        [dataArray addObject:@{@"Object" : objects[i], @"Index" : indexes[i]}];
    }
    [dataArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Index" ascending:YES]]];
    
    [objects removeAllObjects];
    [indexes removeAllObjects];
    for(NSDictionary* dic in dataArray){
        [objects addObject:dic[@"Object"]];
        [objects addObject:dic[@"Index"]];
    }
}

inline void insertObjectsToArray(NSMutableArray* arr, NSMutableArray* objects, NSMutableArray* indexes){
    sortObjectsAndIndexesByIndex(objects, indexes);
    for(int i = 0; i < indexes.count; i++){
        [arr insertObject:objects[i] atIndex:[indexes[i] integerValue]];
    }
}

inline NSArray* indexesOfObjects(NSArray* arr1, NSArray* arr2){
    NSMutableArray* result = [NSMutableArray array];
    for(id obj in arr2)
        [result addObject:@([arr1 indexOfObject:obj])];
    return [NSArray arrayWithArray:result];
}


#pragma mark - Animation object wrapper
@interface InsertElement : NSObject
@property (nonatomic, strong, readonly) PieElement* elem;
@property (nonatomic, assign, readonly) int index;
- (id)initWithElement:(PieElement*)elem toIndex:(int)index;
@end

@implementation InsertElement
- (id)initWithElement:(PieElement*)elem toIndex:(int)index
{
    self = [super init];
    if(self){
        _elem = elem;
        _index = index;
    }
    return self;
}
@end

@interface DeleteElement : NSObject
@property (nonatomic, assign, readonly) int index;
- (id)initWithIndex:(int)index;
@end

@implementation DeleteElement
- (id)initWithIndex:(int)index;
{
    self = [super init];
    if(self){
        _index = index;
    }
    return self;
}
@end

@interface ChangeElement : NSObject
@property (nonatomic, strong, readonly) PieElement* fromValue;
@property (nonatomic, strong, readonly) PieElement* toValue;
- (id)initWithFromValue:(PieElement*)fromValue toValue:(PieElement*)toValue;
@end

@implementation ChangeElement

- (id)initWithFromValue:(PieElement *)fromValue toValue:(PieElement *)toValue
{
    self = [super init];
    if(self){
        _fromValue = fromValue;
        _toValue = toValue;
    }
    return self;
}

@end

extern NSString * const pieElementChangedNotificationIdentifier;

@interface PieElement(hidden)
@property (nonatomic, assign) float titleAlpha;
@property (nonatomic, assign) int retainCount2;
- (void)setVal_:(float)val;
- (void)setColor_:(UIColor *)color;
- (void)setCentrOffset_:(float)centrOffset;
- (NSArray*)animationValuesToPieElement:(PieElement*)anotherElement arrayCapacity:(NSUInteger)count;
@end


#pragma mark - PieLayer
@interface PieLayer ()
{
    BOOL isInitalized;
}
@property (nonatomic, strong) UIFont* font;
@property (nonatomic, strong, readwrite) NSArray* values;
@property (nonatomic, strong) NSMutableArray* deletingIndexes;
@property (nonatomic, strong) NSMutableArray* delayedChangeValues;
@property (nonatomic, strong) NSArray* delayedStartValues;
@property (nonatomic, strong) NSArray* startValuesState;
@property (nonatomic, assign) BOOL isFakeAngleAnimation;
@end

@implementation PieLayer
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
    self.delayedChangeValues = [NSMutableArray new];
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
    for(PieElement* elem in array){
        elem.retainCount2++;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pieElementUpdated:) name:pieElementChangedNotificationIdentifier object:elem];
    }
    
    NSMutableArray* newValues = [NSMutableArray arrayWithArray:self.values];
    NSMutableArray* mutableArray = [array mutableCopy];
    insertObjectsToArray(newValues, mutableArray, [indexes mutableCopy]);
    
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
        for(PieElement* elem in copyInsertArr){
            [elem setVal_:0.0];
            elem.titleAlpha = 0.0;
        }
        insertObjectsToArray(fromValues, copyInsertArr, indexesWithDeletingElements);
        
        //_______ toValues _______
        NSMutableArray* toValues = [[NSMutableArray alloc]initWithArray:self.values copyItems:YES];
        for(NSNumber* deleteIndex in deletingIndexes){
            PieElement* elem = [currValues[deleteIndex.integerValue] copy];
            [elem setVal_:0.0];
            elem.titleAlpha = 0.0;
            [toValues insertObject:elem atIndex:deleteIndex.integerValue];
        }
        insertObjectsToArray(toValues, mutableArray, indexesWithDeletingElements);
        
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
    for(PieElement* elem in valuesToDelete){
        if([self.values containsObject:elem])
            elem.retainCount2--;
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
        for(PieElement* elem in self.values){
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
            PieElement* deleteElement = [currValues[pos] copy];
            [deleteElement setVal_:0.0];
            deleteElement.titleAlpha = 0.0;
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

- (BOOL)performDelayedAnimation
{
    if(self.delayedChangeValues)
        return YES;
    BOOL const isAnimating = [self animationForKey:@"animationValues"] != nil;
    self.delayedStartValues = isAnimating? [self.presentationLayer values] : self.values;
    self.delayedChangeValues = [[NSMutableArray alloc] init];
    
    NSMutableArray* deletingIndexes = isAnimating? [NSMutableArray arrayWithArray:[self.presentationLayer deletingIndexes]] : [NSMutableArray array];
    [deletingIndexes sortUsingSelector:@selector(compare:)];
    BOOL isCountMatch = deletingIndexes.count + self.values.count == self.delayedStartValues.count;
    if(!isCountMatch){//try solve problem
        self.deletingIndexes = nil;
        if(self.values.count != self.delayedStartValues.count){
            return NO;
        }
    }
    
    [self performSelector:@selector(dalyedAnimateChanges) withObject:nil afterDelay:0.0];
    return YES;
}

- (void)insertValues2:(NSArray *)array atIndexes:(NSArray *)indexes animated:(BOOL)animated
{
    NSAssert2(array.count == indexes.count, @"Array sizes must be equal: values.count = %d; indexes.count = %d;", array.count, indexes.count);
    for(PieElement* elem in array){
        elem.retainCount2++;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pieElementUpdated:) name:pieElementChangedNotificationIdentifier object:elem];
    }
    
    NSMutableArray* newValues = [NSMutableArray arrayWithArray:self.values];
    NSMutableArray* mutArray = [array mutableCopy];
    NSMutableArray* 
    insertObjectsToArray(newValues, array, indexes);
    self.values = [NSArray arrayWithArray:newValues];
    
    if(![self performDelayedAnimation]){
        [self removeAnimationForKey:@"animationValues"];
        return;
    }
    
    for(int i = 0; i < array.count; i++){
        InsertElement* insertElem = [[InsertElement alloc] initWithElement:array[i] toIndex:[indexes[i] integerValue]];
        [self.delayedChangeValues addObject:insertElem];
    }
}

- (void)deleteValues2:(NSArray *)valuesToDelete animated:(BOOL)animated
{
    for(PieElement* elem in valuesToDelete){
        if([self.values containsObject:elem])
            elem.retainCount2--;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:pieElementChangedNotificationIdentifier object:elem];
    }
    
    NSMutableArray* newValues = [NSMutableArray arrayWithArray:self.values];
    [newValues removeObjectsInArray:valuesToDelete];
    self.values = [NSArray arrayWithArray:newValues];
    
    if(![self performDelayedAnimation]){
        [self removeAnimationForKey:@"animationValues"];
        return;
    }
    
}

- (void)dalyedAnimateChanges
{
    if(self.delayedChangeValues.count == 0)
        return;
    
    NSMutableArray* fromValues = [NSMutableArray arrayWithArray:self.delayedStartValues];
    NSMutableArray* toValues = [NSMutableArray array];
    for(id action in self.delayedChangeValues){
        if([action isKindOfClass:[InsertElement class]]){
            [self updateAnimationArrayWithInsert:action fromValues:fromValues toValues:toValues deletingIndexes:self.deletingIndexes];
        } else if([action isKindOfClass:[ChangeElement class]]){
            [self updateAnimationArrayWithChange:action fromValues:fromValues toValues:toValues];
        } else if([action isKindOfClass:[DeleteElement class]]){
            [self updateAnimationArrayWithDelete:action toValues:toValues deletingIndexes:self.deletingIndexes];
        }
    }
}

- (void)updateAnimationArrayWithInsert:(InsertElement*)insertElement
                            fromValues:(NSMutableArray*)fromValues
                              toValues:(NSMutableArray*)toValues
                       deletingIndexes:(NSMutableArray*)deletingIndexes
{
    PieElement* startElem = [insertElement copy];
    [startElem setVal_:0.0];
    startElem.titleAlpha = 0.0;
    
    [fromValues insertObject:startElem atIndex:insertElement.index];
    [toValues insertObject:insertElement.elem atIndex:insertElement.index];
    for(int i = 0; i < deletingIndexes.count; i++){
        int deleteIdx = [deletingIndexes[i] integerValue];
        if(insertElement.index <= deleteIdx)
            deletingIndexes[i] = @(deleteIdx + 1);
    }
}

- (void)updateAnimationArrayWithChange:(ChangeElement*)changeElement
                            fromValues:(NSMutableArray*)fromValues
                              toValues:(NSMutableArray*)toValues
{
    int idx = [fromValues indexOfObject:changeElement.fromValue];
    if(idx == NSNotFound)return;
    toValues[idx] = changeElement.toValue;
}

- (void)updateAnimationArrayWithDelete:(InsertElement*)deleteElement
                              toValues:(NSMutableArray*)toValues
                       deletingIndexes:(NSMutableArray*)deletingIndexes
{
    int delIdx = deleteElement.index;
    if(delIdx >= 0 && delIdx < toValues.count && ![deletingIndexes containsObject:@(delIdx)]){
        PieElement* deleteElement = toValues[delIdx];
        [deleteElement setVal_:0.0];
        deleteElement.titleAlpha = 0.0;
        [deletingIndexes addObject:@(delIdx)];
    }
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
    PieElement* newElem = notif.object;
    PieElement* prevValue = notif.userInfo[@"begunState"];
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
            PieElement* elem = [currValues[deleteIndex.integerValue] copy];
            [elem setVal_:0.0];
            elem.titleAlpha = 0.0;
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
    for(PieElement* elem in self.values){
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
    for(PieElement* elem in self.values){
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

- (void)dealloc
{
    for(PieElement* elem in self.values){
        elem.retainCount2--;
        [[NSNotificationCenter defaultCenter] removeObserver:self name:pieElementChangedNotificationIdentifier object:elem];
    }
}

@end
