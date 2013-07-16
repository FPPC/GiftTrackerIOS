//
//  giftNewSourceViewController.m
//  Gift Tracker
//
//  Created by Tam Do on 7/12/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "giftNewSourceViewController.h"
#import "Source.h"

@interface giftNewSourceViewController ()

@end

@implementation giftNewSourceViewController

@synthesize name,addr1,addr2,business,lobbyist,state,city,zip,email,phone;

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
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
    [self.save setEnabled:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"SaveNew"]) {
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
