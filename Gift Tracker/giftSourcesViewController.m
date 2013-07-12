//
//  giftSourcesViewController.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "giftSourcesViewController.h"

@implementation giftSourcesViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    // make connection to the one the only DAO object of the whole app
    self.dao = ((giftAppDelegate*) [[UIApplication sharedApplication] delegate]).dao;
    //populate the initial sources;
    if (self.sources == nil) {
        self.sources = [self.dao getAllSources];
    }
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
    [limitLabel setText:[NSString stringWithFormat:@"$%.2f",[self.dao limitLeft:s]]];
    return cell;
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.sources = [self.dao filterSources:searchText];
    [self.tableView reloadData];
}

@end
