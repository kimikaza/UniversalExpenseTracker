//
//  MasterViewController.m
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 14/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import "MasterViewController.h"

#import "DetailViewController.h"
#import "UETNavigationViewController.h"
#import "UETInputExpenseViewController.h"
#import "UETCustomDateViewController.h"
#import "UETTagManagementViewController.h"


#import "AppDelegate.h"
#import "Expense.h"
#import "DescriptionTag.h"
#import "UETCell.h"
#import "XYPieChart.h"
#import "UETPrintPageRenderer.h"
#import "UETSimplePageRenderer.h"

typedef NS_ENUM(NSInteger, UETFilterType) {
    UETFilterTypeNone,
    UETFilterTypeThisWeek,
    UETFilterTypeThisMonth,
    UETFilterTypeThisYear,
    UETFilterTypeCustomDate,
    UETFilterTypeIncome,
    UETFilterTypeExpense,
    UETFilterTypeTag
};

@interface MasterViewController ()<UETNavigationControllerProtocol, UIActionSheetDelegate, UETCustomDateControllerDelegate, UETTagManagementViewControllerDelegate, XYPieChartDelegate, XYPieChartDataSource, UIDynamicAnimatorDelegate>
{
    NSDecimalNumber *currentIncomeAmount;
    NSDecimalNumber *currentExpenseAmount;
    UILabel *incomeAmountLabel;
    UILabel *expenseAmountLabel;
    UILabel *balanceAmountLabel;
    UIDynamicAnimator *animator;
    UISnapBehavior *snap;
    UICollisionBehavior* collision;
    
    UIImageView *pieIcon;
    
    BOOL pieChartUp;
    
    BOOL customDateScreenOn;
}

@property (nonatomic, assign) UETFilterType filterType;
@property (nonatomic, strong) NSDate *dateFrom;
@property (nonatomic, strong) NSDate *dateTo;
@property (nonatomic, strong) DescriptionTag *tagObject;

@property (nonatomic, strong) UIView *pieChartView;
@property (nonatomic, strong) XYPieChart *pieChart;
@property (nonatomic, strong) NSArray *sliceColors;
@property (nonatomic, strong) NSArray *slices;

@property (strong, nonatomic) UIPopoverController *masterPopoverController;

- (void)configureCell:(UETCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MasterViewController

- (void)awakeFromNib
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.clearsSelectionOnViewWillAppear = NO;
        self.preferredContentSize = CGSizeMake(320.0, 600.0);
    }
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    
    [self restoreFilterDataFromDefaults];
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    pieChartUp = NO;
    self.slices = [[NSArray alloc] init];
    
    customDateScreenOn = NO;
    
    
    
    if([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad){
        UIBarButtonItem *settingsButton =
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openPrintScreen:)];
        self.navigationItem.leftBarButtonItem = settingsButton;
    }else{
        self.detailViewController = (DetailViewController *)[[self.splitViewController.viewControllers firstObject] topViewController];
    }

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    [self prepareFilterView];
    if (![[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        [self initializePieChartView];
    
    [self setTableInsets];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(self.filterType != UETFilterTypeNone){
        [self filterData];
    }
}

- (void)setTableInsets
{
    UIEdgeInsets tblInsets = [self.tableView contentInset];
    tblInsets.bottom = 35;
    [self.tableView setContentInset:tblInsets];
}


#pragma mark - Navigation buttons reactions

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UETInputExpenseViewController *inputExpenseViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UETInputExpenseViewController"];
        [self.navigationController pushViewController:inputExpenseViewController animated:YES];
    }else{
        //show modally on iPhone
        UETNavigationViewController *modalNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"InputNavigationController"];
        modalNavController.delegateModal = self;
        [self presentViewController:modalNavController animated:YES completion:nil];
    }
}

- (void)dismissModalScreen{
    [self dismissViewControllerAnimated:YES completion:^{
        customDateScreenOn = NO;
        [self fetchSums];
        [self.pieChart reloadData];
    }];
    
}

#pragma mark - Printing

-(void)openPrintScreen:(id)sender{
    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.jobName = @"Expense Tracker";
    [printInfo setOrientation:UIPrintInfoOrientationPortrait];
    [printInfo setOutputType:UIPrintInfoOutputGeneral];
    [printController setPrintInfo:printInfo];
    
    NSMutableAttributedString *printData = [self prepareContentPrintString];
    
    UISimpleTextPrintFormatter *printFormatter = [[UISimpleTextPrintFormatter alloc] initWithAttributedText:printData];
    UETSimplePageRenderer *pageRenderer = [[UETSimplePageRenderer alloc] init];
    [pageRenderer addPrintFormatter:printFormatter startingAtPageAtIndex:0];
    //use proportional font with this :)
    NSString *headerText = @"DATE AND TIME           AMOUNT      DESCRIPTION              COMMENT";
    [pageRenderer setHeaderText:headerText];
    [pageRenderer setFooterHeight:30];
    
    [printController setPrintPageRenderer:pageRenderer];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [printController presentFromBarButtonItem:self.detailViewController.navigationItem.leftBarButtonItem animated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
            //
        }];
    }else{
        [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
            //
        }];
    }
}

-(NSMutableAttributedString *)prepareContentPrintString
{
    NSMutableAttributedString *printData = [[NSMutableAttributedString alloc] init];
    double runIncome = 0;
    double runExpense = 0;
    double runBalance = 0;
    NSInteger runNumOfDates = 0;
    NSInteger currentWeekOfYear = -1;
    NSDate *lastDate;
    for (Expense *expense in [[_fetchedResultsController fetchedObjects] reverseObjectEnumerator]) {
        NSInteger dateWeekOfYear = [self getWeekOfYearForDate:expense.timeStamp];
        if(dateWeekOfYear != currentWeekOfYear){
            if(currentWeekOfYear!=-1){
                NSAttributedString *summaryAttr = [self makeARowFromIncome:runIncome Expense:runExpense Balance:runBalance NumOfDates:runNumOfDates];
                [printData appendAttributedString:summaryAttr];
            }
            runIncome = 0;
            runExpense = 0;
            runBalance = 0;
            runNumOfDates = 0;
            currentWeekOfYear = dateWeekOfYear;
        }
        if([self differentDay:expense.timeStamp lastDate:lastDate]){
            runNumOfDates++;
            lastDate = expense.timeStamp;
        }
        if([expense.amount doubleValue]>0){
            runIncome += [expense.amount doubleValue];
        }else{
            runExpense += [expense.amount doubleValue];
        }
        runBalance += [expense.amount doubleValue];
        
        NSAttributedString *rowAttr = [self makeARowFromExpense:expense];
        [printData appendAttributedString:rowAttr];
    }
    if(runNumOfDates>0){
        NSAttributedString *summaryAttr = [self makeARowFromIncome:runIncome Expense:runExpense Balance:runBalance NumOfDates:runNumOfDates];
        [printData appendAttributedString:summaryAttr];
    }
    return printData;
}

- (BOOL)differentDay:(NSDate *)currentDate lastDate:(NSDate *)lastDate
{
    if (!lastDate) {
        return YES;
    }
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *comp1 = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:currentDate];
    NSDateComponents *comp2 = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:lastDate];
    if([comp1 day] != [comp2 day]) return YES;
    if([comp1 month] != [comp2 month]) return YES;
    if([comp1 year] != [comp2 year]) return YES;
    return NO;
}

- (NSAttributedString *)makeARowFromIncome:(double)income Expense:(double)expense Balance:(double)balance NumOfDates:(NSInteger)numOfDates
{
    NSString *incomeString = [[NSString alloc] initWithFormat:@"%0.02f", income];
    NSString *expenseString = [[NSString alloc] initWithFormat:@"%0.02f", expense];
    NSString *balanceString = [[NSString alloc] initWithFormat:@"%0.02f", balance];
    
    double averageDaily = expense/7.0f;
    NSString *averageDailyString = [[NSString alloc] initWithFormat:@"%0.02f", averageDaily];
    NSString *weeklyString = @"\nWEEKLY STATISTICS:\n";
    
    NSString *row = [NSString stringWithFormat:@"INCOME: %@ EXPENSE: %@ BALANCE: %@ AVG. DAILY SPENDING: %@\n\n",
                      incomeString, expenseString, balanceString, averageDailyString];
    UIFont *font = [UIFont fontWithName:@"Courier" size:10];
    NSDictionary *attributesForString1 = @{NSFontAttributeName:font};
    NSDictionary *attributesForString2 = @{NSFontAttributeName:font, NSUnderlineStyleAttributeName:@1};
    NSAttributedString *weekAttr = [[NSAttributedString alloc] initWithString:weeklyString attributes:attributesForString1];
    NSAttributedString *rowAttr = [[NSAttributedString alloc] initWithString:row attributes:attributesForString2];
    NSMutableAttributedString *mutAttr = [[NSMutableAttributedString alloc] init];
    [mutAttr appendAttributedString:weekAttr];
    [mutAttr appendAttributedString:rowAttr];
    return mutAttr;

}

- (NSAttributedString *)makeARowFromExpense:(Expense *)expense
{
    NSString *date = [self formatDate:[expense timeStamp]];
    NSString *time = [self formatTime:[expense timeStamp]];
    NSString *amount = [expense.amount stringValue];
    NSString *tag = expense.descriptionTag.tag;
    NSString *comment = expense.comment;
    date = [self rightPadedString:date Long:16];
    time = [self rightPadedString:time Long:8];
    amount = [self rightPadedString:amount Long:12];
    tag = [self rightPadedString:tag Long:25];
    
    NSString *row = [NSString stringWithFormat:@"%@%@%@%@%@\n",date, time, amount, tag, comment];
    UIFont *font = [UIFont fontWithName:@"Courier" size:10];
    NSDictionary *attributesForString = @{NSFontAttributeName:font};
    NSAttributedString *rowAttr = [[NSAttributedString alloc] initWithString:row attributes:attributesForString];
    return rowAttr;
}

- (NSInteger)getWeekOfYearForDate:(NSDate *)date
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    [calendar setTimeZone:[NSTimeZone systemTimeZone]];
    NSDateComponents *dateComponents = [calendar components:NSWeekOfYearCalendarUnit fromDate:date];
    return [dateComponents weekOfYear];
}

- (NSString *)rightPadedString:(NSString *)string Long:(NSInteger)length
{
    if(string.length<length){
        NSInteger paddingLength = length - string.length;
        NSMutableString *mutoString = [[NSMutableString alloc] initWithString:string];
        for (int i=0; i<paddingLength; i++) {
            [mutoString appendString:@" "];
        }
        return mutoString;
    }
    return string;
}

-(NSString *)formatDate:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEE dd.MM.yyyy"];
    return [df stringFromDate:date];
}

-(NSString *)formatTime:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm"];
    return [df stringFromDate:date];
}

#pragma mark - initializing user data

- (void)restoreFilterDataFromDefaults
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *filter = [defaults objectForKey:@"filterType"];
    if(filter){
        self.filterType = [filter integerValue];
    }else{
        self.filterType = UETFilterTypeNone;
    }
    self.dateFrom = [defaults objectForKey:@"dateFrom"];
    self.dateTo = [defaults objectForKey:@"dateTo"];
    NSString *tagString = [defaults objectForKey:@"tagString"];
    
    
    //FETCH tag object
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DescriptionTag" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    NSPredicate *predicate  = [NSPredicate predicateWithFormat:@"tag = %@", tagString];
    [fetchRequest setPredicate:predicate];
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    if(results.count > 0)
        self.tagObject = results[0];
    
}

- (void)saveDefaultFilterData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:[NSNumber numberWithInteger:_filterType] forKey:@"filterType"];
    [defaults setObject:_dateFrom forKey:@"dateFrom"];
    [defaults setObject:_dateTo forKey:@"dateTo"];
    [defaults setObject:_tagObject.tag forKey:@"tagString"];
    [defaults synchronize];
}

- (void)prepareFilterView
{
    UIButton *titleButton = (UIButton *)self.navigationItem.titleView;
    [titleButton setBackgroundColor:kGreen1];
    [titleButton setTitleColor:kDateHeaderText forState:UIControlStateNormal];
    NSString *title;
    switch (_filterType) {
        case UETFilterTypeNone:
            title = NSLocalizedString(@"FILTER_NONE",@"");
            break;
        case UETFilterTypeThisWeek:
            title = NSLocalizedString(@"FILTER_THIS_WEEK",@"");
            break;
        case UETFilterTypeThisMonth:
            title = NSLocalizedString(@"FILTER_THIS_MONTH",@"");
            break;
        case UETFilterTypeThisYear:
            title = NSLocalizedString(@"FILTER_THIS_YEAR",@"");
            break;
        case UETFilterTypeCustomDate:
            title = [self getTitleFromDateFrom:_dateFrom andDateTo:_dateTo];
            break;
        case UETFilterTypeIncome:
            title = NSLocalizedString(@"FILTER_INCOME",@"");
            break;
        case UETFilterTypeExpense:
            title = NSLocalizedString(@"FILTER_EXPENSE",@"");
            break;
        case UETFilterTypeTag:
            title = self.tagObject.tag;
            break;
        default:
            break;
    }
    [titleButton setTitle:title forState:UIControlStateNormal];
    [self.navigationController.navigationBar setNeedsLayout];
}

#pragma mark - Filter Button action

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    [actionSheet.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL *stop) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            button.titleLabel.textColor = kGray4;
            NSString *buttonText = button.titleLabel.text;
            if ([buttonText isEqualToString:NSLocalizedString(@"Cancel", nil)]) {
                button.titleLabel.textColor = kLila1;
            }
        }
    }];
}

- (IBAction) filterPressed:(id)sender
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"FILTER_NONE", @"")
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"CANCEL",@"")
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:NSLocalizedString(@"FILTER_ALL", @""),
                                                             NSLocalizedString(@"FILTER_THIS_WEEK", @""),
                                                             NSLocalizedString(@"FILTER_THIS_MONTH",@""),
                                                             NSLocalizedString(@"FILTER_THIS_YEAR",@""),
                                                             NSLocalizedString(@"FILTER_CUSTOM_DATE",@""),
                                                             NSLocalizedString(@"FILTER_INCOME",@""),
                                                             NSLocalizedString(@"FILTER_EXPENSE",@""),
                                                             NSLocalizedString(@"FILTER_TAG",@""),
                         nil];
    [as showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_ALL", @"")]){
        self.filterType = UETFilterTypeNone;
        self.dateFrom = nil;
        self.dateTo = nil;
        self.tagObject = nil;
        [self filterData];
    }else if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_THIS_WEEK", @"")]){
        self.filterType = UETFilterTypeThisWeek;
        self.dateFrom = [self thisWeekStartDate];
        self.dateTo = nil;
        self.tagObject = nil;
        [self filterData];
    }else if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_THIS_MONTH", @"")]){
        self.filterType = UETFilterTypeThisMonth;
        self.dateFrom = [self thisMonthStartDate];
        self.dateTo = nil;
        self.tagObject = nil;
        [self filterData];
    }else if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_THIS_YEAR", @"")]){
        self.filterType = UETFilterTypeThisYear;
        self.dateFrom = [self thisYearStartDate];
        self.dateTo = nil;
        self.tagObject = nil;
        [self filterData];
    }else if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_CUSTOM_DATE", @"")]){
        customDateScreenOn = YES;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UETCustomDateViewController *customDateViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"UETCustomDateViewController"];
            if(self.filterType == UETFilterTypeCustomDate){
                [customDateViewController setDateFrom:_dateFrom];
                [customDateViewController setDateTo:_dateTo];
            }
            customDateViewController.delegate = self;
            [self.navigationController pushViewController:customDateViewController animated:YES];
        }else{
            //show modally on iPhone
            UETNavigationViewController *modalNavController = [self.storyboard instantiateViewControllerWithIdentifier:@"CustomDateNavigationController"];
            modalNavController.delegateModal = self;
            if(self.filterType == UETFilterTypeCustomDate){
                [(UETCustomDateViewController *)modalNavController.topViewController setDateFrom:_dateFrom];
                [(UETCustomDateViewController *)modalNavController.topViewController setDateTo:_dateTo];
            }
            [(UETCustomDateViewController *)modalNavController.topViewController setDelegate:self];
            [self presentViewController:modalNavController animated:YES completion:nil];
        }
    }else if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_INCOME", @"")]){
        self.filterType = UETFilterTypeIncome;
        self.dateFrom = nil;
        self.dateTo = nil;
        self.tagObject = nil;
        [self filterData];
    }else if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_EXPENSE", @"")]){
        self.filterType = UETFilterTypeExpense;
        self.dateFrom = nil;
        self.dateTo = nil;
        self.tagObject = nil;
        [self filterData];
    }else if([buttonTitle isEqualToString:NSLocalizedString(@"FILTER_TAG", @"")]){
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UETTagManagementViewController *tagController = [self.storyboard instantiateViewControllerWithIdentifier:@"UETTagManagementViewController"];
            AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [tagController setManagedObjectContext:ad.managedObjectContext];
            [tagController setTagDelegate:self];
            [self.navigationController pushViewController:tagController animated:YES];
        }else{
            UETTagManagementViewController *tagController = [self.storyboard instantiateViewControllerWithIdentifier:@"UETTagManagementViewController"];
            AppDelegate *ad = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [tagController setManagedObjectContext:ad.managedObjectContext];
            [tagController setTagDelegate:self];
            [self.navigationController pushViewController:tagController animated:YES];
        }
        
    }
    [self prepareFilterView];
    [self saveDefaultFilterData];
}

// Finds the date for the first day of the week
- (NSDate *)thisWeekStartDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setFirstWeekday:2];
    NSDate *today = [NSDate date];
    NSDate *beginningOfWeek = nil;
    BOOL ok = [gregorian rangeOfUnit:NSWeekCalendarUnit startDate:&beginningOfWeek
                            interval:NULL forDate: today];
    if(ok)
        return beginningOfWeek;
    else
        return nil;
}

// Finds the date for the first day of the month
- (NSDate *)thisMonthStartDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setFirstWeekday:2];
    NSDate *today = [NSDate date];
    NSDate *beginningOfMonth = nil;
    BOOL ok = [gregorian rangeOfUnit:NSMonthCalendarUnit startDate:&beginningOfMonth
                            interval:NULL forDate: today];
    if(ok)
        return beginningOfMonth;
    else
        return nil;
}

// Finds the date for the first day of the year
- (NSDate *)thisYearStartDate
{
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setFirstWeekday:2];
    NSDate *today = [NSDate date];
    NSDate *beginningOfYear = nil;
    BOOL ok = [gregorian rangeOfUnit:NSYearCalendarUnit startDate:&beginningOfYear
                            interval:NULL forDate: today];
    if(ok)
        return beginningOfYear;
    else
        return nil;
}

#pragma mark - deleagate of Custom Date View Controller
-(void)setCustomDates:(NSDate *)startDate endDate:(NSDate *)endDate
{
    if(startDate && endDate){
        self.dateFrom = startDate;
        self.dateTo = endDate;
        self.filterType = UETFilterTypeCustomDate;
        self.tagObject = nil;
        [self filterData];
    }
    [self prepareFilterView];
    [self saveDefaultFilterData];
}

- (NSString *)getTitleFromDateFrom:(NSDate *)startDate andDateTo:(NSDate *)endDate
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"dd.MM."];
    NSString *dateFromString = [df stringFromDate:startDate];
    NSString *dateToString = [df stringFromDate:endDate];
    NSString *title = [NSString stringWithFormat:@"%@ - %@", dateFromString, dateToString];
    return title;
}


#pragma mark - Delegate of Tag Management View Controller
- (void)tagSelected:(DescriptionTag *)tag{
    self.filterType = UETFilterTypeTag;
    self.dateFrom = nil;
    self.dateTo = nil;
    self.tagObject = tag;
    [self prepareFilterView];
    [self saveDefaultFilterData];
    [self filterData];
}


#pragma mark - Table View

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 25;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [[UIView alloc] init];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [headerView setFrame:CGRectMake(0, 0, 703, 25)];
    }else{
        [headerView setFrame:CGRectMake(0, 0, 320, 25)];
    }
    [headerView setBackgroundColor:kGray1];
    
    UILabel *dateLabel = [[UILabel alloc] init];
    UILabel *timeLabel = [[UILabel alloc] init];
    UILabel *tagLabel = [[UILabel alloc] init];
    UILabel *amountLabel = [[UILabel alloc] init];
    
    dateLabel.text = NSLocalizedString(@"LABEL_DATE", @"");
    timeLabel.text = NSLocalizedString(@"LABEL_TIME", @"");
    tagLabel.text = NSLocalizedString(@"LABEL_TAG", @"");
    amountLabel.text = NSLocalizedString(@"LABEL_AMOUNT", @"");
    
    dateLabel.textAlignment = NSTextAlignmentCenter;
    timeLabel.textAlignment = NSTextAlignmentCenter;
    tagLabel.textAlignment = NSTextAlignmentCenter;
    amountLabel.textAlignment = NSTextAlignmentCenter;
    
    [dateLabel setBackgroundColor:kGray1];
    [timeLabel setBackgroundColor:kGray2];
    [tagLabel setBackgroundColor:kGray3];
    [amountLabel setBackgroundColor:kGray4];
    
    [dateLabel setTextColor:kGrayText];
    [timeLabel setTextColor:kGrayText];
    [tagLabel setTextColor:kGrayText];
    [amountLabel setTextColor:kGrayText];
    
    UIFont *font = [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:14];
    [dateLabel setFont:font];
    [timeLabel setFont:font];
    [tagLabel setFont:font];
    [amountLabel setFont:font];
    
    [headerView addSubview:dateLabel];
    [headerView addSubview:timeLabel];
    [headerView addSubview:tagLabel];
    [headerView addSubview:amountLabel];
    
    dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    tagLabel.translatesAutoresizingMaskIntoConstraints = NO;
    amountLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSDictionary *views = NSDictionaryOfVariableBindings(headerView, dateLabel, timeLabel, tagLabel, amountLabel);
    NSArray *cons1;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        cons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"|[dateLabel(==150)][timeLabel(==150)][tagLabel][amountLabel(==150)]|" options:0 metrics:nil views:views];
    }else{
        cons1 = [NSLayoutConstraint constraintsWithVisualFormat:@"|[dateLabel(==70)][timeLabel(==70)][tagLabel][amountLabel(==90)]|" options:0 metrics:nil views:views];
    }
    NSArray *cons2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[dateLabel]|" options:0 metrics:nil views:views];
    NSArray *cons3 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[timeLabel]|" options:0 metrics:nil views:views];
    NSArray *cons4 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tagLabel]|" options:0 metrics:nil views:views];
    NSArray *cons5 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[amountLabel]|" options:0 metrics:nil views:views];
    
    cons1 = [[cons1 arrayByAddingObjectsFromArray:cons2] arrayByAddingObjectsFromArray:cons3];
    cons1 = [[cons1 arrayByAddingObjectsFromArray:cons4] arrayByAddingObjectsFromArray:cons5];
    
    [headerView addConstraints:cons1];
    return headerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UETCell *cell = (UETCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }else{
            [self fetchSums];
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
//        self.detailViewController.detailItem = object;
//    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setEditedObject:(Expense *)object];
    }
}

#pragma mark - Filtering results

- (NSFetchedResultsController *)filterData
{
    if(self.filterType == UETFilterTypeNone){
        return [self unfilterData];
    }else if(self.filterType == UETFilterTypeTag){
        return [self filterDataByTag];
    }else if(self.filterType == UETFilterTypeThisWeek || self.filterType == UETFilterTypeThisMonth || self.filterType == UETFilterTypeThisYear){
        return [self filterDataByThisWeekMonthYear];
    }else if(self.filterType == UETFilterTypeCustomDate){
        return [self filterDataByCustomDate];
    }else if(self.filterType == UETFilterTypeIncome){
        return [self filterDataByIncome];
    }else if(self.filterType == UETFilterTypeExpense){
        return [self filterDataByExpense];
    }
    return nil;
}

- (NSFetchedResultsController *)unfilterData
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    [_fetchedResultsController.fetchRequest setPredicate:nil];
    
    return [self performFiltering];
}


- (NSFetchedResultsController *)filterDataByTag
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"descriptionTag = %@",self.tagObject];
    [_fetchedResultsController.fetchRequest setPredicate:predicate];
    
    return [self performFiltering];
}

- (NSFetchedResultsController *)filterDataByThisWeekMonthYear
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp >= %@",self.dateFrom];
    [_fetchedResultsController.fetchRequest setPredicate:predicate];
    return [self performFiltering];
    
}

- (NSFetchedResultsController *)filterDataByCustomDate
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"timeStamp >= %@ AND timeStamp<= %@",self.dateFrom, self.dateTo];
    [_fetchedResultsController.fetchRequest setPredicate:predicate];
    
    return [self performFiltering];
}

- (NSFetchedResultsController *)filterDataByIncome
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"amount >= 0"];
    [_fetchedResultsController.fetchRequest setPredicate:predicate];
    
    return [self performFiltering];
}

- (NSFetchedResultsController *)filterDataByExpense
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"amount < 0"];
    [_fetchedResultsController.fetchRequest setPredicate:predicate];
    
    return [self performFiltering];
}

- (NSFetchedResultsController *)performFiltering
{
    NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    [self.tableView reloadData];
    [self fetchSums];
    return _fetchedResultsController;
}

- (void)fetchSums
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    NSFetchRequest *fetchRequestIncome = [[NSFetchRequest alloc] init];
    NSFetchRequest *fetchRequestExpense = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:_managedObjectContext];
    [fetchRequestIncome setEntity:entity];
    [fetchRequestExpense setEntity:entity];
    //income
    NSPredicate *oldPredicate = _fetchedResultsController.fetchRequest.predicate;
    NSPredicate *incomePredicate = [NSPredicate predicateWithFormat:@"amount > 0"];
    if (oldPredicate) {
        NSPredicate *combiPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[oldPredicate,incomePredicate]];
        [fetchRequestIncome setPredicate:combiPredicate];
    }else{
        [fetchRequestIncome setPredicate:incomePredicate];
    }
    [fetchRequestIncome setResultType:NSDictionaryResultType];
    //expense
    NSPredicate *expensePredicate = [NSPredicate predicateWithFormat:@"amount < 0"];
    if (oldPredicate) {
        NSPredicate *combiPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[oldPredicate,expensePredicate]];
        [fetchRequestExpense setPredicate:combiPredicate];
    }else{
        [fetchRequestExpense setPredicate:expensePredicate];
    }
    
    [fetchRequestExpense setResultType:NSDictionaryResultType];
    
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    expressionDescription.name = @"sumAmount";
    expressionDescription.expression =  [NSExpression expressionForKeyPath:@"@sum.amount"];
    expressionDescription.expressionResultType = NSDecimalAttributeType;
    
    fetchRequestIncome.propertiesToFetch = @[expressionDescription];
    fetchRequestExpense.propertiesToFetch = @[expressionDescription];
    
    NSError *error = nil;
    NSArray *result = [_managedObjectContext executeFetchRequest:fetchRequestIncome error:&error];
    if (result == nil)
    {
        NSLog(@"Error: %@", error);
    }
    else
    {
        currentIncomeAmount = [[result objectAtIndex:0] objectForKey:@"sumAmount"];
        [incomeAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentIncomeAmount doubleValue]]];
    }
    
    result = [_managedObjectContext executeFetchRequest:fetchRequestExpense error:&error];
    if (result == nil)
    {
        NSLog(@"Error: %@", error);
    }
    else
    {
        currentExpenseAmount = [[result objectAtIndex:0] objectForKey:@"sumAmount"];
        [expenseAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentExpenseAmount doubleValue]]];
    }
    NSDecimalNumber *currentBalanceAmount = [currentIncomeAmount decimalNumberByAdding:currentExpenseAmount];
    [balanceAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentBalanceAmount doubleValue]]];
    NSDecimalNumber *minusOne = [NSDecimalNumber decimalNumberWithString:@"-1"];
    self.slices = @[[currentExpenseAmount decimalNumberByMultiplyingBy:minusOne], currentIncomeAmount];
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad){
        self.detailViewController.slices = self.slices;
        [self.detailViewController.pieChart reloadData];
        [self.detailViewController.incomeAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentIncomeAmount doubleValue]]];
        [self.detailViewController.expenseAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentExpenseAmount doubleValue]]];
        [self.detailViewController.balanceAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentBalanceAmount doubleValue]]];
    }
    //don't reload data if screen not visible
    if(!customDateScreenOn)
        [[self pieChart] reloadData];
}




#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    [NSFetchedResultsController deleteCacheWithName:@"Master"];
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Expense" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    [self fetchSums];
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(UETCell *)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
    [self fetchSums];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}

/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UETCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    Expense *expense = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    NSDateFormatter *df1 = [[NSDateFormatter alloc] init];
    NSDateFormatter *df2 = [[NSDateFormatter alloc] init];
    [df1 setDateFormat:@"dd.MM."];
    [df2 setDateFormat:@"HH:mm"];
    cell.date.text = [df1 stringFromDate:expense.timeStamp];
    cell.time.text = [df2 stringFromDate:expense.timeStamp];
    cell.tagLabel.text = expense.descriptionTag.tag;
    double damount = [expense.amount doubleValue];
    NSString *texAmount = [[NSString alloc] initWithFormat:@"%0.02f",damount];
    cell.amount.text = texAmount;
    cell.comment.text = expense.comment;
    
    if([expense.amount floatValue]<0){
        [cell.dateView setBackgroundColor:kLila1];
        [cell.date setTextColor:kWhiteText];
        [cell.timeView setBackgroundColor:kLila2];
        [cell.time setTextColor:kWhiteText];
        [cell.tagLabelView setBackgroundColor:kLila3];
        [cell.tagLabel setTextColor:kWhiteText];
        [cell.amountView setBackgroundColor:kLila4];
        [cell.amount setTextColor:kLilaText];
    }else{
        [cell.dateView setBackgroundColor:kGreen1];
        [cell.date setTextColor:kWhiteText];
        [cell.timeView setBackgroundColor:kGreen2];
        [cell.time setTextColor:kWhiteText];
        [cell.tagLabelView setBackgroundColor:kGreen3];
        [cell.tagLabel setTextColor:kWhiteText];
        [cell.amountView setBackgroundColor:kGreen4];
        [cell.amount setTextColor:kGreenText];
    }
}

#pragma mark - PieChartView

- (void)initializePieChartView
{
    _pieChartView = [[UIView alloc] init];
    CGRect frame = CGRectMake(0, self.navigationController.view.frame.size.height-270, self.navigationController.view.frame.size.width, 270);
    [_pieChartView setFrame:frame];
    [_pieChartView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin];
    _pieChartView.translatesAutoresizingMaskIntoConstraints = YES;
    [_pieChartView setBackgroundColor:kBackground];
    [self.navigationController.view addSubview:_pieChartView];
    
    UIView *pieToolbar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _pieChartView.frame.size.width, 35)];
    [pieToolbar setBackgroundColor:kGray1];
    [pieToolbar setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleWidth ];
    pieToolbar.translatesAutoresizingMaskIntoConstraints = YES;
    [_pieChartView addSubview:pieToolbar];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [pieToolbar addGestureRecognizer:tapRecognizer];
    
    
    UILabel *incomeLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 2, 45, 15)];
    [incomeLabel setTextColor:kGreen4];
    [incomeLabel setText:NSLocalizedString(@"INCOME", @"")];
    [incomeLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:10]];
    [pieToolbar addSubview:incomeLabel];
    
    incomeAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(2, 19, 66, 15)];
    [incomeAmountLabel setTextColor:kGrayText];
    
    [incomeAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentIncomeAmount doubleValue]]];
    [incomeAmountLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:12]];
    [incomeAmountLabel setTextAlignment:NSTextAlignmentRight];
    [pieToolbar addSubview:incomeAmountLabel];
    
    UILabel *expenseLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 2, 45, 15)];
    [expenseLabel setTextColor:kLila4];
    [expenseLabel setText:NSLocalizedString(@"EXPENSE", @"")];
    [expenseLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:10]];
    [pieToolbar addSubview:expenseLabel];
    
    expenseAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(72, 19, 66, 15)];
    [expenseAmountLabel setTextColor:kGrayText];
    [expenseAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentExpenseAmount doubleValue]]];
    [expenseAmountLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:12]];
    [expenseAmountLabel setTextAlignment:NSTextAlignmentRight];
    [pieToolbar addSubview:expenseAmountLabel];
    
    UILabel *balanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(142, 2, 45, 15)];
    [balanceLabel setTextColor:kGrayText];
    [balanceLabel setText:NSLocalizedString(@"BALANCE", @"")];
    [balanceLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:10]];
    [pieToolbar addSubview:balanceLabel];
    
    balanceAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(142, 19, 86, 15)];
    [balanceAmountLabel setTextColor:kGrayText];
    NSDecimalNumber *currentBalanceAmount = [currentIncomeAmount decimalNumberByAdding:currentExpenseAmount];
    [balanceAmountLabel setText:[[NSString alloc] initWithFormat:@"%0.02f",[currentBalanceAmount doubleValue]]];
    [balanceAmountLabel setFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:12]];
    [balanceAmountLabel setTextAlignment:NSTextAlignmentRight];
    [pieToolbar addSubview:balanceAmountLabel];
    
    pieIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"pie"]];
    [pieIcon setFrame:CGRectMake(293, 7, 21, 21)];
    [pieIcon setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    [pieToolbar addSubview:pieIcon];
    
    //dynamics
    animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.navigationController.view];
    snap = [[UISnapBehavior alloc] initWithItem:_pieChartView
                                       snapToPoint:CGPointMake(self.navigationController.view.frame.size.width/2,
                                                               self.navigationController.view.frame.size.height-35+_pieChartView.frame.size.height/2)];
    [animator addBehavior:snap];
    CGPoint pieChartCenter = CGPointMake(self.pieChartView.frame.size.width/2,
                                         (self.pieChartView.frame.size.height-35)/2+35);
    CGRect pieChartRect = CGRectMake(pieChartCenter.x-100, pieChartCenter.y-100, 200, 200);
    _pieChart = [[XYPieChart alloc] initWithFrame:pieChartRect];
    //[_pieChart setFrame:pieChartRect];
    [_pieChartView addSubview:_pieChart];
    [self createPieChart];
}

- (void)createPieChart
{
    
    [self.pieChart setDataSource:self];
    [self.pieChart setStartPieAngle:M_PI_2];
    [self.pieChart setAnimationSpeed:1.0];
    [self.pieChart setLabelFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16]];
    [self.pieChart setLabelRadius:50];
    [self.pieChart setShowPercentage:YES];
    [self.pieChart setPieBackgroundColor:kBackground];
    [self.pieChart setPieCenter:CGPointMake(100, 100)];
    [self.pieChart setUserInteractionEnabled:YES];
    [self.pieChart setLabelShadowColor:[UIColor blackColor]];
    self.sliceColors = @[kLila1, kGreen1];
}

#pragma mark - XYPieChart Data Source

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart
{
    return self.slices.count;
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index
{
    return [[self.slices objectAtIndex:index] floatValue];
}

- (UIColor *)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index
{
    return [self.sliceColors objectAtIndex:(index % self.sliceColors.count)];
}

#pragma mark - XYPieChart Delegate
- (void)pieChart:(XYPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"will select slice at index %lu",(unsigned long)index);
}
- (void)pieChart:(XYPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"will deselect slice at index %lu",(unsigned long)index);
}
- (void)pieChart:(XYPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index
{
    NSLog(@"did deselect slice at index %lu",(unsigned long)index);
}
//- (void)pieChart:(XYPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index
//{
//    NSLog(@"did select slice at index %d",index);
//    self.selectedSliceLabel.text = [NSString stringWithFormat:@"$%@",[self.slices objectAtIndex:index]];
//}



#pragma mark - Tap Gesture

- (void)handleTap:(UITapGestureRecognizer *)recognizer
{
    if(!pieChartUp){
        pieChartUp = YES;
        [self positionPieChart];
        [pieIcon setImage:[UIImage imageNamed:@"Close"]];
    }else{
        pieChartUp = NO;
        [self positionPieChart];
        [pieIcon setImage:[UIImage imageNamed:@"pie"]];
    }
}

#pragma mark - Orientation changed

- (void)orientationChanged:(NSNotification *)aNotification
{
    if(!UIDeviceOrientationIsValidInterfaceOrientation([UIDevice currentDevice].orientation)) return;
    if(!pieChartUp){
        [self positionPieChart];
        [pieIcon setImage:[UIImage imageNamed:@"pie"]];
    }else{
        [self positionPieChart];
        [pieIcon setImage:[UIImage imageNamed:@"Close"]];
    }
}

- (void)positionPieChart
{
    if (pieChartUp) {
        if(snap){
            [animator removeBehavior:snap];
            if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
                snap = [[UISnapBehavior alloc] initWithItem:_pieChartView
                                                   snapToPoint:CGPointMake(self.navigationController.view.frame.size.height/2,
                                                                           self.navigationController.view.frame.size.width-_pieChartView.frame.size.height/2)];
                [self positionPieChartRect];
            }else{
                snap = [[UISnapBehavior alloc] initWithItem:_pieChartView
                                                   snapToPoint:CGPointMake(self.navigationController.view.frame.size.width/2,
                                                                           self.navigationController.view.frame.size.height-_pieChartView.frame.size.height/2)];
                [self positionPieChartRect];
            }
            [animator addBehavior:snap];
            UIEdgeInsets tblInsets = [self.tableView contentInset];
            tblInsets.bottom = 270;
            [self.tableView setContentInset:tblInsets];
        }
    }else{
        if(snap){
            [animator removeBehavior:snap];
            if(UIDeviceOrientationIsLandscape([[UIDevice currentDevice] orientation])){
                snap = [[UISnapBehavior alloc] initWithItem:_pieChartView
                                                   snapToPoint:CGPointMake(self.navigationController.view.frame.size.height/2,
                                                                           self.navigationController.view.frame.size.width-35+_pieChartView.frame.size.height/2)];
                [self positionPieChartRect];
            }else{
                snap = [[UISnapBehavior alloc] initWithItem:_pieChartView
                                                   snapToPoint:CGPointMake(self.navigationController.view.frame.size.width/2,
                                                                           self.navigationController.view.frame.size.height-35+_pieChartView.frame.size.height/2)];
                [self positionPieChartRect];
            }
            [animator addBehavior:snap];
            UIEdgeInsets tblInsets = [self.tableView contentInset];
            tblInsets.bottom = 35;
            [self.tableView setContentInset:tblInsets];
        }
    }
}

- (void)positionPieChartRect
{
    CGPoint pieChartCenter = CGPointMake(self.pieChartView.frame.size.width/2,
                                             (self.pieChartView.frame.size.height-35)/2+35);
    CGRect pieChartRect = CGRectMake(pieChartCenter.x-100, pieChartCenter.y-100, 200, 200);
    [_pieChart setFrame:pieChartRect];
}

#pragma mark - UIDynamicAnimatorDelegate

-(void)dynamicAnimatorDidPause:(UIDynamicAnimator *)animator
{
    if(pieChartUp){
        [self.pieChart reloadData];
    }
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Pie Chart", @"Pie Chart");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

@end
