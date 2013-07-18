//
//  DAO.m
//  Gift Tracker
//
//  Created by Tam Do on 7/11/13.
//  Copyright (c) 2013 Fair Political Practices Commission. All rights reserved.
//

#import "DAO.h"
#import "FMDatabase.h"
#import "FMResultSet.h"
#import "Source.h"
#import "Utility.h"
#import "giftAppDelegate.h"
#import "Gift.h"


@interface DAO()
-(Source *)processSourceResult:(FMResultSet *)results;
-(Gift *) processGiftResult:(FMResultSet *)results;
-(void) sortSources:(NSMutableArray *)sources;
-(void) doubleCheckLimit:(NSMutableArray *) sources;
-(void) cleanupOrphanedGift;
-(void) updateGiftContributionForGift:(Gift *)g fromResults:(FMResultSet *)results;
@end

@implementation DAO

const double LIMIT = 440.0;
const double LOBBY_LIMIT = 10.0;


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

-(void)sortSources:(NSMutableArray *)sources {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"limitLeft" ascending:YES];
    [sources sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    sortDescriptor = nil;
}

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

- (void) doubleCheckLimit:(NSMutableArray *)sources {
    for(Source *s in sources) {
        s.limitLeft = [self limitLeft:s];
    }
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

- (Gift *) processGiftResult:(FMResultSet *)results {
    Gift * g = [[Gift alloc] init];
    s.description = [results stringForColumn:@"description"];
    NSInteger idno = [results intForColumn:@"gid"];
    NSInteger y = [results intForColumn:@"year"];
    NSInteger m = [results intForColumn:@"month"];
    NSInteger d = [results intForColumn:@"day"];
    
    NSDateComponents * dateComp = [[NSDateComponents alloc] init];
    
    NSCalendar * cal = [NSCalendar currentCalendar];
    
    [dateComp setYear:y];
    [dateComp setMonth:m];
    [dateComp setDay:d];
    g.date = [cal dateFromComponents:dateComp];
    
}

- (void)updateGiftContributionForGift:(Gift *)g fromResults:(FMResultSet *)results {
    
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
            float value = [(NSNumber*)g.contributions[i] floatValue];
            NSInteger sid = [(NSNumber *) g.contributors[i] integerValue];
            
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

-(Gift *)getGiftWithId:(NSUInteger *)gid {
    Gift * g = [[Gift alloc] init];
    NSString * query = @"SELECT * FROM gift WHERE gid = ?";
    NSString * giving_query = @"SELECT * FROM giving WHERE gid = ?";
    FMResultSet * results = [self.db executeQuery:query,gid];
    if ([results next]) {
        [self processGiftResult:results];
    }
}

-

@end