//
//  RecordingManager.m
//  OccupyStreamer
//
//  Created by Sam Shapiro on 11/26/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import "RecordingManager.h"
#import "AppDelegate.h"

#define kInitialLag 2
#define kReelLength 6

@implementation RecordingManager

@synthesize delegate, captureOutput, capDirURL, recording, reelTimer, reelTime, reelCount;

+ (NSURL *)NewCaptureDirURL:(NSError **)anError{
    NSString *capFileName = [NSString stringWithFormat:@"Capture_%d", [[NSDate date] timeIntervalSince1970]];
    NSURL *newCapDirURL = [[(AppDelegate *)[[UIApplication sharedApplication] delegate] applicationDocumentsDirectory] URLByAppendingPathComponent:capFileName];
    
    if([[NSFileManager defaultManager] createDirectoryAtURL:newCapDirURL withIntermediateDirectories:NO attributes:nil error:anError]){
        return newCapDirURL;
    }
    
    return nil;
}

- (id)initWithAVCaptureSession:(AVCaptureSession *)aSession{
    if(!aSession){
        return nil;
    }
    
    self = [super init];
    
    if(!!self){
        delegate = nil;
        
        recording = NO;
        
        capDirURL = nil;
        reelTimer = nil;
        reelCount = 0;
        
        AVCaptureMovieFileOutput *anOutput = [[AVCaptureMovieFileOutput alloc] init];
        if(![aSession canAddOutput:anOutput]){
            [anOutput release];
            return nil;
        }
        
        captureOutput = [anOutput retain];
        [aSession addOutput:captureOutput];
        
        captureOutput.maxRecordedDuration   = CMTimeMake(6, 1);
        captureOutput.movieFragmentInterval = CMTimeMake(3, 1);
    }
    
    return self;
}

- (void)dealloc{
    [delegate release];
    
    [captureOutput release];
    [capDirURL release];
    
    [reelTimer release];
    
    [super dealloc];
}

- (BOOL)startRecording{
    //  Return if we're already recording
    if(self.recording){
        return NO;
    }
    
    //  Check for delegate
    if(!self.delegate){
        return NO;
    }
    
    //  Release existing assets
    if(!!self.reelTimer){
        if([self.reelTimer isValid]){
            [self.reelTimer invalidate];
        }
        
        [reelTimer release];
        reelTimer = nil;
    }
    
    if(!!self.capDirURL){
        [capDirURL release];
        capDirURL = nil;
    }
    
    //  Get a directory to store the captured files in
    NSError *anError;
    NSURL *aURL = [RecordingManager NewCaptureDirURL:&anError];
    if(!aURL){
        UIAlertView *alView = [[UIAlertView alloc] initWithTitle:@"Error" message:[NSString stringWithFormat:@"Failed to create obtain a directory to store the capture reels: %@", anError] delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil];
        [alView show];
        [alView release];
        
        return NO;
    }
    
    capDirURL = [aURL retain];

    //  Get the timer running
    reelTimer = 0;
    reelCount = 0;
    
    //  Start the Recording
    recording = YES;
    
    //  Start the event scheduler
    reelTimer = [[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES] retain];
    
    return YES;
}
- (void)stopRecording{
    recording = NO;
    
    if(!!self.reelTimer && [self.reelTimer isValid]){
        [self.reelTimer invalidate];
    }
    
    if(!!self.captureOutput && self.captureOutput.recording){
        [self.captureOutput stopRecording];
    }
}

//  Capture Output's Delegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"Capture output did start Recording!");
    reelCount++;
}
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
    NSLog(@"Capture output did finish!");
    
    if(!!error){
        NSLog(@"Finish captuing error: %@\n%@", [error localizedDescription], error);
        return;
    }
    
    if(recording){
        NSLog(@"Still recording.  Adding another reel (%d.mp4).", reelCount);
        
        NSURL *reelURL = [capDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%d.mp4", reelCount]];
        [self.captureOutput startRecordingToOutputFileURL:reelURL recordingDelegate:self];
    }
    
    [self uploadReelAtURL:outputFileURL];
}

//  Timer's Selector
- (void)handleTimer:(NSTimer *)theTimer{
    reelTime++;
    
    NSLog(@"Reel Time: %d Reel Count: %d", reelTime, reelCount);
    
    //  Don't start recording until the lag time's elapsed
    if(reelTime < kInitialLag){
        return;
    }
    
    //  Pass control to the reel switching if the initial Lag's elapsed, or we've been recording for 15 seconds
    if(reelTime == kInitialLag){
        NSLog(@"Starting first reel.");
        [self.captureOutput startRecordingToOutputFileURL:[capDirURL URLByAppendingPathComponent:@"0.mp4"] recordingDelegate:self];
    }
    
    if(reelTime > kInitialLag && ((reelTime - kInitialLag) % kReelLength) == 0){
        NSLog(@"Stopping reel no: %d", reelCount);
        [self.captureOutput stopRecording];
    }
}

//  Uploading the mp4's
NSMutableString *uploadResponse = nil;
- (void)uploadReelAtURL:(NSURL *)reelURL{
    if(!!uploadResponse){
        [uploadResponse release];
        uploadResponse = nil;
    }
    
    NSURLRequest *urlRequest = [self postRequestForReelData:[NSData dataWithContentsOfURL:reelURL] withFilename:[NSString stringWithFormat:@"%d.mp4", reelCount]];
    NSURLConnection *netconnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    
    [netconnection release];
}
- (NSURLRequest *)postRequestForReelData:(NSData *)reelData withFilename:(NSString *)fileName{
    
    NSMutableURLRequest *urlRequest = [[[NSMutableURLRequest alloc] init] autorelease];
    
    [urlRequest setURL:[NSURL URLWithString:@"http://192.168.2.73:3000/playlists/save_fragment/"]];
    [urlRequest setHTTPMethod:@"POST"];
    
    NSString *boundry = [NSString stringWithString:@"---------------------------14737809831466499882746641449"];
    [urlRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundry] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData *postData = [NSMutableData dataWithCapacity:[reelData length] + 512];
    [postData appendData:[[NSString stringWithFormat:@"--%@\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"fragment\"; filename=\"%@\"\r\n\r\n", fileName] dataUsingEncoding:NSUTF8StringEncoding]];
    [postData appendData:reelData];
    [postData appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundry] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [urlRequest setHTTPBody:postData];
    
    return urlRequest;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
	NSLog(@"Connection did fail with error: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	if(!uploadResponse){
		uploadResponse = [[NSMutableString stringWithString:@""] retain];
	}
	
	[uploadResponse appendString:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
    
    NSLog(@"connection Recoeved data");
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"connection did finish loading.  Response: %@", uploadResponse);
}

@end
