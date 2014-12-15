//
//  UETSimplePageRenderer.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 19/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#define HEADER_FONT_SIZE 10
#define HEADER_TOP_PADDING 5
#define HEADER_BOTTOM_PADDING 10
#define HEADER_RIGHT_PADDING 5
#define HEADER_LEFT_PADDING 5

#define FOOTER_FONT_SIZE 12
#define FOOTER_TOP_PADDING 10
#define FOOTER_BOTTOM_PADDING 5
#define FOOTER_RIGHT_PADDING 5
#define FOOTER_LEFT_PADDING 5

#import <UIKit/UIKit.h>

@interface UETSimplePageRenderer : UIPrintPageRenderer

@property (nonatomic, copy) NSString *headerText;
@property (nonatomic, copy) NSString *footerText;

- (void)drawHeaderForPageAtIndex:(NSInteger)pageIndex
                          inRect:(CGRect)headerRect;

- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex
                          inRect:(CGRect)footerRect;



@end
