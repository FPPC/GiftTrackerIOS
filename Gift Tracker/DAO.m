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
-(void) sortGift:(NSMutableArray *)gifts;

-(Source *)processSourceResult:(FMResultSet *)results;
- (Gift *) processGiftResultWithoutContributionList:(FMResultSet *)results;
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

-(void)sortGift:(NSMutableArray *)gifts {
    NSSortDescriptor * sorter = [[NSSortDescriptor alloc] initWithKey:@"date" ascending:YES];
    [gifts sortUsingDescriptors:[NSArray arrayWithObject:sorter]];
    sorter = nil;
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


// if searchString is nil or 0, we give you all Sources
-(NSMutableArray *)filterSources:(NSString *)searchString {
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    
    // empty or all space cases, return everything
    if ((searchString == nil) || ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0)) {
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

    [self.db beginTransaction];
    @try {
        if (![self.db executeUpdate:query, newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state, newSource.zip,
              newSource.business, [NSNumber numberWithBool:newSource.lobby], newSource.email, newSource.phone, [NSNumber numberWithInteger:sid]]) {
            [NSException raise:@"Updating Source Failed" format:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state,
             newSource.zip, newSource.business, newSource.lobby?@"lobbyist":@"", newSource.email, newSource.phone ];
        }
    

        NSString * content = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state,
                              newSource.zip, newSource.business, newSource.lobby?@"lobbyist":@"", newSource.email, newSource.phone];
        query = @"UPDATE source_index SET content = ? WHERE docid = ?";

        if(![self.db executeUpdate:query, content, [NSNumber numberWithInteger:sid]]) {
            [NSException raise:@"Updating Source Index Failed" format:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", newSource.name, newSource.addr1, newSource.addr2, newSource.city, newSource.state, newSource.zip, newSource.business, newSource.lobby?@"lobbyist":@"", newSource.email, newSource.phone ];
        }
        
        [self.db commit];
    }
    @catch (NSException * e) {
        [self.db rollback];
        return NO;
    }
    return YES;
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
        return NO;
    }
    return YES;
}

#pragma mark Gift Read


// Yep, we also need the contribution array so the view controller can read the value out
-(NSMutableArray *) getAllGiftFromSource:(Source *)source {
    NSMutableArray * gifts = [[NSMutableArray alloc] init];
    NSString * query = @"SELECT * FROM giving WHERE sid = ?";
    FMResultSet * resultSet = [self.db executeQuery:query,[NSNumber numberWithInt:source.idno]];
    while ([resultSet next]) {
        // get gid of the result,
        // create a full-fledge (with contribution array) gift object with it
        // add it to the array
        [gifts addObject:[self getGiftWithId:[resultSet intForColumn:@"gid"]]];
    }
    [self sortGift:gifts];
    return gifts;
}

// Empty string are taken care of here too.
// Gift contribution list are updated too
-(NSMutableArray *) filterGiftFromSource:(Source *)source
                        withSearchString:(NSString *)searchString {
    if ((searchString == nil) ||
        ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length]==0)) {
        return [self getAllGiftFromSource:source];
    }
    // Now the main dish
    // get all gift from source (inner join), take only those that match search string (another inner join).
    NSString * query = @"SELECT g.* FROM gift g \
    INNER JOIN giving gv ON gv.gid = g.gid \
    INNER JOIN source s ON s.sid = gv.sid \
    INNER JOIN gift_index i on i.docid = g.gid \
    WHERE s.sid = ? AND I.content match ?";
    
    // prep the argument
    NSString * matching = [searchString stringByAppendingString:@"*"];
    FMResultSet * resultSet = [self.db executeQuery:query,[NSNumber numberWithInt:source.idno], matching];
    
    NSMutableArray * gifts = [[NSMutableArray alloc] init];
    while ([resultSet next]) {
        Gift *g =  [self processGiftResultWithoutContributionList:resultSet];
        [self updateGiftContributionForGift:g];
        [gifts addObject:g];
    }
    [self sortGift:gifts];
    return gifts;
}


// Yep, it's a complete gift with contribution list (a gift paid by many people
-(Gift *)getGiftWithId:(NSUInteger)gid {
    NSString * query = @"SELECT * FROM gift WHERE gid = ?";
    FMResultSet * results = [self.db executeQuery:query,[NSNumber numberWithInt:gid]];
    if ([results next]) {
        Gift * g = [self processGiftResultWithoutContributionList:results];
        [self updateGiftContributionForGift:g];
        return g;
    }
    return nil;
}

- (void)updateGiftContributionForGift:(Gift *)g {
    NSString * query = @"SELECT * FROM giving WHERE gid = ?";
    FMResultSet * results = [self.db executeQuery:query,[NSNumber numberWithInt:g.idno]];
    while ([results next]) {
        NSUInteger sourceId = [results intForColumn:@"sid"];
        float gValue = [results doubleForColumn:@"value"];
        Contribution * contrib = [[Contribution alloc] initWithSid:sourceId value:gValue];
        contrib.idno = [results intForColumn:@"gvid"];
        [g.contributions addObject:contrib];
    }
}

#pragma mark Gift Update
-(BOOL) updateGift:(Gift *)old newGift:(Gift *)newGift {
    //Prep the ingredients
    NSInteger gid = old.idno;
    NSDateComponents * dateComp = [[NSCalendar currentCalendar] components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit) fromDate:newGift.date];
    NSInteger y = [dateComp year];
    NSInteger m = [dateComp month];
    NSInteger d = [dateComp day];
    
    NSString * content = [NSString stringWithFormat:@"%d/%d/%d %@",m,d,y,newGift.description];

    NSString * query = @"UPDATE gift SET year = ?, month = ?, day = ?, description = ? where gid = ?";
    NSString * query_index = @"UPDATE gift_index SET content = ? where docid =?";
    NSString * giving = @"INSERT INTO giving (sid,giv,value) VALUES (?,?,?)";
    
    //start cooking the transaction
    [self.db beginTransaction];
    @try {
        //main entry
        if(![self.db executeUpdate:query, y,m,d,newGift.description,gid]) {
            [NSException raise:@"Update gift details failed" format:@" %d/%d/%d %@",m,d,y,newGift.description ];
        }
        // the index
        if (![self.db executeUpdate:query_index, content, gid]) {
            [NSException raise:@"Update gift index failed" format:@" %d/%d/%d %@",m,d,y,newGift.description ];
        }
        // the giving
        // delete the olds, insert the new. Complete in n.
        
        // If db update query is slow, we can do n squared in here by comparing the old and new array first, then
        // only make the minimal change require. But it's complicated, very likely to be n squared, and we might
        // end up running replace all as well. Not worth complicating.
        
        //Simplest way to enforce consistency in my mind right now.
        
        //out with the old
        if (![self deleteContributionList:old]) {
            [NSException raise:@"Gift update: delete old contribution failed" format:@""];
        }
        
        // yes it can be safely put inside a transaction
        //in with the new
        for (int i = 0; i < [newGift.contributions count]; i++ ) {
            Contribution * c = newGift.contributions[i];
            if(![self.db executeUpdate:giving, c.sid,gid,c.value]) {
                [NSException raise:@"Gift update: insert new contribution failed" format:@""];
            }
        }
        [self.db commit];
    }
    @catch (NSException *e) {
        [self.db rollback];
    }
    
}

#pragma mark Gift Delete
-(BOOL) deleteGift:(Gift *)gift {
    NSString * query = @"DELETE FROM gift WHERE gid = ?";
    NSString * index = @"DELETE FROM gift_index WHERE gid = ?";
    [self.db beginTransaction];
    @try {
        if(![self deleteContributionList:gift]) {
            [NSException raise:@"Delete gift contribution error" format:@"GID: %d",gift.idno];
        }
        if (![self.db executeUpdate:query,gift.idno]) {
            [NSException raise:@"Delete Gift Error" format:@"GID: %d",gift.idno];
        }
        if (![self.db executeUpdate:index,gift.idno]) {
            [NSException raise:@"Delete Gift Index Error" format:@"GID: %d",gift.idno];
        }
        [self.db commit];
    }
    @catch (NSException *exception) {
        [self.db rollback];
    }
}

-(BOOL) deleteContributionList:(Gift *)gift {
    NSString * query = @"DELETE FROM giving WHERE gid =?";
    return [self.db executeUpdate:query, gift.idno];
}


@end