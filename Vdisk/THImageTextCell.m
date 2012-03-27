//
//  THImageTextCell.m
//  Vdisk
//
//  Created by Hao Tan on 12/01/29.
//  Copyright (c) 2012年 tanhao. All rights reserved.
//

#import "THImageTextCell.h"

@implementation THImageTextCell
@synthesize image;

#define kIconImageSize		32
#define kIconButtonSize     32

#define kImageOriginXOffset 6
#define kTextOriginXOffset	6
#define kTextEndXOffset     12

#define kTextOffsetX        (20 + kImageOriginXOffset)

- (NSRect)imageRectForBounds:(NSRect)theRect
{
    if (image == nil)
        return NSZeroRect;
    
    // the cell has an image: draw the normal item cell
	NSSize imageSize;
	NSRect imageFrame;
    NSRect textFrame;
    
	imageSize = [image size];
	NSDivideRect(theRect, &imageFrame, &textFrame, kImageOriginXOffset + imageSize.width, NSMinXEdge);
	
    imageFrame.size = imageSize;
	imageFrame.origin.x += kImageOriginXOffset;
	imageFrame.origin.y += (theRect.size.height - imageSize.height)/2;
    
	return imageFrame;
}

- (NSRect)titleRectForBounds:(NSRect)theRect
{
    if (image == nil)
        return theRect;
    
    // the cell has an image: draw the normal item cell
	NSSize imageSize;
	NSRect imageFrame;
    NSRect textFrame;
    
	imageSize = [image size];
	NSDivideRect(theRect, &imageFrame, &textFrame, kImageOriginXOffset + imageSize.width, NSMinXEdge);
	
    NSSize textSize = [[self attributedStringValue] size];
	textFrame.origin.x += kTextOriginXOffset;
	textFrame.origin.y += (theRect.size.height - textSize.height)/2;
    //textFrame.size.height = textSize.height;
    //textFrame.size.width = textSize.width + kTextEndXOffset;
    
	return textFrame;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	if (image != nil)
	{
        // draw image
        [image setFlipped:[controlView isFlipped]];
        NSRect imageFrame = [self imageRectForBounds:cellFrame];
        [image drawInRect:imageFrame 
                 fromRect:NSZeroRect 
                operation:NSCompositeSourceOver 
                 fraction:1];
        
        // draw text
        NSAttributedString *title = [self attributedStringValue];
        NSRect titleRect = [self titleRectForBounds:cellFrame];   
        [title drawInRect:titleRect];
    }
	else
	{
        [super drawWithFrame:cellFrame inView:controlView];
	}
    
}

@end
