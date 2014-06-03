//
//  MyPieElement.m
//  MagicPie
//
//  Created by Alexander on 31.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "MyPieElemntExample4.h"

@implementation MyPieElemntExample4

- (id)copyWithZone:(NSZone *)zone
{
    MyPieElemntExample4 *copyElem = [super copyWithZone:zone];
    copyElem.title = self.title;
    
    return copyElem;
}

@end