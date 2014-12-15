//
//  UETCustomDateViewController.m
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 17/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import "UETCustomDateViewController.h"
#import "JVFloatLabeledTextField.h"
#import "UETNavigationViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface UETCustomDateViewController ()<UITextFieldDelegate>
{
    UITapGestureRecognizer *tapper;
    UITextField *activeField;
}
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *dateFromTextField;
@property (weak, nonatomic) IBOutlet JVFloatLabeledTextField *dateToTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation UETCustomDateViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.automaticallyAdjustsScrollViewInsets = NO;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIBarButtonItem *saveButton =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveData:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    UIBarButtonItem *settingsButton =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissSelf:)];
    self.navigationItem.leftBarButtonItem = settingsButton;//self.editButtonItem;

    [self registerForKeyboardNotifications];
    
    [self initTextFields];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Initializers

- (void)initTextFields
{
    self.dateFromTextField.placeholder = NSLocalizedString(@"INPUT_DATE_FROM", @"");
    self.dateToTextField.placeholder = NSLocalizedString(@"INPUT_DATE_TO",@"");
    self.dateFromTextField.inputView = [self datePickerView];
    self.dateToTextField.inputView = [self datePickerView];
    [self addShadowToView:self.dateToTextField];
    [self addShadowToView:self.dateFromTextField];

    if(_dateFrom && _dateTo){
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"dd.MM."];
        NSString *formattedDateFrom = [df stringFromDate:_dateFrom];
        NSString *formattedDateTo = [df stringFromDate:_dateTo];
        self.dateFromTextField.text = formattedDateFrom;
        self.dateToTextField.text = formattedDateTo;
        [(UIDatePicker *)self.dateFromTextField.inputView setDate:_dateFrom];
        [(UIDatePicker *)self.dateToTextField.inputView setDate:_dateTo];
    }
}

- (void)addShadowToView:(UIView *)textField
{
    textField.layer.masksToBounds = NO;
    textField.layer.shadowColor = [UIColor blackColor].CGColor;
    textField.layer.shadowOffset = CGSizeMake(5.0f, 5.0f);
    textField.layer.shadowOpacity = 1.0f;
    textField.layer.shadowRadius = 0;
}

- (UIView *)datePickerView
{
    UIDatePicker *dp = [[UIDatePicker alloc] init];
    [dp setDatePickerMode:UIDatePickerModeDate];
    [dp addTarget:self action:@selector(selectedDate:) forControlEvents:UIControlEventValueChanged];
    return dp;
}

#pragma mark - Date Picker changes

- (void)selectedDate:(id)sender
{
    UIDatePicker *dp = (UIDatePicker *)sender;
    NSDate *currentDate = dp.date;
    //geting just day componenets
    NSCalendar *calendar = [NSCalendar currentCalendar];
    if([activeField isEqual:_dateFromTextField]){
        NSDateComponents *components = [calendar components:(NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:currentDate];
        currentDate = [calendar dateFromComponents:components];
    }else{
        NSDateComponents *components = [calendar components:(NSYearCalendarUnit| NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:currentDate];
        [components setHour:23];
        [components setMinute:59];
        [components setSecond:59];
        
        currentDate = [calendar dateFromComponents:components];

    }
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd.MM."];
    NSString *formattedDate = [df stringFromDate:currentDate];
    if([activeField isEqual:_dateFromTextField]){
        self.dateFrom = currentDate;
        self.dateFromTextField.text = formattedDate;
    }else if([activeField isEqual:_dateToTextField]){
        self.dateTo = currentDate;
        self.dateToTextField.text = formattedDate;
    }
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


#pragma mark - UITextField delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    
    activeField = textField;
    if(textField.text.length==0){
        [self selectedDate:textField.inputView];
    }
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
    if([textField isEqual:_dateFromTextField])
        self.dateFrom = nil;
    else if([textField isEqual:_dateFromTextField])
        self.dateTo = nil;
    return YES;
}

#pragma mark - Handle genstures

- (void)handleSingleTap:(UITapGestureRecognizer *) sender
{
    [self.view endEditing:YES];
}

#pragma mark - Navigation Buttons pressed

- (void)dismissSelf:(id)sender
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [[(UETNavigationViewController *)self.navigationController  delegateModal] dismissModalScreen];
    }
}

- (void)saveData:(id)sender
{
    if([_dateFrom compare:_dateTo] == NSOrderedDescending){
        NSString *message = NSLocalizedString(@"DATE_FROM_LATE", @"");
        [self throwAlertTitle:nil message:message];
        return;
    }
    [self.delegate setCustomDates:_dateFrom endDate:_dateTo];
    [self dismissSelf:nil];
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





@end
