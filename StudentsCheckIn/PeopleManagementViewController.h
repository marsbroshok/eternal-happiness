//
//  CheckInSecondViewController.h
//  StudentsCheckIn
//
//  Created by Mars Broshok on 04/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PeopleManagementViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
-(IBAction)barButtonTouched:(UIBarButtonItem *)sender;

@end
