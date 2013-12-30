//
//  MyPieElement.m
//  MagicPie
//
//  Created by Alexander on 31.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "MyPieElement.h"

@implementation MyPieElement

- (id)copyWithZone:(NSZone *)zone
{
    MyPieElement *copyElem = [super copyWithZone:zone];
    copyElem.title = self.title;
    
    return copyElem;
}

@end
