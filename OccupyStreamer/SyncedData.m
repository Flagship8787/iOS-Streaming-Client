//
//  SyncedData.m
//  SigningView
//
//  Created by Sam Shapiro on 3/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SyncedData.h"
#import "GDataXMLNode.h"

@implementation SyncedData

@dynamic FilePath, SyncState, Synced;
@synthesize delegate, SyncResponseStr;

- (void)awakeFromInsert{
	[self setSyncState:[NSNumber numberWithInt:SyncedDataNeverSynced]];
}

/******		NSURLConnection Routines	***********/
- (BOOL)SyncDataWithServer{
    if(!self.delegate){
        return NO;
    }
    
    return YES;
}
- (BOOL)SyncDataUsingRequest:(NSURLRequest *)urlRequest{
	//	Make sure there is a delegate to notify of asyncronous events.
    if(!self.delegate){
        NSLog(@"SyncedData can't sync data without a delegate!");
        return NO;
    }
    
	if(!urlRequest){
		NSLog(@"SyncedData can't sync data without a URL Request!");
        return NO;
	}
    
  	if(!!delegate && [delegate respondsToSelector:@selector(SyncedData:willSyncWithRequest:)]){
		[delegate SyncedData:self willSyncWithRequest:urlRequest];
	}
    
   	NSURLConnection *urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    BOOL success = NO;
    
    if(!!urlConnection){
        success = YES;
        [urlConnection release];
    }

    return success;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	[self failureSyncingQBData:error];
	[SyncResponseStr release];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	if(!SyncResponseStr){
		SyncResponseStr = [[NSMutableString stringWithString:@""] retain];
	}
	
	[SyncResponseStr appendString:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
    
    NSLog(@"connection Recoeved data");
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"connection did finish loading");
	
    [self handleServerResponse:SyncResponseStr];
	[SyncResponseStr setString:@""];
}

/******
 *      Controls state flow for request/response cycle
 *          -   Communicate with the delegate 
 *          -   Update SyncState Property Accordingly
 *          -   Segway from stage to routine of the response handling
 ***********/
- (void)handleServerResponse:(NSString *)qbResponseStr{
	//	First ensure the data is handled without error
	//		- Validate XML
	//			1.) The XML is parsable as a GDataXMLObject
	//			2.) The XML contains tag <errcode>0</errcode> (indicating no Server error condition)
	//		-Save XML Response as File
    
    NSLog(@"Handling response:\n%@", qbResponseStr);
    
	if ([self handleValidationOfServerResponse:qbResponseStr] &&
        [self handleSavingOfServerResponse:qbResponseStr] && 
        [self handleParsingOfServerResponse:qbResponseStr]){
        
		[self successSyncingQBData];	
	}
}
- (BOOL)handleValidationOfServerResponse:(NSString *)xmlResponseStr{
	
    NSLog(@"validating Server Response");
    
	if(!!delegate && [delegate respondsToSelector:@selector(SyncedDataWillValidateServerResponse:)]){
		[delegate SyncedDataWillValidateServerResponse:self];
	}
	
	if(![self validateServerResponse:xmlResponseStr]){
        return NO;
    }
    
    if(!!delegate && [delegate respondsToSelector:@selector(SyncedDataDidValidateServerResponse:)]){
        [delegate SyncedDataDidValidateServerResponse:self];
    }
    
    return YES;
}
- (BOOL)handleSavingOfServerResponse:(NSString *)xmlResponseStr{

    NSLog(@"saving Server Response");
    
    if([self shouldSaveServerResponse:xmlResponseStr] == NO){
        return YES;
    }
    
    if(!!delegate && [delegate respondsToSelector:@selector(SyncedDataWillSaveServerResponse:)]){
		[delegate SyncedDataWillSaveServerResponse:self];
	}
	
	if(![self saveServerResponseAsFile:xmlResponseStr]){
        return NO; 
    }
    
    if(!!delegate && [delegate respondsToSelector:@selector(SyncedDataDidSaveServerResponse:)]){
        [delegate SyncedDataDidSaveServerResponse:self];
    }
    
    return YES;
}
- (BOOL)handleParsingOfServerResponse:(NSString *)xmlResponseStr{

    NSLog(@"parsing Server Response");
    
	if(!!delegate && [delegate respondsToSelector:@selector(SyncedDataWillParseServerResponse:)]){
		[delegate SyncedDataWillParseServerResponse:self];
	}
	
	if(![self parseServerResponseString:xmlResponseStr]){
        return NO;
    }
    
    if(!!delegate && [delegate respondsToSelector:@selector(SyncedDataDidParseServerResponse:)]){
        [delegate SyncedDataDidParseServerResponse:self];
    }
    
    return YES;
}

- (void)successSyncingQBData{
    
    NSLog(@"Success Syncing Server Data");
    
	[self setSyncState:[NSNumber numberWithInt:SyncedDataSyncedSuccessfully]];
	[self setSynced:[NSDate date]];
	
	if(!!delegate && [delegate respondsToSelector:@selector(successSyncingResource:)]){
		[delegate successSyncingResource:self];
	}
}
- (void)failureSyncingQBData:(NSError *)anError{
    NSLog(@"Failed to sync Server Data with error: %@", [anError localizedDescription]);
    
	[self setSyncState:[NSNumber numberWithInt:SyncedDataStalledOnError]];
	
	if(!!delegate && [delegate respondsToSelector:@selector(failureSyncingResource:withError:)]){
		if(!!anError){
			[delegate failureSyncingResource:self withError:anError];
            return;
		}
		
		anError = [[NSError alloc] initWithDomain:@"Error Refreshing SyncedDataObject From Server" code:100 userInfo:nil];
        
		[delegate failureSyncingResource:self withError:anError];
        [anError release];
	}
}

/******		
 *  Override-able functions for handling The actual data manipulation that goes on in during each Sync State
 ***********/
- (BOOL)validateServerResponse:(NSString *)xmlResponseStr{
	//	Create GDataXMLElement from the schema XML, and ensure all goes well
	NSError *anError;
	GDataXMLElement *schemaXMLObj = [[GDataXMLElement alloc] initWithXMLString:xmlResponseStr error:&anError];
	if(!schemaXMLObj){
		if(!anError){
			anError = [[NSError errorWithDomain:@"Failed to parse application schema XML into QBTables" code:102 userInfo:nil] autorelease];
		}
		
		[self failureSyncingQBData:anError];
		
		return NO;
	}
	
	//	Check the <errcode></errcode> and <errtext></errtext> tags to make sure that Server didn't return an error
	anError = nil;
	GDataXMLElement *errCodeElement = [schemaXMLObj firstElementForName:@"errcode"];
	if(!errCodeElement){
		anError = [NSError errorWithDomain:@"Failed Server returned invalid response XML (no <errcode> element)." code:103 userInfo:nil];
	}else if([[errCodeElement stringValue] compare:@"0" options:NSLiteralSearch] != NSOrderedSame){
		GDataXMLElement *errTextElement = [schemaXMLObj firstElementForName:@"errtext"];
		if(!!errTextElement){
			anError = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"Server Returned Error:\n%@", [errTextElement stringValue]] code:104 userInfo:nil];
		}else{
			anError = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"Server Returned Error Code:%@", [errCodeElement stringValue]] code:104 userInfo:nil];
		}
	}
	
	if(anError){
		[self failureSyncingQBData:anError];
		[anError release];
		
		[schemaXMLObj release];
		
		return NO;
	}
	
	[schemaXMLObj release];
	
	return YES;
}

- (BOOL)shouldSaveServerResponse:(NSString *)responseStr{
    return YES;
}
- (BOOL)saveServerResponseAsFile:(NSString *)xmlResponseStr{
	if(self.FilePath && [[NSFileManager defaultManager] fileExistsAtPath:self.FilePath]){
		NSError *anError;
		if([[NSFileManager defaultManager] removeItemAtPath:self.FilePath error:&anError]){
			[FilePath release];
			[self setFilePath:nil];
		}else{
			NSLog(@"Failed to remove File at Path %@ for %@\nError:\n%@", self.FilePath, [[self class] description], (anError ? [anError localizedDescription] : @"NO ERROR"));
		}
	}
	
	NSString *applicationDocumentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
	NSString *FilePathPath = [applicationDocumentsDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%f.xml", [[NSDate date] timeIntervalSince1970]]];
	
	NSData *xmlFormData = [SyncResponseStr dataUsingEncoding:NSASCIIStringEncoding];
	BOOL saveSuccess = [xmlFormData writeToFile:FilePathPath atomically:YES];
	
	if(saveSuccess){
		[self setFilePath:FilePathPath];
        [self setSyncState:[NSNumber numberWithInt:SyncedDataSavedResponseData]];
	}else{
		NSError *anError = [[NSError alloc] initWithDomain:@"Failed to save application schema XML as local file." code:101 userInfo:nil];
		[self failureSyncingQBData:anError];
		
		[anError release];
	}
	
	return saveSuccess;
}

- (BOOL)parseServerResponseString:(NSString *)xmlResponseStr{
	return YES;
}

- (void)didTurnIntoFault{
    NSLog(@"dealloc'ing a SyncedData Object");
    
    [delegate release];
    [SyncResponseStr release];
    
	NSLog(@"dealloc'ing an NSManagedObject");
    [super didTurnIntoFault];
}

@end
