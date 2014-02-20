//
//  MasterViewController.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 14/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DetailViewController;

#import <CoreData/CoreData.h>

@interface MasterViewController : UITableViewController <NSFetchedResultsControllerDelegate, UISplitViewControllerDelegate>

@property (strong, nonatomic) DetailViewController *detailViewController;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

-(void)openSettingsScreen:(id)sender;
-(void)fetchSums;

@end
