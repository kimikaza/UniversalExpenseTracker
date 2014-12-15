//
//  UETTagManagementViewController.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 15/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//



#import <UIKit/UIKit.h>
@class DescriptionTag;

@protocol UETTagManagementViewControllerDelegate <NSObject>

@optional
- (void)tagSelected:(DescriptionTag *)tag;

@end

@interface UETTagManagementViewController : UITableViewController<NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (weak, nonatomic) id<UETTagManagementViewControllerDelegate> tagDelegate;

@end
