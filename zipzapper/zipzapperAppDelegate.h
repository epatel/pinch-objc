//
//  zipzapperAppDelegate.h
//  zipzapper
//
//  Created by Edward Patel on 2011-05-29.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface zipzapperAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;

- (IBAction)go:(id)sender;
- (IBAction)url:(id)sender;

@end
