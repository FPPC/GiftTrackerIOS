//
//  DAO.h
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMDatabase;
@class Source;
@interface DAO : NSObject

@property (strong, nonatomic) FMDatabase * db;

extern const double LIMIT;
extern const double LOBBY_LIMIT;

//C
-(BOOL) insertSource:(Source *) s;

//R
-(NSMutableArray *) getAllSources;
-(NSMutableArray *) filterSources:(NSString *)searchString;
-(double) limitLeft:(Source *) source;
//U
-(BOOL) updateSource:(Source *)old newSource:(Source *)newSource;
//D
-(BOOL) deleteSource:(Source *)source;


@end
