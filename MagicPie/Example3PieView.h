//
//  Example3PieView.h
//  MagicPie
//
//  Created by Alexander on 18.01.14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVAudioPlayer;
@interface Example3PieView : UIView
@property (nonatomic, strong) AVAudioPlayer* player;
@property (nonatomic, assign) BOOL enableCustomDrawing;
@end
