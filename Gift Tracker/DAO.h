//
//  DAO.h
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Source.h"
#import "Utility.h"
#import "giftAppDelegate.h"

@interface DAO : NSObject

@property (strong, nonatomic) FMDatabase * db;

extern const double LIMIT;
extern const double LOBBY_LIMIT;

-(NSMutableArray *) getAllSources;
-(NSMutableArray *) filterSources:(NSString *)searchString;
-(double) limitLeft:(Source *) source;
//-(BOOL) insertSource:(Source *) s;
//-(BOOL) updateSource:(Source *) s;

@end