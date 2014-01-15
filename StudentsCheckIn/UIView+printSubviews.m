//
//  UIView+printSubviews.m
//  StudentsCheckIn
//
//  Created by Mars Broshok on 06/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import "UIView+printSubviews.h"

@implementation UIView (printSubviews)
- (void)deleteAllSubviewsWithLog {
    // Get all the subviews of the current view
    NSArray *subviews = [self subviews];
    int indentation = 0;
    
    // Loop through the whole subviews array. We are using the plain-old C-like for loop,
    // just for its simplicity and also to be provided with the iteration number
    for (int i = 0; i < [subviews count]; i++) {
        
        // Get the subview at current index
        UIView *currentSubview = [subviews objectAtIndex:i];
        
        
        // We will create our description using this mutable string
        NSMutableString *currentViewDescription = [[NSMutableString alloc] init];
        
        // Indent the actual description to provide visual clue of  how deeply is the current view nested
        for (int j = 0; j <= indentation; j++) {
            [currentViewDescription appendString:@"   "];
        }
        
        // Construct the actual description string. Note that we are using just index of the current view
        // and name of its class, but it's up to you to print anything you are interested in
        // (for example the frame property using the NSStringFromCGRect(currentSubview.frame) )
        [currentViewDescription appendFormat:@"[%d]: class: '%@' deleted", i, NSStringFromClass([currentSubview class])];
        
        // Log the description string to the console
        NSLog(@"%@", currentViewDescription);
        
        [currentSubview removeFromSuperview];
    }

}

- (void)printSubviewsWithIndentation:(int)indentation {
    
    // Get all the subviews of the current view
    NSArray *subviews = [self subviews];
    
    // Loop through the whole subviews array. We are using the plain-old C-like for loop,
    // just for its simplicity and also to be provided with the iteration number
    for (int i = 0; i < [subviews count]; i++) {
        
        // Get the subview at current index
        UIView *currentSubview = [subviews objectAtIndex:i];
        
        // We will create our description using this mutable string
        NSMutableString *currentViewDescription = [[NSMutableString alloc] init];
        
        // Indent the actual description to provide visual clue of  how deeply is the current view nested
        for (int j = 0; j <= indentation; j++) {
            [currentViewDescription appendString:@"   "];
        }
        
        // Construct the actual description string. Note that we are using just index of the current view
        // and name of its class, but it's up to you to print anything you are interested in
        // (for example the frame property using the NSStringFromCGRect(currentSubview.frame) )
        [currentViewDescription appendFormat:@"[%d]: class: '%@'", i, NSStringFromClass([currentSubview class])];
        
        // Log the description string to the console
        NSLog(@"%@", currentViewDescription);
        
        // Be good memory citizen
        //[currentViewDescription release];
        
        // the 'recursiveness' nature of this method. Call it on the current subview, with greater indentation
        [currentSubview printSubviewsWithIndentation:indentation+1];
    }
}
@end
