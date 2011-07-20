//
//  EntryViewController.h
//  zipzapper
//
//  Created by Edward Patel on 2011-05-29.
//  Copyright 2011 Memention AB. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface EntryViewController : UIViewController {
    IBOutlet UIImageView *imageView;
    IBOutlet UITextView *textView;
}

@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, readonly) UITextView *textView;

@end
