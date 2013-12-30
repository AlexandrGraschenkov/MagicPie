//
// NSMutableArray+pieEx.m
// MagicPie
//
// Created by Alexander on 27.12.13.
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

#import "NSMutableArray+pieEx.h"

@implementation NSMutableArray (pieEx)

- (void)sortWithIndexes:(NSArray*)indexes
{
    NSMutableArray* dataArray = [NSMutableArray array];
    for(int i = 0; i < indexes.count; i++){
        [dataArray addObject:@{@"Object" : self[i], @"Index" : indexes[i]}];
    }
    [dataArray sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"Index" ascending:YES]]];
    
    [self removeAllObjects];
    for(NSDictionary* dic in dataArray){
        [self addObject:dic[@"Object"]];
    }
}

- (void)insertSortedObjects:(NSArray*)objects indexes:(NSArray*)indexes
{
    for(int i = 0; i < indexes.count; i++){
        [self insertObject:objects[i] atIndex:[indexes[i] integerValue]];
    }
}

- (void)insertObjects:(NSArray*)objects indexes:(NSArray*)indexes
{
    NSMutableArray* mutObjects = [objects mutableCopy];
    [mutObjects sortWithIndexes:indexes];
    indexes = [indexes sortedArrayUsingSelector:@selector(compare:)];
    [self insertSortedObjects:mutObjects indexes:indexes];
}

// Ex: [@[@1, @2] updateIndexesWithUnusedIndexes:@[@2]] => @[@1, @3]
- (void)updateIndexesWithUnusedIndexes:(NSArray*)unusedIndexes
{
    unusedIndexes = [unusedIndexes sortedArrayUsingSelector:@selector(compare:)];
    int indexesCount = self.count;
    for(NSNumber* unusedIdxNum in unusedIndexes){
        int unusedIdx = unusedIdxNum.integerValue;
        for(int i = 0; i < indexesCount; i++){
            int idx = [self[i] integerValue];
            if(idx >= unusedIdx)
                self[i] = @(idx+1);
        }
    }
}

@end
