//
//  DetailViewController.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 14/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <UIKit/UIKit.h>
@class XYPieChart;

@interface DetailViewController : UIViewController 

@property (strong, nonatomic) id detailItem;

@property (weak, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@property (nonatomic, weak) IBOutlet XYPieChart *pieChart;
@property (nonatomic, strong) NSArray *sliceColors;
@property (nonatomic, strong) NSArray *slices;


@property (nonatomic, weak) IBOutlet UILabel *incomeAmountLabel;
@property (nonatomic, weak) IBOutlet UILabel *expenseAmountLabel;
@property (nonatomic, weak) IBOutlet UILabel *balanceAmountLabel;

@property (nonatomic, weak) IBOutlet UILabel *incomeLabel;
@property (nonatomic, weak) IBOutlet UILabel *expenseLabel;
@property (nonatomic, weak) IBOutlet UILabel *balanceLabel;

- (void)createPieChart;

@end
