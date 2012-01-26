//
//  CaptureViewController.m
//  OccupyStreamer
//
//  Created by Sam Shapiro on 11/26/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import "CaptureViewController.h"

#import "RecordingManager.h"
#import "UploadManager.h"

@implementation CaptureViewController

@synthesize recordButt, captureSession, recordingManager, uploadManager;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Custom initialization
    }
    
    return self;
}

- (void)didReceiveMemoryWarning{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc{
    [recordButt release];
    
    [captureSession release];
    [recordingManager release];
    
    [super dealloc];
}

#pragma mark - 
#pragma mark - View lifecycle
- (void)viewDidLoad{
    [super viewDidLoad];
    
    captureSession = nil;
    recordingManager = nil;
    uploadManager = nil;
    
    [self.view setBackgroundColor:[UIColor greenColor]];
    [self initializeCaptureSession];
}
- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    if(!!self.captureSession){
        [self.captureSession startRunning];
    }
}

- (void)viewDidUnload{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - 
#pragma mark - AVCaptureSession Configuration
- (void)initializeCaptureSession{
    //  Set nils
    captureSession = nil;
    recordingManager = nil;
    
    //  Get the input devices
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if(!audioDevice || !videoDevice){
        NSLog(@"Failed to get an audio and video capture device");
        return;
    }
    
    NSError *audioError;
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&audioError];
    if(!audioInput){
        NSLog(@"Failed to create AVCaptureDeviceInput (for audio device) with error:\n%@", audioError);
        return;
    }
    
    NSError *videoError;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&videoError];
    if(!videoInput){
        NSLog(@"Failed to create AVCaptureDeviceInput (for video device) with error:\n%@", videoError);
        return;
    }
    
    //  get the captureSession
    captureSession = [[[AVCaptureSession alloc] init] retain];
    [captureSession addInput:audioInput];
    [captureSession addInput:videoInput];
    
    //  Create the preview layer
    AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:captureSession];
    previewLayer.frame = self.view.bounds;
    
    [self.view.layer addSublayer:previewLayer];
    
    //  Add the button
    CGFloat buttX = (self.view.frame.size.width - self.recordButt.frame.size.width) / 2;
    CGFloat buttY = self.view.frame.size.height - (15.0 + self.recordButt.frame.size.height);
    
    CGFloat buttW = recordButt.frame.size.width;
    CGFloat buttH = recordButt.frame.size.height;
    
    recordButt.frame = CGRectMake(buttX, buttY, buttW, buttH);
    [self.view addSubview:recordButt];
}

#pragma mark - 
#pragma mark - Recording
- (IBAction)toggleRecording:(id)sender{
    if(!!self.recordingManager && self.recordingManager.recording){
        [self stopRecording];
    }else{
        [self startRecording];
    }
}

- (void)startRecording{
    //  Release the previously held assets
    if(!!self.recordingManager){
        [recordingManager release];
        recordingManager = nil;
    }
    
    if(!!self.uploadManager){
        [uploadManager release];
        uploadManager = nil;
    }
    
    //  Create the RecordingManager
    recordingManager = [[[RecordingManager alloc] initWithAVCaptureSession:self.captureSession] retain];
    [recordingManager setDelegate:self];
    
    [self.recordingManager startRecording];
    [self.recordButt setTitle:@"Stop Recording" forState:UIControlStateNormal];
}
- (void)stopRecording{
    [self.recordingManager stopRecording];
    
    [self.recordButt setTitle:@"Start Recording" forState:UIControlStateNormal];
}

#pragma mark - 
#pragma mark - RecordingManagerDelegate
- (void)RecordingManager:(RecordingManager *)aRecordingManager savedReelAtURL:(NSURL *)aReelURL{
    if(!self.uploadManager){
        uploadManager = [[[UploadManager alloc] initUploadManager] retain];
    }
    
    [uploadManager uploadReelToServer:aReelURL];
}

@end
