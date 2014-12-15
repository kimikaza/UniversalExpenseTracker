//
//  UETSimplePageRenderer.m
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 19/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import "UETSimplePageRenderer.h"

@implementation UETSimplePageRenderer

- (void)setHeaderText:(NSString *)newString {
    
    if (_headerText != newString) {
        _headerText = [newString copy];
        
        
        if (_headerText) {
            //UIFont *font = [UIFont fontWithName:@"AvenirNextCondensed-Regular" size:HEADER_FONT_SIZE];
            UIFont *font = [UIFont fontWithName:@"Courier-Bold" size:HEADER_FONT_SIZE];
            NSDictionary *attrs = @{NSFontAttributeName:font};
            CGSize size = [_headerText sizeWithAttributes:attrs];
            self.headerHeight = size.height + HEADER_TOP_PADDING + HEADER_BOTTOM_PADDING;
        }
    }
}

- (void)drawHeaderForPageAtIndex:(NSInteger)pageIndex
                          inRect:(CGRect)headerRect {
    
    if (self.headerText) {
        UIFont *font = [UIFont fontWithName:@"Courier"
                                       size:HEADER_FONT_SIZE];
        NSDictionary *attrs = @{NSFontAttributeName:font};
        CGSize size = [_headerText sizeWithAttributes:attrs];
        
        // Center Text
//        CGFloat drawX = CGRectGetMaxX(headerRect)/2 - size.width/2;
//        CGFloat drawY = CGRectGetMaxY(headerRect) - size.height -
//        HEADER_BOTTOM_PADDING;
        CGFloat drawX = headerRect.origin.x + HEADER_LEFT_PADDING;
        CGFloat drawY = CGRectGetMaxY(headerRect) - size.height - HEADER_BOTTOM_PADDING;
        
        CGPoint drawPoint = CGPointMake(drawX, drawY);
        [self.headerText drawAtPoint:drawPoint withAttributes:attrs];
    }
}

- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex
                          inRect:(CGRect)footerRect {
    
    UIFont *font = [UIFont fontWithName:@"Courier-Bold" size:FOOTER_FONT_SIZE];
    NSString *pageNumber = [NSString stringWithFormat:@"- %d -", pageIndex+1];
    NSDictionary *attrs = @{NSFontAttributeName:font};
    CGSize size = [pageNumber sizeWithAttributes:attrs];
    CGFloat drawX = CGRectGetMaxX(footerRect)/2 - size.width/2;
    CGFloat drawY = CGRectGetMaxY(footerRect) - size.height - FOOTER_BOTTOM_PADDING;
    CGPoint drawPoint = CGPointMake(drawX, drawY);
    [pageNumber drawAtPoint:drawPoint withAttributes:attrs];
    
    
    if (self.footerText) {
        size = [self.footerText sizeWithAttributes:attrs];
        drawX = CGRectGetMaxX(footerRect) - size.width - FOOTER_RIGHT_PADDING;
        drawPoint = CGPointMake(drawX, drawY);
        [self.footerText drawAtPoint:drawPoint withAttributes:attrs];
    }
}

@end
