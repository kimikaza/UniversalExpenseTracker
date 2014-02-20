//
//  DescriptionTag.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 18/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Expense;

@interface DescriptionTag : NSManagedObject

@property (nonatomic, retain) NSString * tag;
@property (nonatomic, retain) NSNumber * protected;
@property (nonatomic, retain) NSSet *expenses;
@end

@interface DescriptionTag (CoreDataGeneratedAccessors)

- (void)addExpensesObject:(Expense *)value;
- (void)removeExpensesObject:(Expense *)value;
- (void)addExpenses:(NSSet *)values;
- (void)removeExpenses:(NSSet *)values;

@end
