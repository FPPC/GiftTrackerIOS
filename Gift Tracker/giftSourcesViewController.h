//
//  giftSourcesViewController.h
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "giftAppDelegate.h"
#import "Source.h"
#import "DAO.h"

@interface giftSourcesViewController : UITableViewController <UISearchBarDelegate, UISearchDisplayDelegate>

// App delegate decide when to expire the one and only DAO of the app, hence everything else's reference to that one DAO
// should be 'weak'
@property (weak, nonatomic) DAO * dao;
// the data array of the view, whenever you change this, call reload on tableview
// to reload the cells
@property (strong, nonatomic) NSMutableArray * sources;

@end
