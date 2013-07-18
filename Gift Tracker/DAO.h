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

//Source C
-(BOOL) insertSource:(Source *) s;

//Source R
-(NSMutableArray *) getAllSources;
-(NSMutableArray *) filterSources:(NSString *)searchString;
-(double) limitLeft:(Source *) source;
-(void) doubleCheckLimit:(NSMutableArray *) sources;

//Source U
-(BOOL) updateSource:(Source *)old newSource:(Source *)newSource;

//Source D
-(BOOL) deleteSource:(Source *)source;

/*================================================*/

//Gift C
-(BOOL) insertGift:(Gift *) g;

//Gift R
-(NSMutableArray *) getAllGiftFromSource:(Source *)source;
-(NSMutableArray *)filterGiftFromSource:(Source *)source
                       withSearchString:(NSString *) searchString;
-(Gift*)getGiftWithId:(NSUInteger *)gid;
-(void) updateGiftContributionForGift:(Gift *)g;

//Gift U
-(BOOL) updateGift:(Gift *)old newGift:(Gift *)newGift;

//Gift D
-(BOOL) deleteGift:(Gift *)gift;

@end
