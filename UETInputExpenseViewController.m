//
//  UETInputExpenseViewController.m
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 15/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import "UETInputExpenseViewController.h"
#import "JVFloatLabeledTextField.h"
#import "UETNavigationViewController.h"
#import "UETTagManagementViewController.h"
#import "MasterViewController.h"
#import "AppDelegate.h"
#import "Expense.h"
#import "DescriptionTag.h"
#import <QuartzCore/QuartzCore.h>

@interface UETInputExpenseViewController ()<UITextFieldDelegate, UETTagManagementViewControllerDelegate>
{
    UITapGestureRecognizer *tapper;
    UITextField *activeField;
    NSDate *currentDate;
    BOOL income;
    DescriptionTag *descriptionTag;
    DescriptionTag *oldDescriptionTag;
}

@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *amount;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *dateAndTime;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *tagTextField;
@property (nonatomic, weak) IBOutlet JVFloatLabeledTextField *commentTextField;

@property (nonatomic, weak) IBOutlet UIButton *incomeButton;
@property (nonatomic, weak) IBOutlet UIButton *expenseButton;

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation UETInputExpenseViewController


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    UIBarButtonItem *saveButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveData:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    UIBarButtonItem *settingsButton =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissSelf:)];
    self.navigationItem.leftBarButtonItem = settingsButton;//self.editButtonItem;
    
    income = NO;
    
    [self getObjectContext];
    
    [self registerForKeyboardNotifications];
    
    [self initializeTapGestureRecognizer];
    
    [self initializeButtons];
    
    [self initializeTextFields];
    
    [self populateEditedData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation Buttons pressed

- (void)dismissSelf:(id)sender
{
    if ( self.editedObject || [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [(MasterViewController *)[self.navigationController.viewControllers firstObject] fetchSums];
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        
        [[(UETNavigationViewController *)self.navigationController  delegateModal] dismissModalScreen];
    }
}

- (void)saveData:(id)sender
{
    if([self checkData]){
        if(_editedObject){
            Expense *expense = _editedObject;
            NSString *amount = [_amount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
            double damount = [amount doubleValue];
            NSDecimalNumber *dnamount = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:damount];
            
            expense.amount = dnamount;
            NSDecimalNumber *minusOne = [NSDecimalNumber decimalNumberWithString:@"-1"];
            if(!income) expense.amount = [expense.amount decimalNumberByMultiplyingBy:minusOne];
            expense.timeStamp = currentDate;
            expense.comment = _commentTextField.text;
            expense.descriptionTag = descriptionTag;
            
            [oldDescriptionTag removeExpensesObject:expense];
            [descriptionTag removeExpensesObject:expense];
            [descriptionTag addExpensesObject:expense];
            
            // Save the context.
            NSError *error = nil;
            if (![_managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }else{
                [self dismissSelf:nil];
            }
        }else{
        
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:_managedObjectContext];
            Expense *expense = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:_managedObjectContext];

            NSString *amount = [_amount.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
            double damount = [amount doubleValue];
            NSDecimalNumber *dnamount = (NSDecimalNumber *)[NSDecimalNumber numberWithDouble:damount];
            
            expense.amount = dnamount;
            NSDecimalNumber *minusOne = [NSDecimalNumber decimalNumberWithString:@"-1"];
            if(!income) expense.amount = [expense.amount decimalNumberByMultiplyingBy:minusOne];
            expense.timeStamp = currentDate;
            expense.comment = _commentTextField.text;
            expense.descriptionTag = descriptionTag;
            
            [descriptionTag addExpensesObject:expense];

            // Save the context.
            NSError *error = nil;
            if (![_managedObjectContext save:&error]) {
                 // Replace this implementation with code to handle the error appropriately.
                 // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }else{
                [self dismissSelf:nil];
            }
        }
    }
}

#pragma mark - buttons pressed

- (IBAction)incomePressed:(id)sender
{
    income = YES;
    [self initializeButtons];
}

- (IBAction)expensePressed:(id)sender
{
    income = NO;
    [self initializeButtons];
}

#pragma mark - Keyboard and moving content in view

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGRect keyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self.view convertRect:keyboardRect fromView:self.view.window];
    
    CGSize kbSize = convertedFrame.size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbSize.height+10, 0.0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbSize.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        CGRect frame10PointsDown = activeField.frame;
        frame10PointsDown.origin.y +=10;
        [self.scrollView scrollRectToVisible:frame10PointsDown animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    [UIView animateWithDuration:0.3 animations:^{
        UIEdgeInsets contentInsets = UIEdgeInsetsZero;
        _scrollView.contentInset = contentInsets;
        _scrollView.scrollIndicatorInsets = contentInsets;
    }];
    
}

#pragma mark - initializers

- (void)initializeButtons
{
    if(income){
        [self.expenseButton setBackgroundColor:[UIColor whiteColor]];
        [self.expenseButton setTitleColor:kPieLila forState:UIControlStateNormal];
        [self.expenseButton setTintColor:kPieLila];
        [self.incomeButton setBackgroundColor:kPieGreen];
        [self.incomeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.incomeButton setTintColor:[UIColor whiteColor]];
    }else{
        [self.expenseButton setBackgroundColor:kPieLila];
        [self.expenseButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.expenseButton setTintColor:[UIColor whiteColor]];
        [self.incomeButton setBackgroundColor:[UIColor whiteColor]];
        [self.incomeButton setTitleColor:kPieGreen forState:UIControlStateNormal];
        [self.incomeButton setTintColor:kPieGreen];
    }
    
}

- (void)initializeTextFields
{
    self.amount.placeholder = NSLocalizedString(@"INPUT_VIEW__AMOUNT_PLACEHOLDER", @"");
    self.dateAndTime.placeholder = NSLocalizedString(@"INPUT_VIEW__DATE_AND_TIME_PLACEHOLDER",@"");
    self.dateAndTime.inputView = [self datePickerView];
    self.tagTextField.placeholder = NSLocalizedString(@"INPUT_VIEW__CHOOSE_TAG_PLACEHOLDER", @"");
    self.commentTextField.placeholder = NSLocalizedString(@"INPUT_VIEW__ENTER_COMMENT_PLACEHOLDER", @"");
    
    [self addShadowToView:self.amount];
    [self addShadowToView:self.dateAndTime];
    [self addShadowToView:self.tagTextField];
    [self addShadowToView:self.commentTextField];
//    [self addShadowToView:self.incomeButton];
//    [self addShadowToView:self.expenseButton];
}

- (void)addShadowToView:(UIView *)textField
{
    textField.layer.masksToBounds = NO;
    textField.layer.shadowColor = [UIColor blackColor].CGColor;
    textField.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
    textField.layer.shadowOpacity = 1.0f;
    textField.layer.shadowRadius = 0;
}

- (void)initializeTapGestureRecognizer
{
    tapper = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    tapper.cancelsTouchesInView = FALSE;
    [self.view addGestureRecognizer:tapper];
}

- (UIView *)datePickerView
{
    UIDatePicker *dp = [[UIDatePicker alloc] init];
    [dp setDatePickerMode:UIDatePickerModeDateAndTime];
    [dp addTarget:self action:@selector(selectedDate:) forControlEvents:UIControlEventValueChanged];
    [self selectedDate:dp];
    return dp;
}

- (void)getObjectContext
{
    AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    self.managedObjectContext = ad.managedObjectContext;
}

- (void)populateEditedData
{
    if(self.editedObject){
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"dd.MM    HH:mm"];
        NSString *formattedDate = [df stringFromDate:self.editedObject.timeStamp];
        [_dateAndTime setText:formattedDate];
        currentDate = self.editedObject.timeStamp;
        NSDecimalNumber *amount = self.editedObject.amount;
        NSDecimalNumber *minusOne = [NSDecimalNumber decimalNumberWithString:@"-1"];
        double damount = [amount doubleValue];
        if(damount<0){
            income = NO;
            amount = [amount decimalNumberByMultiplyingBy:minusOne];
        }else{
            income = YES;
        }
        [_amount setText:[amount stringValue]];
        _tagTextField.text = [self.editedObject.descriptionTag tag];
        _commentTextField.text = [self.editedObject comment];
        descriptionTag = self.editedObject.descriptionTag;
        oldDescriptionTag = self.editedObject.descriptionTag;
        [self initializeButtons];
    }
}

#pragma mark - TextFieldChangeValue

- (IBAction)textFieldChangeValue:(UITextField *)textField
{
    if(textField.text.length>25) textField.text = [textField.text substringWithRange:NSMakeRange(0, textField.text.length-1)];
}

#pragma mark - UITextField delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if([textField isEqual:_amount]){
        NSCharacterSet *nonAmount = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789,"] invertedSet];
        if([string rangeOfCharacterFromSet:nonAmount].location != NSNotFound){
            return NO;
        }
        BOOL textFieldHasComma = [textField.text rangeOfString:@","].location != NSNotFound;
        textFieldHasComma = textFieldHasComma || ([textField.text rangeOfString:@"."].location != NSNotFound);
        BOOL stringHasComma = [string rangeOfString:@","].location != NSNotFound;
        stringHasComma = stringHasComma || ([string rangeOfString:@"."].location != NSNotFound);
        if(textFieldHasComma && stringHasComma){
            return NO;
        }
        return YES;
        
    }if([textField isEqual:_commentTextField]){
        if(_commentTextField.text.length>=25 && ![string isEqualToString:@""]){
            return NO;
        }

    }
    return YES;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if([textField isEqual:_tagTextField]){
        UETTagManagementViewController *tagController = [self.storyboard instantiateViewControllerWithIdentifier:@"UETTagManagementViewController"];
        AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [tagController setManagedObjectContext:ad.managedObjectContext];
        [tagController setTagDelegate:self];
        [self.navigationController pushViewController:tagController animated:YES];
        return NO;
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField resignFirstResponder];
    activeField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    if([textField isEqual:_dateAndTime])
        currentDate = nil;
    return YES;
}

#pragma mark - CheckData

- (BOOL)checkData
{
    NSString *title;
    NSString *message;
    if(!currentDate){
        title = NSLocalizedString(@"DATA_CHECK_TITLE",@"");
        message = NSLocalizedString(@"DATA_CHECK_NO_DATE",@"");
    }
    if(!title && (!_amount.text || [_amount.text isEqualToString:@""])){
        title = NSLocalizedString(@"DATA_CHECK_TITLE",@"");
        message = NSLocalizedString(@"DATA_CHECK_NO_AMOUNT",@"");
    }
    if (!title && !descriptionTag) {
        title = NSLocalizedString(@"DATA_CHECK_TITLE",@"");
        message = NSLocalizedString(@"DATA_CHECK_NO_TAG",@"");
    }
    if(title && message){
        [self throwAlertTitle:title message:message];
        return NO;
    }
    return YES;
}

#pragma mark - Alert View

- (void)throwAlertTitle:(NSString *)title message:(NSString *)message
{
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                                 message:message
                                                delegate:nil
                                       cancelButtonTitle:NSLocalizedString(@"OK", @"")
                                       otherButtonTitles:nil];
    [av show];
}

#pragma mark - Date Picker changes

- (void)selectedDate:(id)sender
{
    UIDatePicker *dp = (UIDatePicker *)sender;
    currentDate = dp.date;
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd.MM.    HH:mm"];
    NSString *formattedDate = [df stringFromDate:currentDate];
    [_dateAndTime setText:formattedDate];
}

#pragma mark - Handle genstures

- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}


#pragma mark - UETTagManagementViewControllerDelegate

- (void)tagSelected:(DescriptionTag *)tag
{
    descriptionTag = tag;
    [self.tagTextField setText:tag.tag];
}

@end
