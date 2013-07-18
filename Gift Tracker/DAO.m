//
//  DAO.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//


/* NOTICE:
 * Sorry for putting all data access method in one big file
 * intead of 2 files SourceDAO, GiftDAO. 
 * I try my best to pragma mark it for ease of reading.
 * 
 * My reason:
 * Any view controller that interacts with the database should only need one DAO for
 * every database-related task. Also Xcode is accomodating enough with the reading.
 * 
 * Suggestion:
 * A tidier but not-so-clean hack:
 * Make DAO inherit from SourceDAO inherit from GiftDAO, or just inject methods
 * definition into it.
 *
 * Pro: tidier code, 2-3 separate files to read instead of one big file
 * Con: logically it doesn't make sense. (DAO is not a children of giftDAO nor
 *      sourceDAO. And method injection is messy to read.
 */


#import "DAO.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Source.h"
#import "Utility.h"
#import "giftAppDelegate.h"
#import "Gift.h"
#import "Contribution.h"


@interface DAO()
-(void) cleanupOrphanedGift;
-(void) sortSources:(NSMutableArray *)sources;
-(Source *)processSourceResult:(FMResultSet *)results;
-(Gift *) processGiftResult:(FMResultSet *)results;
@end

@implementation DAO

const double LIMIT = 440.0;
const double LOBBY_LIMIT = 10.0;

// #pragma mark are XCode helper to jump to sections of code
// Doesnt affect any programming logic at all
#pragma mark Generic Object Method

-(id)init {
    self = [super init];
    giftAppDelegate * appDelegate = (giftAppDelegate *)[[UIApplication sharedApplication] delegate];
    //setup the db
    self.db = [FMDatabase databaseWithPath:[Utility getDatabasePath:appDelegate.databaseName]];
    [self.db open];
    return self;
}

-(void)dealloc {
    // Yes, even in ARC we can do dealloc, this is solely just to close the db.
    // no releasing needed (it's automatic)
    // no super call needed (automatic too). In fact if you call super here, compiler will stop you
    
    [self.db close];
}

#pragma mark Helper
- (void)cleanupOrphanedGift {
    NSString * query = @"DELETE FROM gift WHERE gid NOT IN (SELECT gid FROM giving)";
    NSString * index_query = @"DELETE FROM gift_index WHERE docid NOT IN (SELECT gid FROM giving)";
    [self.db beginTransaction];
    @try {
        if (![self.db executeUpdate:query]) {
            [NSException raise:@"can't cleanup orphaned gifts" format:@""];
        }
        if (![self.db executeUpdate:index_query]) {
            [NSException raise:@"can't cleanup orphaned gifts index" format:@""];
        }
        [self.db commit];
    }
    @catch (NSException * e) {
        [self.db rollback];
    }
}

-(void)sortSources:(NSMutableArray *)sources {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"limitLeft" ascending:YES];
    [sources sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    sortDescriptor = nil;
}

- (Source *) processSourceResult:(FMResultSet * )results {
    Source *s = [[Source alloc] init];
    s.idno = [results intForColumn:@"sid"];
    //convention over configuration, @property name should be the same as column name, except the id (which is a reserved word)
    s.name = [results stringForColumn:@"name"];
    s.addr1 = [results stringForColumn:@"addr1"];
    s.addr2 = [results stringForColumn:@"addr2"];
    s.city = [results stringForColumn:@"city"];
    s.state = [results stringForColumn:@"state"];
    s.zip= [results stringForColumn:@"zip"];
    s.business = [results stringForColumn:@"business"];
    s.lobby = ([results intForColumn:@"lobby"] != 0);
    s.email = [results stringForColumn:@"email"];
    s.phone = [results stringForColumn:@"phone"];
    s.limitLeft = [self limitLeft:s];
    return s;
}

- (Gift *) processGiftResultWithoutContributionList:(FMResultSet *)results {
    Gift * g = [[Gift alloc] init];
    g.description = [results stringForColumn:@"description"];
    g.idno = [results intForColumn:@"gid"];
    
    NSInteger y = [results intForColumn:@"year"];
    NSInteger m = [results intForColumn:@"month"];
    NSInteger d = [results intForColumn:@"day"];
    
    NSDateComponents * dateComp = [[NSDateComponents alloc] init];
    
    NSCalendar * cal = [NSCalendar currentCalendar];
    
    [dateComp setYear:y];
    [dateComp setMonth:m];
    [dateComp setDay:d];
    g.date = [cal dateFromComponents:dateComp];
    return g;
}

#pragma mark Source Create

- (BOOL) insertSource:(Source *)s {
    NSString * query = @"INSERT INTO source (name,addr1,addr2,city,state,zip,business,lobby,email,phone) values (?,?,?,?,?,?,?,?,?,?)";
    NSString * index_query = @"INSERT INTO source_index (docid,content) values (?, ?)";
    BOOL success;
    [self.db beginTransaction];
    //it will either end with a commit, or a rollback
    @try {
        
        success = [self.db executeUpdate:query, s.name, s.addr1, s.addr2, s.city, s.state, s.zip,
                   s.business, [NSNumber numberWithBool:s.lobby], s.email, s.phone];
        if (!success) {
            //exception throw
            [NSException raise:@"can't insert source" format:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", s.name, s.addr1, s.addr2,
             s.city, s.state, s.zip, s.business, s.lobby?@"lobbyist":@"", s.email, s.phone];
        }
        
        NSString * content = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", s.name, s.addr1, s.addr2,
                              s.city, s.state, s.zip, s.business, s.lobby?@"lobbyist":@"", s.email, s.phone];
        
        // WARNING: THIS IS INTENDED FOR SINGLE THREADED APP ONLY, NOT THREAD-SAFE
        NSNumber * idno = [NSNumber numberWithInteger:[self.db lastInsertRowId]];
        BOOL index_success = [self.db executeUpdate:index_query, idno, content];
        success = success && index_success;
        if (!index_success) {
            //exception throw
            [NSException raise:@"Cant index source" format:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", s.name, s.addr1, s.addr2,
             s.city, s.state, s.zip, s.business, s.lobby?@"lobbyist":@"", s.email, s.phone];
        }
        [self.db commit];
    }
    
    @catch (NSException *e) {
        [self.db rollback];
    }
    return success;
}

#pragma mark Source Read

- (NSMutableArray *)getAllSources {
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    //query
    NSString * query = @"SELECT * FROM source;";
    //run
    FMResultSet *results = [self.db executeQuery:query];
    while ([results next]) {
        [sources addObject:[self processSourceResult:results]];
    }
    [self sortSources:sources];
    return sources;
}

-(NSMutableArray *)filterSources:(NSString *)searchString {
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    if ((searchString == nil) || ([searchString length] == 0)){
        return [self getAllSources];
    }
    //query
    NSString * query = @"SELECT s.* FROM source s JOIN source_index i ON i.docid = s.sid WHERE i.content match ?";
    FMResultSet *results = [self.db executeQuery:query withArgumentsInArray:[NSArray arrayWithObject:[searchString stringByAppendingString:@"*"]]];
    while ([results next]) {
        [sources addObject:[self processSourceResult:results]];
    }
    [self sortSources:sources];
    return sources;
}

-(double)limitLeft:(Source *)source {
    double output = (source.lobby)?LOBBY_LIMIT:LIMIT;
    NSString * query = @"SELECT SUM(value) FROM giving WHERE sid = ?";
    
    FMResultSet *result = [self.db executeQuery:query withArgumentsInArray:[NSArray arrayWithObject:[NSNumber numberWithInteger:source.idno]]];
    
    if ([result next]) {
        output -= [result doubleForColumnIndex:0];
    }
    return output;
}

- (void) doubleCheckLimit:(NSMutableArray *)sources {
    for(Source *s in sources) {
        s.limitLeft = [self limitLeft:s];
    }
}

#pragma mark Source Update

-(BOOL) updateSource:(Source *)old newSource:(Source *)newSource {
    
    // Why getting idno directly work?
    // SourceDetailVC (view controller) get info from the sources arrays in SourceVC
    // SourceVC get its array from getAllSources and filterSource in DAO class
    // getAllSource and filterSource build their object with processResult, which give the object its database sid
    // under the property idno;
    // therefore the old Source know its own database id.
    
    NSInteger sid = old.idno;
    
    NSString * query = @"UPDATE source SET name=?, addr1=?, addr2=?, city=?, state=?, zip=?, business=?, lobby=?, email=?, phone=? \
            WHERE sid = ?";
    
    BOOL success = [self.db executeUpdate:query, newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state, newSource.zip,
                    newSource.business, [NSNumber numberWithBool:newSource.lobby], newSource.email, newSource.phone, [NSNumber numberWithInteger:sid]];
    
    if (success) {
        query = @"UPDATE source_index SET content = ? WHERE docid = ?";
        NSString * content = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state,
                              newSource.zip, newSource.business, newSource.lobby?@"lobbyist":@"", newSource.email, newSource.phone];
        
        BOOL index_success = [self.db executeUpdate:query, content, [NSNumber numberWithInteger:sid]];
        success = success && index_success;
    }
    return success;
}

#pragma mark Source Delete

-(BOOL) deleteSource:(Source *)source {
    NSNumber * sid = [NSNumber numberWithInteger:source.idno];
    NSString * query =@"DELETE FROM source WHERE sid = ?";
    NSString * d_giving = @"DELETE FROM giving WHERE sid =?";
    NSString * d_index = @"DELETE FROM source_index WHERE docid = ?";
    [self.db beginTransaction];
    @try {
        if (![self.db executeUpdate:query, sid]) {

            [NSException raise:@"Delete Source error" format:@""];
        }
        if (![self.db executeUpdate:d_giving, sid]) {
            [NSException raise:@"Delete in table giving error" format:@""];
        }
        if (![self.db executeUpdate:d_index, sid]) {
            [NSException raise:@"Delete Source index error" format:@""];
        }
        [self.db commit];
        [self cleanupOrphanedGift];
    }
    @catch (NSException *exception) {
        [self.db rollback];
        return NO;
    }
    return YES;
}

#pragma mark Gift Create
-(BOOL) insertGift:(Gift *)g {
    NSString * query = @"INSERT INTO gift(year,month,day,description) VALUES (?,?,?,?)";
    NSString * index_query = @"INSERT INTO gift_index (docid, content) VALUES (?,?)";
    NSString * giving = @"INSERT INTO giving(value,sid,gid) VALUES (?,?,?)";
    
    NSDateComponents * dateComp = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit) fromDate:g.date];
    NSUInteger d = [dateComp day];
    NSUInteger m = [dateComp month];
    NSUInteger y = [dateComp year];
    
    [self.db beginTransaction];
    @try {
        if (![self.db executeUpdate:query, y,m,d, g.description]) {
            [NSException raise:@"Insert gift info fail" format:@"%d/%d/%d %@",m,d,y,g.description ];
        }
        //not thread safe
        NSNumber * num = [NSNumber numberWithInteger:[self.db lastInsertRowId]];
        NSString * content = [NSString stringWithFormat:@"%d/%d/%d %@",m,d,y,g.description];
        if (![self.db executeUpdate:index_query,num,content]) {
            [NSException raise:@"Insert gift index fail" format:@"%d/%d/%d %@",m,d,y,g.description ];
        }
        for(int i = 0; i < [g.contributions count]; i++) {
            NSUInteger sid = ((Contribution *)g.contributions[i]).sid;
            float value = ((Contribution *)g.contributions[i]).value;
            if (![self.db executeUpdate:giving, value , sid, num]) {
                [NSException raise:@"Insert giving fail" format:@"%d/%d/%d %@ sid: %d, value: %.2f",m,d,y,g.description,sid,value];
            }
        }
        
        [self.db commit];
    }
    @catch (NSException *exception) {
        [self.db rollback];
    }
}

#pragma mark Gift Read

-(NSMutableArray *) getAllGiftFromSource:(Source *)source {

}

-(NSMutableArray *) filterGiftFromSource:(Source *)source
                        withSearchString:(NSString *)searchString {
    
}

-(Gift *)getGiftWithId:(NSUInteger *)gid {
    NSString * query = @"SELECT * FROM gift WHERE gid = ?";
    FMResultSet * results = [self.db executeQuery:query,gid];
    if ([results next]) {
        Gift * g = [self processGiftResultWithoutContributionList:results];
        [self updateGiftContributionForGift:g];
        return g;
    }
    return nil;
}

- (void)updateGiftContributionForGift:(Gift *)g {
    NSString * query = @"SELECT * FROM giving WHERE gid = ?";
    FMResultSet * results = [self.db executeQuery:query,g.idno];
    while ([results next]) {
        NSUInteger sourceId = [results intForColumn:@"sid"];
        float gValue = [results doubleForColumn:@"value"];
        [g.contributions addObject:[[Contribution alloc] initWithSid:sourceId value:gValue]];
    }
}

#pragma mark Gift Update
-(BOOL) updateGift:(Gift *)old newGift:(Gift *)newGift {
    
}

#pragma mark Gift Delete
-(BOOL) deleteGift:(Gift *)gift {
    
}

@end