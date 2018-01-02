//
//  BarcodePreview.m
//  Barcode Scanner
//
//  Created by Rudolph, Aaron on 4/10/17.
//  Copyright © 2017 Aaron Rudolph. All rights reserved.
//

#import "BarcodePreview.h"

@implementation BarcodePreview

NSMutableArray * polylinePoints;

- (id) init
{
    if(self = [super init])
    {
        polylinePoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void) setBarcodePolyline:(NSArray *)points
{
    if(points == nil)
    {
        [polylinePoints removeAllObjects];
    }
    else
    {
        [polylinePoints setArray:points];
    }
    [self setNeedsDisplay];
}

- (void)drawInContext:(CGContextRef)context
{
    
    if([polylinePoints count] > 0)
    {
        CGMutablePathRef path = CGPathCreateMutable();
        CGContextSetLineWidth(context, 5.0);
        CGRect bounds = self.frame;
        
        for(int i = 0; i < [polylinePoints count]; i ++)
        {
            NSDictionary * coords = [polylinePoints objectAtIndex:i];
            CGPoint coord = CGPointMake(bounds.size.width - [((NSString*)[coords valueForKey:@"Y"]) floatValue] * (bounds.size.width - bounds.origin.y),
                                        [((NSString*)[coords valueForKey:@"X"]) floatValue] * (bounds.size.height - bounds.origin.x));
            
            if(i > 0)
            {
                CGPathAddLineToPoint(path, nil, coord.x, coord.y);
            }
            else
            {
                CGPathMoveToPoint(path, nil, coord.x, coord.y);
                CGContextBeginPath(context);
            }
        }
        NSDictionary * coords = [polylinePoints objectAtIndex:0];
        CGPoint coord = CGPointMake(bounds.size.width - [((NSString*)[coords valueForKey:@"Y"]) floatValue] * bounds.size.width, [((NSString*)[coords valueForKey:@"X"]) floatValue] * bounds.size.height);
        CGPathAddLineToPoint(path, nil, coord.x, coord.y);
        
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        
        CGContextAddPath(context, path);
        CGContextStrokePath(context);
        CFRelease(path);
     }
    else
    {
        CGContextAddPath(context, nil);
    }
}


@end
