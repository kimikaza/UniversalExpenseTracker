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
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(openPrintScreen:)];
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

- (void)openPrintScreen:(id)sender
{
    [_mvc openPrintScreen:sender];
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




@end
