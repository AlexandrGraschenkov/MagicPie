//
//  ExamplePieView.h
//  MagicPie
//
//  Created by Alexandr on 10.10.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PieLayer, PieElement;

@interface Example1PieView : UIView
@property (nonatomic, copy) void(^elemTapped)(PieElement*);
@end

@interface Example1PieView (ex)
@property(nonatomic,readonly,retain) PieLayer *layer;
@end