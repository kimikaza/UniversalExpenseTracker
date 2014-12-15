//
//  UETCell.m
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 17/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import "UETCell.h"

@implementation UETCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
