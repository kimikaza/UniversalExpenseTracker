//
//  UETPrintPageRenderer.m
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 18/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import "UETPrintPageRenderer.h"
#import "Expense.h"
#import "DescriptionTag.h"
#import <CoreText/CoreText.h>


static CGFloat const ROW_HEIGHT = 30;

@implementation UETPrintPageRenderer

- (NSInteger)numberOfPages{
    
    self.rowsPerPage = floorf(self.printableRect.size.height/ROW_HEIGHT);
    
    NSInteger numPages = ceilf((float)self.numberOfRows / (float)self.rowsPerPage);
    
    return numPages;

}

- (void)drawContentForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)contentRect
{
    UIRectClip(contentRect);
    for (int i = 0; i< self.rowsPerPage; i++) {
        if( (pageIndex*self.rowsPerPage + i)>=self.numberOfRows ) return;
        [self drawTextAtIndex:pageIndex*self.rowsPerPage + i atOffset:CGPointMake(contentRect.origin.x, contentRect.origin.y+i*ROW_HEIGHT) inRect:contentRect];
    }
}

- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)footerRect{
    UIRectClip(footerRect);
    [self drawTextAtIndex:(pageIndex + 1) inRect:footerRect];
}

//not
- (void)drawTextAtIndex:(NSInteger)index atOffset:(CGPoint)offset inRect:(CGRect)contentRect{
    Expense *expense = _data[index];
    NSString *date = [self formatDate:[expense timeStamp]];
    NSString *time = [self formatTime:[expense timeStamp]];
    NSString *amount = [expense.amount stringValue];
    NSString *tag = expense.descriptionTag.tag;
    NSString *comment = expense.comment;
    NSString *row = [NSString stringWithFormat:@"%@\t\t%@\t\t%@\t\t%@\t\t%@",date, time, amount, tag, comment];
    CGContextRef context =  UIGraphicsGetCurrentContext();
    
    CFStringRef rowRef= (__bridge CFStringRef)row;
    CFAttributedStringRef currentText = CFAttributedStringCreate(NULL, rowRef, NULL);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(currentText);
    
    CGRect frameRect = CGRectMake(0+offset.x, contentRect.size.height-30-offset.y, contentRect.size.width, 30);
    CGMutablePathRef framePath = CGPathCreateMutable();
    CGPathAddRect(framePath, NULL, frameRect);
    
    CFRange currentRange = CFRangeMake(0, 0);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, NULL);
    CGPathRelease(framePath);
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, contentRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CTFrameDraw(frameRef, context);
    CGContextRestoreGState(context);
    
    CFRelease(frameRef);
    CFRelease(rowRef);
    CFRelease(framesetter);
    
}

- (void)drawTextAtIndex:(NSInteger)index inRect:(CGRect)contentRect
{
    NSString *page = [NSString stringWithFormat:@"page %d",(int)index];
    CGContextRef context =  UIGraphicsGetCurrentContext();
    
    CFStringRef rowRef= (__bridge CFStringRef)page;
    CFAttributedStringRef currentText = CFAttributedStringCreate(NULL, rowRef, NULL);
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString(currentText);
    
    CGRect frameRect = CGRectMake(contentRect.origin.x, 0, 300, 30);
    CGMutablePathRef framePath = CGPathCreateMutable();
    CGPathAddRect(framePath, NULL, frameRect);
    
    CFRange currentRange = CFRangeMake(0, 0);
    CTFrameRef frameRef = CTFramesetterCreateFrame(framesetter, currentRange, framePath, NULL);
    CGPathRelease(framePath);
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, contentRect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CTFrameDraw(frameRef, context);
    CGContextRestoreGState(context);
    
    CFRelease(frameRef);
    CFRelease(rowRef);
    CFRelease(framesetter);

}

-(NSString *)formatDate:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd.MM."];
    return [df stringFromDate:date];
}

-(NSString *)formatTime:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm"];
    return [df stringFromDate:date];
}

@end
