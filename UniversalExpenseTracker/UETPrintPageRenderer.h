//
//  UETPrintPageRenderer.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 18/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Expense.h"

@interface UETPrintPageRenderer : UIPrintPageRenderer

@property (nonatomic, assign) NSInteger rowsPerPage;
@property (nonatomic, assign) NSInteger numberOfRows;
@property (nonatomic, assign) NSArray *data;

//new
- (void)drawTextAtIndex:(NSInteger)index
               atOffset:(CGPoint)offset
                 inRect:(CGRect)contentRect;

- (void)drawTextAtIndex:(NSInteger)index inRect:(CGRect)contentRect;

//overrides
- (NSInteger)numberOfPages;
- (void)drawContentForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)contentRect;
- (void)drawFooterForPageAtIndex:(NSInteger)pageIndex inRect:(CGRect)footerRect;

@end
