//
//  UETNavigationViewController.h
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 15/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UETNavigationControllerProtocol <NSObject>

@required
-(void)dismissModalScreen;

@end

@interface UETNavigationViewController : UINavigationController

@property (nonatomic, weak) id<UETNavigationControllerProtocol> delegateModal;

- (void)dismissSelf;

@end
