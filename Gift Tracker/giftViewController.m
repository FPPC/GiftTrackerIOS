//
//  giftViewController.m
//  Gift Tracker
//
//  Created by Tam Do on 7/17/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "giftViewController.h"
#import "Gift.h"
#import "Source.h"
#import "Contribution.h"
#import "giftAppDelegate.h"

@interface giftViewController ()

@end

@implementation giftViewController

@synthesize gifts, source;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidAppear:(BOOL)animated {
    [self.navigationController.navigationBar.topItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];
    [self.navigationController.navigationBar.topItem setTitle:self.navigationItem.title];

    self.gifts = [self.dao filterGiftFromSource:self.source withSearchString:self.searchBar.text];
    [[self tableView] reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dao = ((giftAppDelegate *)[[UIApplication sharedApplication] delegate]).dao;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"GiftCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    //styling
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Gift * g = [gifts objectAtIndex:[indexPath row]];
    cell.textLabel.text = g.description;
    [cell.detailTextLabel setTextColor:[UIColor colorWithRed:0 green:0.4 blue:0 alpha:1]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"$%.2f",[g findContributionFromSourceId:self.source.idno].value ] ;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.gifts count];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // DAO takes care of empty search string case too
    self.gifts = [self.dao filterGiftFromSource:self.source withSearchString:searchText];
    [self.tableView reloadData];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}


@end
