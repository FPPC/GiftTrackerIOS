//
//  Source.h
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Source : NSObject

@property (assign, nonatomic) NSUInteger idno;
@property (copy, nonatomic) NSString * name;
@property (copy, nonatomic) NSString * addr1;
@property (copy, nonatomic) NSString * addr2;
@property (copy, nonatomic) NSString * city;
@property (copy, nonatomic) NSString * state;
@property (copy, nonatomic) NSString * zip;
@property (copy, nonatomic) NSString * business;
@property (assign, nonatomic) BOOL lobby;
@property (copy, nonatomic) NSString * email;
@property (copy, nonatomic) NSString * phone;
@property (assign, nonatomic) double limitLeft;

@end
