//
//  giftEditSourceViewController.h
//  Gift Tracker
//
//  Created by Tam Do on 7/16/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Source;
@class DAO;
@interface giftEditSourceViewController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) Source * source;

@property (weak, nonatomic) DAO * dao;

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

//Gray save button when name is empty
@property (weak, nonatomic) IBOutlet UIBarButtonItem *save;
- (IBAction)test:(id)sender;
-(IBAction) editingChange;
@end
