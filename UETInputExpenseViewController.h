//
//  UETInputExpenseViewController.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 15/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Expense.h"

@protocol UETInputExpenseViewController <NSObject>

@required
-(void)dismissInputController;
@end

@interface UETInputExpenseViewController : UIViewController

@property (nonatomic, weak) id<UETInputExpenseViewController> delegate;

@property (nonatomic, strong) Expense *editedObject;

@end
