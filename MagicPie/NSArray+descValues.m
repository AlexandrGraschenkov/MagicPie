//
//  NSArray+descValues.m
//  MagicPie
//
//  Created by Alexander on 25.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import "NSArray+descValues.h"

@implementation NSArray (descValues)
- (NSString*)descValues
{
    NSMutableString* str = [[NSMutableString alloc] initWithString:@"["];
    for(id obj in self){
        if(str.length > 1)
            [str appendFormat:@", %@", obj];
        else
            [str appendFormat:@"%@", obj];
    }
    [str appendString:@"]"];
    return str;
}
@end
