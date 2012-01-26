//
//  UploadManager.m
//  OccupyStreamer
//
//  Created by Sam Shapiro on 12/1/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import "UploadManager.h"

@implementation UploadManager

@synthesize uploading, reelURL, connResponse;

- (id)initUploadManager{
    self = [super init];
    
    if(self){
        uploading = NO;
        
        reelURL = nil;
        connResponse = nil;
    }
    
    return  self;
}

- (BOOL)uploadReelToServer:(NSURL *)aReelURL{
    if(self.uploading || !aReelURL){
        return NO;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:[reelURL path]]){
        return NO;
    }
    
    //  Save the reel
    reelURL = [aReelURL retain];

    //  Upload
    uploading = YES;
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:[self postRequestForReel] delegate:self];
    [connection release];
    
    return YES;
}
- (NSURLRequest *)postRequestForReel{
    
    NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    
    [urlRequest setURL:[NSURL URLWithString:@"http://192.168.2.95:3000/playlists/save_fragment/"]];
    [urlRequest setHTTPMethod:@"POST"];
    
    NSString *boundry = [NSString stringWithString:@"---------------------------14737809831466499882746641449"];
    [urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundry] forHTTPHeaderField:@"Content-Type"];
    
    NSData *reelData = [NSData dataWithContentsOfURL:self.reelURL];
    
    NSMutableData *postData = [NSMutableData dataWithCapacity:[reelData length] + 512];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"fragment\"; filename=\"%@\"\r\n\r\n", [self.reelURL lastPathComponent]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [postData appendData:reelData];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    
    return urlRequest;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	NSLog(@"Connection did fail with error: %@", error);
    [self finishedUploadingReel];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	[connResponse appendString:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"connection did finish loading.  Response: %@", connResponse);
    [self finishedUploadingReel];
}

- (void)finishedUploadingReel{
    //  Delete the file the the reel was on
    NSError *anError;
    if(![[NSFileManager defaultManager] removeItemAtURL:self.reelURL error:&anError]){
        NSLog(@"Error deleteing file at path:%@\n%@", [self.reelURL path], anError);
    }
    
    //  Get rid of the old assets, that they may be created anew
    if(!!self.reelURL){
        [reelURL release];
        reelURL = nil;
    }
    
    if(!!self.connResponse){
        [connResponse release];
        connResponse = nil;
    }
    
    //  Now, we're done!
    uploading = NO;
}

- (void)dealloc{
    [reelURL release];
    [connResponse release];
    
    [super dealloc];
}

@end
