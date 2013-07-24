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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    Gift * g = [gifts objectAtIndex:[indexPath row]];
    cell.textLabel.text = g.description;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"$%.2f",[g findContributionFromSourceId:self.source.idno].value ] ;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.gifts count];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
   }

@end
