//
//  giftViewController.h
//  Gift Tracker
//
//  Created by Tam Do on 7/17/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DAO;
@class Source;

@interface giftViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>
@property (weak, nonatomic) DAO * dao;
@property (strong, nonatomic) Source * source;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (copy, nonatomic) NSMutableArray * gifts;
@end
