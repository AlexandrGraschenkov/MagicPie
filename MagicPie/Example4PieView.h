//
//  Example4PieView.h
//  MagicPie
//
//  Created by Madusha Perera on 6/2/14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PieLayer;

@interface Example4PieView : UIView

@end

@interface Example4PieView (ex)
@property(nonatomic,readonly,retain) PieLayer *layer;

@end