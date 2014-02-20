//
//  UETCell.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 17/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UETCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *date;
@property (nonatomic, weak) IBOutlet UILabel *time;
@property (nonatomic, weak) IBOutlet UILabel *tagLabel;
@property (nonatomic, weak) IBOutlet UILabel *amount;
@property (nonatomic, weak) IBOutlet UILabel *comment;

@property (nonatomic, weak) IBOutlet UIView *dateView;
@property (nonatomic, weak) IBOutlet UIView *timeView;
@property (nonatomic, weak) IBOutlet UIView *tagLabelView;
@property (nonatomic, weak) IBOutlet UIView *amountView;

@end
