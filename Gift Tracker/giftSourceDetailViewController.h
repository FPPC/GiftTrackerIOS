//
//  giftSourceDetailViewController.h
//  Gift Tracker
//
//  Created by Tam Do on 7/12/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Source;
@class DAO;

@interface giftSourceDetailViewController : UITableViewController

-(void)configureView;

@property (weak, nonatomic) DAO * dao;
@property (strong, nonatomic) Source * source;

@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *addr1;
@property (weak, nonatomic) IBOutlet UILabel *addr2;
@property (weak, nonatomic) IBOutlet UILabel *city;
@property (weak, nonatomic) IBOutlet UILabel *state;
@property (weak, nonatomic) IBOutlet UILabel *zip;
@property (weak, nonatomic) IBOutlet UILabel *business;
@property (weak, nonatomic) IBOutlet UILabel *lobbyist;
@property (weak, nonatomic) IBOutlet UILabel *email;
@property (weak, nonatomic) IBOutlet UILabel *phone;


-(IBAction)saveEdit:(UIStoryboardSegue *)segue;
-(IBAction)cancelEdit:(UIStoryboardSegue *)segue;

- (IBAction)deleteButton:(UIButton *)sender;

@end
