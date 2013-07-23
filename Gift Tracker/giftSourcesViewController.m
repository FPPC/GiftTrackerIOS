//
//  giftSourcesViewController.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "giftSourcesViewController.h"
#import "giftAppDelegate.h"
#import "Source.h"
#import "DAO.h"
#import "giftNewSourceViewController.h"
#import "giftSourceDetailViewController.h"
#import "giftSourceDetailTabBar.h"

@interface giftSourcesViewController () {

}

@end

@implementation giftSourcesViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    // make connection to the one the only DAO object of the whole app
    self.dao = ((giftAppDelegate*) [[UIApplication sharedApplication] delegate]).dao;
    
    /*populate the initial sources;
    if (self.sources == nil) {
        self.sources = [self.dao getAllSources];
    }
     */
    // Only load the DAO (data access object) when view controller is loaded in memory
    // we do the loading of the actual table when view appear in front
    // can be optimized here, but I figure it wont be much of a performance hit.
}

// reload sources when view appear - that way it update when resume from editting in detail view too !
- (void) viewDidAppear:(BOOL)animated {
    self.sources = [self.dao filterSources:self.sBar.text];
    [self.dao doubleCheckLimit:self.sources];
    [[self tableView] reloadData];
}

-(IBAction)saveNew:(UIStoryboardSegue *)segue {
    NSLog(@"BOOHOO");
    if ([[segue identifier] isEqualToString:@"SaveNew"]) {
        
        giftNewSourceViewController * newController = [segue sourceViewController];
        if (newController.source) {
            if ([self.dao insertSource:newController.source]) {
                
                // newController.source is strong propery, release it now
                newController.source = nil;
                
                // update the table view
                self.sources = [self.dao filterSources:self.sBar.text];
                [[self tableView] reloadData];
            }
        }
}
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(IBAction)cancelNew:(UIStoryboardSegue *)segue {
    NSLog(@"Cancel");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sources count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellID = @"SourceCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellID];
    
    //styling
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID];
    }
    
    Source * s = [self.sources objectAtIndex:[indexPath row]];
    
    [(UILabel*)[cell viewWithTag:1] setText:s.name];
    UILabel * limitLabel = (UILabel*)[cell viewWithTag:2];
        if (s.limitLeft < 0) {
        [limitLabel setTextColor:[UIColor colorWithRed:0.4 green:0 blue:0 alpha:1]];
        [limitLabel setText:[NSString stringWithFormat:@"-$%.2f",-s.limitLeft]];

    } else {
        [limitLabel setTextColor:[UIColor colorWithRed:0 green:0.4 blue:0 alpha:1]];
        [limitLabel setText:[NSString stringWithFormat:@"$%.2f",s.limitLeft]];

    }
    return cell;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    // DAO takes care of empty search string case too
    self.sources = [self.dao filterSources:searchText];
    [self.tableView reloadData];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"ShowSourceDetails"]) {
        giftSourceDetailTabBar *tabBar = [segue destinationViewController];
        tabBar.source = [self.sources objectAtIndex:[self.tableView indexPathForCell:sender].row];
    }
}

@end
