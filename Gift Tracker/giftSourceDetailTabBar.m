//
//  giftSourceDetailTabBar.m
//  Gift Tracker
//
//  Created by Tam Do on 7/12/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "giftSourceDetailTabBar.h"
#import "Source.h"
#import "giftSourceDetailViewController.h"
#import "giftViewController.h"
@interface giftSourceDetailTabBar ()

@end

@implementation giftSourceDetailTabBar

@synthesize source;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    giftSourceDetailViewController * detail = [self.viewControllers objectAtIndex:0];
    detail.source = self.source;
    /*
    UINavigationController * nav = [self.viewControllers objectAtIndex:1];
    giftViewController *giftVC = [[nav viewControllers] objectAtIndex:0];
    */
    giftViewController * giftVC = [self.viewControllers objectAtIndex:1];
    giftVC.source = self.source;
   	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
