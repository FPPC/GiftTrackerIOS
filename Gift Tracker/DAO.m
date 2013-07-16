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


@interface DAO()
-(Source *)processResult:(FMResultSet *)results;
-(void) sortSources:(NSMutableArray *)sources;
-(void) doubleCheckLimit:(NSMutableArray *) sources;
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
        [sources addObject:[self processResult:results]];
    }
    [self sortSources:sources];
    return sources;
}

- (void) doubleCheckLimit:(NSMutableArray *)sources {
    for(Source *s in sources) {
        s.limitLeft = [self limitLeft:s];
    }
}

- (Source *) processResult:(FMResultSet * )results {
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

-(NSMutableArray *)filterSources:(NSString *)searchString {
    NSMutableArray * sources = [[NSMutableArray alloc] init];
    if (searchString == nil) {
        NSLog(@"What do you think? it's NIL!");
        return [self getAllSources];
    }
    //query
    NSString * query = @"SELECT s.* FROM source s JOIN source_index i ON i.docid = s.sid WHERE i.content match ?";
    FMResultSet *results = [self.db executeQuery:query withArgumentsInArray:[NSArray arrayWithObject:[searchString stringByAppendingString:@"*"]]];
    while ([results next]) {
        [sources addObject:[self processResult:results]];
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
    BOOL success = [self.db executeUpdate:query, s.name, s.addr1, s.addr2, s.city, s.state, s.zip,
                    s.business, [NSNumber numberWithBool:s.lobby], s.email, s.phone];
    if (success) {
        NSString * content = [NSString stringWithFormat:@"%@ %@ %@ %@ %@ %@ %@ %@ %@ %@", s.name, s.addr1, s.addr2,
                              s.city, s.state, s.zip, s.business, s.lobby?@"lobbyist":@"", s.email, s.phone];
        NSString * index_query = @"INSERT INTO source_index (docid,content) values (?, ?)";
        NSNumber * idno = [NSNumber numberWithInteger:[self.db lastInsertRowId]];
        BOOL index_success = [self.db executeUpdate:index_query, idno, content];
        success = success && index_success;
    }
    return success;
}

@end