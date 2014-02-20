//
//  DetailViewController.m
//  UniversalExpenseTracker
//
//  Created by Zoran Plesko on 14/02/14.
//  Copyright (c) 2014 Masinerija. All rights reserved.
//

#import "DetailViewController.h"
#import "MasterViewController.h"
#import "Expense.h"
#import "DescriptionTag.h"
#import "UETSimplePageRenderer.h"
#import "XYPieChart.h"

@interface DetailViewController ()<XYPieChartDataSource, XYPieChartDelegate>

@property (nonatomic, weak) MasterViewController *mvc;

- (void)configureView;
@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }

//    if (self.masterPopoverController != nil) {
//        [self.masterPopoverController dismissPopoverAnimated:YES];
//    }        
}

- (void)configureView
{
    // Update the user interface for the detail item.
    [self.navigationController.navigationBar setTintColor:kGreen1];
    self.slices = [[NSArray alloc] init];
    
    UINavigationController *navC = [self.splitViewController viewControllers][1];
    
    self.mvc = [navC viewControllers][0];
    
    UIBarButtonItem *settingsButton =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openSettingsScreen:)];
    self.navigationItem.leftBarButtonItem = settingsButton;
    [self initializeLabels];
    [self createPieChart];
    [self.pieChart reloadData];
}

- (void)initializeLabels
{
    [_incomeLabel setTextColor:kGreen4];
    [_incomeLabel setText:NSLocalizedString(@"INCOME", @"")];
    
    [_incomeAmountLabel setTextColor:kGrayText];

    [_expenseLabel setTextColor:kLila4];
    [_expenseLabel setText:NSLocalizedString(@"EXPENSE", @"")];
    
    [_expenseAmountLabel setTextColor:kGrayText];
    
    [_balanceLabel setTextColor:kGrayText];
    [_balanceLabel setText:NSLocalizedString(@"BALANCE", @"")];

    [_balanceAmountLabel setTextColor:kGrayText];

}

- (void)openSettingsScreen:(id)sender
{
    [_mvc openSettingsScreen:sender]; return;
//    UIPrintInteractionController *printController = [UIPrintInteractionController sharedPrintController];
//    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
//    printInfo.jobName = @"Expense Tracker";
//    [printInfo setOrientation:UIPrintInfoOrientationPortrait];
//    [printInfo setOutputType:UIPrintInfoOutputGeneral];
//    [printController setPrintInfo:printInfo];
//    
//    NSMutableAttributedString *printData = [[NSMutableAttributedString alloc] init];
//    for (Expense *expense in [_mvc.fetchedResultsController fetchedObjects]) {
//        NSString *date = [self formatDate:[expense timeStamp]];
//        NSString *time = [self formatTime:[expense timeStamp]];
//        NSString *amount = [expense.amount stringValue];
//        NSString *tag = expense.descriptionTag.tag;
//        NSString *comment = expense.comment;
//        date = [self rightPadedString:date Long:12];
//        time = [self rightPadedString:time Long:8];
//        amount = [self rightPadedString:amount Long:12];
//        tag = [self rightPadedString:tag Long:25];
//        
//        NSString *row = [NSString stringWithFormat:@"%@%@%@%@%@\n",date, time, amount, tag, comment];
//        UIFont *font = [UIFont fontWithName:@"Courier" size:10];
//        NSDictionary *attributesForString = @{NSFontAttributeName:font};
//        NSAttributedString *rowAttr = [[NSAttributedString alloc] initWithString:row attributes:attributesForString];
//        [printData appendAttributedString:rowAttr];
//    }
//    
//    UISimpleTextPrintFormatter *printFormatter = [[UISimpleTextPrintFormatter alloc] initWithAttributedText:printData];
//    
//    //    CORE GRAPHICS PAGE RENDERER, we do not need that here, arranging data there is really tedious!
//    //    UETPrintPageRenderer *pageRenderer = [[UETPrintPageRenderer alloc] init];
//    //    printController.printPageRenderer = pageRenderer;
//    //
//    //    pageRenderer.data = [_fetchedResultsController fetchedObjects];
//    //    pageRenderer.numberOfRows = pageRenderer.data.count;
//    //    pageRenderer.footerHeight = 30;
//    
//    UETSimplePageRenderer *pageRenderer = [[UETSimplePageRenderer alloc] init];
//    [pageRenderer addPrintFormatter:printFormatter startingAtPageAtIndex:0];
//    NSString *headerText = @"DATE AND TIME       AMOUNT      DESCRIPTION              COMMENT";
//    [pageRenderer setHeaderText:headerText];
//    [pageRenderer setFooterHeight:30];
//    
//    [printController setPrintPageRenderer:pageRenderer];
//    
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
//        [printController presentFromBarButtonItem:self.navigationItem.leftBarButtonItem animated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
//            //
//        }];
//    }else{
//        [printController presentAnimated:YES completionHandler:^(UIPrintInteractionController *printInteractionController, BOOL completed, NSError *error) {
//            //
//        }];
//    }

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
    [df setDateFormat:@"dd.MM.yyyy"];
    return [df stringFromDate:date];
}

-(NSString *)formatTime:(NSDate *)date
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"HH:mm"];
    return [df stringFromDate:date];
}




- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Pie Chart

- (void)createPieChart
{
    
    [self.pieChart setDataSource:self];
    [self.pieChart setStartPieAngle:M_PI_2];
    [self.pieChart setAnimationSpeed:1.0];
    [self.pieChart setLabelFont:[UIFont fontWithName:@"AvenirNextCondensed-Medium" size:16]];
    [self.pieChart setLabelRadius:100];
    [self.pieChart setShowPercentage:YES];
    [self.pieChart setPieBackgroundColor:kBackground];
    [self.pieChart setPieCenter:CGPointMake(150, 150)];
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




@end
