//
//  MetrtTable.m
//  MagicPie
//
//  Created by Alexander on 19.01.14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import "MetrtTable.h"

// I've rewrite C++ class to ObjC

#define mMinDecibels (-80.0)
#define mTableSize (800)
#define mDecibelResolution (mMinDecibels / (mTableSize - 1))
#define mScaleFactor (1. / mDecibelResolution)

@implementation MeterTable

- (id)init
{
    self = [super init];
    if(!self)return nil;
    
    float inMinDecibels = -80.0;
    int tableCount = 800;
    float inRoot = 1.5;
    
    double minAmp = [self dbToAmp:inMinDecibels];
	double ampRange = 1. - minAmp;
	double invAmpRange = 1. / ampRange;
    
	double rroot = 1.0 / inRoot;
    mTable = [NSMutableArray new];
	for (int i = 0; i < tableCount; i++) {
		double decibels = i * mDecibelResolution;
		double amp = [self dbToAmp:decibels];
		double adjAmp = (amp - minAmp) * invAmpRange;
		[mTable addObject:@(pow(adjAmp, rroot))];
	}
    
    return self;
}

- (double)dbToAmp:(double)inDb
{
	return pow(10., 0.05 * inDb);
}

- (float)valueAt:(float)inDecibels
{
    if (inDecibels < -80.0) return  0.;
    if (inDecibels >= 0.) return 1.;
    int index = (int)(inDecibels * mScaleFactor);
    return [mTable[index] floatValue];
}

@end

