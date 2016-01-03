//
//  FSItemIndex.m
//  Disk Inventory X
//
//  Created by Tjark Derlien on 01.04.05.
//  Copyright 2005 Tjark Derlien. All rights reserved.
//

#import "FSItemIndex.h"
#import <OmniFoundation/NSString-OFExtensions.h>

@interface NSMutableDictionary(Indexing)
- (void) addObject: (id) object forTerm: (id) term; 
- (NSArray*) objectsForTerm: (id) term; 
@end

@implementation NSMutableDictionary(Indexing)

- (void) addObject: (id) object forTerm: (id) term
{
	NSMutableArray *objects = [self objectForKey: term];
	if ( objects == nil )
	{
		objects = [[NSMutableArray alloc] initWithObjects: &object count: 1];
		[self setObject: objects forKey: term];
		[objects release];
	}
	else
		[objects addObject: object];
}

- (NSArray*) objectsForTerm: (id) term
{
	return [self objectForKey: term];
}

@end

@interface FSItemIndex(Privat)
/*
- (SKIndexRef) createIndexWithName: (NSString*) indexName;
- (FSItem*) itemForDocument: (SKDocumentRef) document;
*/
@end

@implementation FSItemIndex

- (id) initWithKindStatistics: (NSDictionary*) kindStatistics;
{
	self = [super init];
	
	_displayNameIndex = [[NSMutableDictionary alloc] init];
	_displayFolderIndex = [[NSMutableDictionary alloc] init];
	_kindStatistics = [kindStatistics retain];
	
/*	_indexedItems = [[NSMutableDictionary alloc] init];
	
	//create indexes
	_displayNameIndex = [self createIndexWithName: @"DisplayNameIndex"];
	_kindNameIndex = [self createIndexWithName: @"KindNameIndex"];
	
	//create search groups
	SKIndexRef indexArray[2];
    indexArray[0] = _displayNameIndex;
    indexArray[1] = _kindNameIndex;
	
    CFArrayRef searchArray = CFArrayCreate( kCFAllocatorDefault, (void *)indexArray, 2, &kCFTypeArrayCallBacks );
	_searchGroupAll = SKSearchGroupCreate( searchArray );
	CFRelease( searchArray );
*/	
	return self;
}

- (void) dealloc
{
	[_kindStatistics release];
	[_displayNameIndex release];
	[_displayFolderIndex release];
	
/*	CFRelease( _searchGroupAll );	
	CFRelease( _displayNameIndex );
	CFRelease( _kindNameIndex );
	[_indexedItems release];
*/	
	[super dealloc];
}

- (void) addItem: (FSItem*) item
{
	[_displayNameIndex addObject: item forTerm: [[item displayName] lowercaseString]];
	[_displayFolderIndex addObject: item forTerm: [[item displayPath] lowercaseString]];
	
/*	NSString *key = [[NSString alloc] initWithFormat: @"%u", [item hash]];
	
	[_indexedItems setObject: item forKey: key];
	
    // create the Search Kit document representing the FSItem
    SKDocumentRef aDocument = SKDocumentCreate ( (CFStringRef) @"data", //document scheme
												 NULL,					//parent document
												 (CFStringRef) key );  //document name
	[key release];
	
    // add the document to the indexes
    if ( !SKIndexAddDocumentWithText( _displayNameIndex, // a reference ot the index added to 
									  aDocument, // the document we want to add
									  (CFStringRef) [item displayName], // text of the document
									  1) )   // a boolean value indicating the document can be overwritten
	{
        LOG(@"There was a problem adding '%@' to search index", [item path]);
	}
	
    // add the document to the index
    if ( !SKIndexAddDocumentWithText( _kindNameIndex, // a reference ot the index added to 
									  aDocument, // the document we want to add
									  (CFStringRef) [item kindName], // text of the document
									  1) )   // a boolean value indicating the document can be overwritten
	{
        LOG(@"There was a problem adding '%@' to search index", [item path]);
	}

	//the document is retained by the indexes, so we can release it
    CFRelease(aDocument);
*/
}

- (void) addItemsFromArray: (NSArray*) items
{
	unsigned int i = [items count];
	
	NSAutoreleasePool *localPool = (i > 200) ? [[NSAutoreleasePool alloc] init] : nil;
	
	unsigned poolLoopCount = 0;
	
	while ( i-- )
	{
		[self addItem: [items objectAtIndex: i]];
		
		poolLoopCount++;
		if ( poolLoopCount > 200 )
		{
			poolLoopCount = 0;
			[localPool release];
			localPool = [[NSAutoreleasePool alloc] init];
		}
	}
	
	[localPool release];
}

- (NSArray*) searchItems: (NSString*) searchString inIndex: (FSItemIndexType) indexesToSearch
{
	searchString = [searchString lowercaseString];
	
	NSMutableSet *items = [NSMutableSet set];
	NSEnumerator *indexEnum;
	
	//search indexes
	struct _indexTag {
		NSMutableDictionary* index; FSItemIndexType indexType;
	}
	indexes[] = { { _displayNameIndex, FSItemIndexName },
				  { _displayFolderIndex, FSItemIndexPath }
				};
	
	unsigned i;
	for ( i = 0; i < sizeof(indexes)/sizeof(indexes[0]); i++ )
	{
		if ( ( indexes[i].indexType & indexesToSearch ) != 0 )
		{
			indexEnum = [indexes[i].index keyEnumerator];
			NSString *term;	
			while ( (term = [indexEnum nextObject]) != nil )
			{
				if ( [term rangeOfString: searchString].location != NSNotFound )
					[items addObjectsFromArray: [indexes[i].index objectsForTerm: term]];
			}
		}
	}
	
	//search kinds
	if ( ( indexesToSearch & FSItemIndexKind ) != 0 )
	{
		indexEnum = [_kindStatistics objectEnumerator];
		FileKindStatistic *stat;	
		while ( (stat = [indexEnum nextObject]) != nil )
		{
			if ( [[stat kindName] rangeOfString: searchString options: NSCaseInsensitiveSearch].location != NSNotFound )
				[items unionSet: [stat items]];
		}
	}

	return [items allObjects];
	
/*	
	//before a search, flush index
	SKIndexFlush( _displayNameIndex );
	SKIndexFlush( _kindNameIndex );
	
	LOG( @"search for '%@' in indexes:", searchString );
	LOG( @"   name index: %i documents, %i terms", SKIndexGetDocumentCount(_displayNameIndex), SKIndexGetMaximumTermID(_displayNameIndex) );
	LOG( @"   kind index: %i documents, %i terms", SKIndexGetDocumentCount(_kindNameIndex), SKIndexGetMaximumTermID(_kindNameIndex) );

	//perform search
	// The function has a problem with a too large value like INT_MAX (or INT_MAX -1) for "inMaxFoundDocuments".
	// You'll get the error "malloc_zone_malloc: argument too large" or your app even crashes (EXC_BAD_ACCESS)
	// (let's see how this will change with Tiger...).

    SKSearchResultsRef searchResults
        = SKSearchResultsCreateWithQuery( _searchGroupAll,	// the search group
										  (CFStringRef) searchString, //our query
										  kSKSearchPrefixRanked,	// the kind of search
										  1000000, //1 million;  the maximum number of results
										  NULL,				// context, may be null
										  NULL);			// callback function for hit testing during searching, may be NULL
	
	//get the number of documents found by the query
	CFIndex resultCount = SKSearchResultsGetCount( searchResults );
	LOG( @"%i items found", resultCount );
	
	//get all documents in one turn
	SKDocumentRef *docArray = malloc( sizeof(SKDocumentRef) * resultCount );
    
	//retrieve document in result set
    resultCount = SKSearchResultsGetInfoInRange(searchResults,	// the search result set
												CFRangeMake(0, resultCount), // which results we're interested in seeing
												docArray,		// an array of SKDocumentRef
												NULL,			// An array of indexes in which the found docouments reside, may be NULL
												NULL);			// an array of scores
	
	
	NSMutableArray *items = [NSMutableArray arrayWithCapacity: resultCount];

    // iterate over the results
    int i;
    for ( i =0 ; i < resultCount; i++)
	{
        SKDocumentRef hit = docArray[i];

		[items addObject: [self itemForDocument: hit]];
    }
	
	free( docArray );
	
    //the search result seems to contain copies of the documents in the indexes as you get unexpected result
	//if the result is released before you access the documents in it
    CFRelease(searchResults);
	
	return items;
 */
}

@end

@implementation FSItemIndex(Privat)
/*
- (SKIndexRef) createIndexWithName: (NSString*) indexName
{
	CFMutableDataRef indexData = CFDataCreateMutable( kCFAllocatorDefault, 0 );
	
	SKIndexRef index = SKIndexCreateWithMutableData( indexData,	// data object where to store the index
													 (CFStringRef) indexName,		// a name for the index (this may be nil)
													 kSKIndexInverted,				// the type of index
													 NULL );						// and our index attributes dictionary (may be NULL)

	CFRelease( indexData );
	
	return index;
}

- (FSItem*) itemForDocument: (SKDocumentRef) document
{
	NSString *name = (NSString*) SKDocumentGetName( document );
	NSAssert( ![NSString isEmptyString: name], @"can't get name of SearchKit document" );
	
	FSItem *item = [_indexedItems objectForKey: name];
	NSAssert1( item != nil, @"FSItem object for name '%@' does not exist in set of indexed items", name );
	
	return item;
}
*/
@end

