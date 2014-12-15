//
//  Expense.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 15/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DescriptionTag;

@interface Expense : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * amount;
@property (nonatomic, retain) NSString * comment;
@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) DescriptionTag *descriptionTag;

@end
