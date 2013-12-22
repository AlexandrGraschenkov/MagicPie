//
//  PieEl.h
//  MagicPie
//
//  Created by Alexandr on 03.11.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PieElement : NSObject

+ (PieElement*)pieElementWithValue:(float)val color:(UIColor*)color;
@property (nonatomic, assign) float val;
@property (nonatomic, strong) UIColor* color;
@property (nonatomic, assign) float centrOffset;
@property (nonatomic, assign) BOOL showTitle;//default NO
+ (void)animateChanges:(void(^)())changesBlock;

@end