//
//  Example3PieElem.h
//  MagicPie
//
//  Created by Alexander on 19.01.14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import "PieLayer.h"

// implements custom drawing element
@interface Example3PieLayer : PieLayer
@property (nonatomic, strong) NSArray* colorsArr;
@property (nonatomic, assign) BOOL enableCustomDrawing;
@end
