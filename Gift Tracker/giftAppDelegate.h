//
//  giftAppDelegate.h
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utility.h"
#import "DAO.h"

@class DAO;
@interface giftAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (copy, nonatomic) NSString * databaseName;
@property (copy, nonatomic) NSString * databasePath;
@property (strong, nonatomic) DAO * dao;

@end
