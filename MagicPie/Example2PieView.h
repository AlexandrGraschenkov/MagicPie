//
//  Example2PieView.h
//  MagicPie
//
//  Created by Alexander on 30.12.13.
//  Copyright (c) 2013 Alexandr Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PieLayer;

@interface Example2PieView : UIView
@property (nonatomic, assign) BOOL centerDisplace;
@end

@interface Example2PieView (ex)
@property(nonatomic,readonly,retain) PieLayer *layer;
@end