//
//  TestPieLayer.h
//  MagicPie
//
//  Created by Alexandr on 04.10.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PieLayer;
@interface TestPieLayer : NSObject

+ (void)testsOnPieLayer:(PieLayer*)pieLayer testCount:(int)count eachActionBlock:(void(^)(NSString* actionDesc))actionBlock;

@end
