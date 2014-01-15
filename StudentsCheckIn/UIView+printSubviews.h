//
//  UIView+printSubviews.h
//  StudentsCheckIn
//
//  Created by Mars Broshok on 06/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (printSubviews)
- (void)printSubviewsWithIndentation:(int)indentation;
- (void)deleteAllSubviewsWithLog;
@end
