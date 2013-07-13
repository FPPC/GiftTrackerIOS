//
//  giftNewSourceViewController.h
//  Gift Tracker
//
//  Created by Tam Do on 7/12/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface giftNewSourceViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *name;
@property (weak, nonatomic) IBOutlet UITextField *addr1;
@property (weak, nonatomic) IBOutlet UITextField *addr2;
@property (weak, nonatomic) IBOutlet UITextField *city;
@property (weak, nonatomic) IBOutlet UITextField *state;
@property (weak, nonatomic) IBOutlet UITextField *zip;
@property (weak, nonatomic) IBOutlet UITextField *business;
@property (weak, nonatomic) IBOutlet UISwitch *lobbyist;
@property (weak, nonatomic) IBOutlet UITextField *email;
@property (weak, nonatomic) IBOutlet UITextField *phone;


@end
