//
//  Example3PieElem.m
//  MagicPie
//
//  Created by Alexander on 19.01.14.
//  Copyright (c) 2014 Alexandr Corporation. All rights reserved.
//

#import "Example3PieLayer.h"

@implementation Example3PieLayer
@dynamic colorsArr, enableCustomDrawing;

- (void)drawElement:(PieElement *)elem context:(CGContextRef)ctx
{
    if(!self.enableCustomDrawing){
        [super drawElement:elem context:ctx];
        return;
    }
    
    if(self.colorsArr == 0)
        return;
    
    float const indent = 3.0;
    CGPoint centr = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    float endRadius = MIN(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    float startRadius = self.minRadius;
    
    NSUInteger lvlCount = self.colorsArr.count;
    float levelWidth = (endRadius - startRadius - (lvlCount-1)*indent) / lvlCount;
    float currRadius = startRadius;
    
    CGContextSetLineWidth(ctx, levelWidth);
    for(UIColor* color in self.colorsArr){
//        if(currRadius + levelWidth > self.maxRadius)
//            break;
        
        CGContextSetStrokeColorWithColor(ctx, color.CGColor);
        float lvlCentrRadius = currRadius + levelWidth/2.0;
        CGContextStrokeEllipseInRect(ctx, CGRectMake(centr.x - lvlCentrRadius, centr.y - lvlCentrRadius, 2*lvlCentrRadius, 2*lvlCentrRadius));
        currRadius += levelWidth + indent;
    }
}

@end
