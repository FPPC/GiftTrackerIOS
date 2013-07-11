//
//  giftMasterViewController.h
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <UIKit/UIKit.h>

@class giftDetailViewController;

@interface giftMasterViewController : UITableViewController

@property (strong, nonatomic) giftDetailViewController *detailViewController;

@end
