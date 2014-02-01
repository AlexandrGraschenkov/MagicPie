//
//  TestPieLayer.m
//  MagicPie
//
//  Created by Alexandr on 04.10.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "TestPieLayer.h"
#import "MagicPieLayer.h"

typedef enum PieAction
{
    PieActionAdd = 0,
    PieActionInsert = 1,
    PieActionDelete = 2
}PieAction;

@implementation TestPieLayer

+ (void)testsOnPieLayer:(PieLayer*)pieLayer testCount:(int)count eachActionBlock:(void(^)(NSString* actionDesc))actionBlock
{
    NSDictionary* userInfo = @{@"actionBlock" : actionBlock, @"count" : [NSMutableString stringWithFormat:@"%d", count], @"pieLayer" : pieLayer};
    [NSTimer scheduledTimerWithTimeInterval:0.1
                                     target:self
                                   selector:@selector(timerAction:)
                                   userInfo:userInfo
                                    repeats:YES];
}

+ (void)timerAction:(NSTimer*)timer
{
    NSMutableString* timerCountStr = timer.userInfo[@"count"];
    NSUInteger count = [timerCountStr integerValue];
    if(count <= 0){
        [timer invalidate];
        return;
    } else {
        count--;
        [timerCountStr setString:[NSString stringWithFormat:@"%lu", count]];
    }
    
    void(^actionBlock)(NSString* actionDesc) = timer.userInfo[@"actionBlock"];
    PieLayer* pieLayer = timer.userInfo[@"pieLayer"];
    if(actionBlock){
        NSUInteger valuesCount = pieLayer.values.count;
        NSString* actionDesc = [self runRandomActionWithPie:pieLayer];
        if(actionDesc){
            actionDesc = [NSString stringWithFormat:@"Curr values count %lu. %@", valuesCount, actionDesc];
            actionBlock(actionDesc);
        }
    }else
        [self runRandomActionWithPie:pieLayer];
}

+ (NSString*)runRandomActionWithPie:(PieLayer*)pieLayer
{
    int action = arc4random() % 3;
    if (action == PieActionAdd){
        NSArray* arr = [self randArr];
        if(arr.count == 0)
            return nil;
        
        [pieLayer addValues:arr animated:YES];
        return [NSString stringWithFormat:@"Add %lu elements", arr.count];
    } else if(action == PieActionInsert){
        NSArray* arr = [self randArr];
        if(arr.count == 0)
            return nil;
        
        NSUInteger count = pieLayer.values.count;
        NSMutableArray* indxArr = [NSMutableArray array];
        for(int i = 0; i < arr.count; i++){
            int indx = arc4random() % (count+1);
            [indxArr addObject:@(indx)];
            if(indx == count)
                count++;
        }
        [pieLayer insertValues:arr atIndexes:indxArr animated:YES];
        return [NSString stringWithFormat:@"Insert %lu elements at indexes: %@", arr.count, [self arrDesc:indxArr]];
    } else if(action == PieActionDelete) {
        if(pieLayer.values.count == 0)
            return nil;
        int countDelete = arc4random() % pieLayer.values.count;
        if(countDelete == 0)
            return nil;
        
        NSMutableArray* deleteIndexArr = [NSMutableArray array];
        NSMutableArray* deleteArr = [NSMutableArray array];
        for(int i = 0; i < countDelete; i++){
            int indxDelete = arc4random() % pieLayer.values.count;
            while ([deleteIndexArr containsObject:@(indxDelete)]) {
                indxDelete = arc4random() % pieLayer.values.count;
            }
            [deleteArr addObject:pieLayer.values[indxDelete]];
            [deleteIndexArr addObject:@(indxDelete)];
        }
        
        [pieLayer deleteValues:deleteArr animated:YES];
        return [NSString stringWithFormat:@"Delete with indexes: %@", [self arrDesc:deleteIndexArr]];
    }
    return nil;
}

+ (NSString*)arrDesc:(NSArray*)arr
{
    NSString* str = arr.description;
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@""];
    str = [str stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return str;
}

+ (NSArray*)randArr
{
    int count = arc4random() % 6;
    NSMutableArray* arr = [NSMutableArray array];
    for(int i = 0; i < count; i++)
        [arr addObject:[self randElem]];
    return [NSArray arrayWithArray:arr];
}

+ (PieElement*)randElem
{
    PieElement* result = [PieElement pieElementWithValue:(arc4random() % 10 + 5) color:[self randColor]];
//    result.showTitle = YES;
    return result;
}

+ (UIColor*)randColor
{
    CGFloat hue = ( arc4random() % 256 / 256.0 );  //  0.0 to 1.0
    CGFloat saturation = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from white
    CGFloat brightness = ( arc4random() % 128 / 256.0 ) + 0.5;  //  0.5 to 1.0, away from black
    UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
    return color;
}

@end
