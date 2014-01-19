//
//  MetrtTable.h
//  MagicPie
//
//  Created by Alexander on 19.01.14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MeterTable : NSObject
{
    NSMutableArray* mTable;
}
- (float)valueAt:(float)inDecibels;
@end