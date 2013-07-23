//
//  giftEditSourceViewController.m
//  Gift Tracker
//
//  Created by Tam Do on 7/16/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "giftEditSourceViewController.h"
#import "Source.h"

@interface giftEditSourceViewController ()

@end

@implementation giftEditSourceViewController
@synthesize name,addr1,addr2,business,lobbyist,state,city,zip,email,phone;

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.source == nil) {
        return;
    }
    /*
    [self.navigationController.navigationBar.topItem setLeftBarButtonItem:self.navigationItem.leftBarButtonItem];
    [self.navigationController.navigationBar.topItem setRightBarButtonItem:self.navigationItem.rightBarButtonItem];
    [self.navigationController.navigationBar.topItem setTitle:self.navigationItem.title];
    */
    [self.name setText:self.source.name];
    self.addr1.text = self.source.addr1;
    self.addr2.text = self.source.addr2;
    self.city.text = self.source.city;
    self.state.text = self.source.state;
    self.zip.text = self.source.zip;
    self.lobbyist.on = self.source.lobby;
    self.business.text = self.source.business;
    self.email.text = self.source.email;
    self.phone.text = self.source.phone;
}


- (IBAction)test:(id)sender {
    NSLog(@"it did run");
}

-(IBAction)editingChange {
    if ([self.name.text length] != 0) {
        [self.save setEnabled:YES];
    } else {
        [self.save setEnabled:NO];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"SaveEdit"]) {
        self.source = [[Source alloc] init];
        self.source.name = self.name.text;
        self.source.business = self.business.text;
        self.source.lobby = self.lobbyist.on ;
        self.source.addr1 = self.addr1.text;
        self.source.addr2 = self.addr2.text;
        self.source.city = self.city.text;
        self.source.state = self.state.text;
        self.source.zip = self.zip.text;
        self.source.email = self.email.text;
        self.source.phone = self.phone.text;
    }
}


@end
