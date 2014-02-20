//
//  UETCustomDateViewController.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 17/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UETCustomDateControllerDelegate <NSObject>

@required

-(void)setCustomDates:(NSDate *)startDate endDate:(NSDate *)endDate;

@end


@interface UETCustomDateViewController : UIViewController

@property (nonatomic, strong) NSDate *dateFrom;
@property (nonatomic, strong) NSDate *dateTo;

@property (nonatomic, weak) id<UETCustomDateControllerDelegate> delegate;

@end
