//
//  CheckInSecondViewController.m
//  StudentsCheckIn
//
//  Created by Mars Broshok on 04/12/13.
//  Copyright (c) 2013 Mars Broshok. All rights reserved.
//

#import "PeopleManagementViewController.h"
#import "CustomFaceRecognizer.h"
#import "CreateFaceViewController.h"

@interface PeopleManagementViewController ()
@property (strong) NSMutableArray *allPeople;
@property (strong) CustomFaceRecognizer *faceRecognizer;
@end

@implementation PeopleManagementViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButton;
    self.faceRecognizer = [[CustomFaceRecognizer alloc] initWithLBPHFaceRecognizer];
    self.allPeople = self.faceRecognizer.getAllPeople;
}

- (void) viewDidAppear:(BOOL)animated
{
    self.allPeople = self.faceRecognizer.getAllPeople;
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{

    return (NSInteger)self.allPeople.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *person = [self.allPeople objectAtIndex:indexPath.row];
    NSString *personName = [person objectForKey:@"name"];
    
    static NSString *MyIdentifier = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault  reuseIdentifier:MyIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryNone;
    //UIImageView *cellImage = (UIImageView *)[cell viewWithTag:1];
    //UILabel *cellLabel = (UILabel *)[cell viewWithTag:2];
    //UIButton *cellButton = (UIButton *)[cell viewWithTag:3];
    UILabel *cellLabel = cell.textLabel;
    cellLabel.text = personName;
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"plus" ofType:@"png"];
    //cellImage.image = [UIImage imageNamed:path];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
                                           forRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSDictionary *person = [self.allPeople objectAtIndex:indexPath.row];
        int personID = [[person objectForKey:@"id"] intValue];
        [self.allPeople removeObjectAtIndex:indexPath.row];
        [self.faceRecognizer forgetPersonWithID:personID];
        
        [tableView beginUpdates]; //update our UI
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [tableView endUpdates];
    }

}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    //[self performSegueWithIdentifier: @"personDetails" sender: indexPath];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"personDetails"]) {
        CreateFaceViewController *detailViewController = [segue destinationViewController];
        NSIndexPath *indexPath = sender;
        detailViewController.person = [self.allPeople objectAtIndex:indexPath.row];
    }
}

-(IBAction)barButtonTouched:(UIBarButtonItem *)sender
{
    if (self.isEditing)
    {
        [self setEditing:NO animated:YES];
        self.navigationItem.leftBarButtonItem = self.editButton;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
    else
    {
        [self setEditing:YES animated:YES];
        self.navigationItem.leftBarButtonItem = self.doneButton;
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }
    
}

@end
