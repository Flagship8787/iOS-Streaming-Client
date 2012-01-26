//
//  AppDelegate.h
//  OccupyStreamer
//
//  Created by Sam Shapiro on 11/26/11.
//  Copyright (c) 2011 TransPerfect Translations. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CaptureViewController;

@interface AppDelegate : NSObject <UIApplicationDelegate>{
    UIWindow *window;
    
    CaptureViewController *captureControl;
}

@property (strong, nonatomic) IBOutlet UIWindow *window;

@property (strong, nonatomic) IBOutlet CaptureViewController *captureControl;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
