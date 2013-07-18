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
@class Gift;
@interface DAO : NSObject

@property (strong, nonatomic) FMDatabase * db;

extern const double LIMIT;
extern const double LOBBY_LIMIT;

//C
-(BOOL) insertSource:(Source *) s;
-(BOOL) insertGift:(Gift *) g;

//R
-(NSMutableArray *) getAllSources;
-(NSMutableArray *) filterSources:(NSString *)searchString;
-(NSMutableArray *) getAllGiftFromSource:(Source *)source;
-(Gift*)getGiftWithId:(NSUInteger *)gid;
-(double) limitLeft:(Source *) source;

//U
-(BOOL) updateSource:(Source *)old newSource:(Source *)newSource;
-(BOOL) updateGift:(Gift *)old newGift:(Gift *)newGift;
//D
-(BOOL) deleteSource:(Source *)source;
-(BOOL) deleteGift:(Gift *)gift;

@end
