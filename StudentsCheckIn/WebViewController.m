//
//  WebViewController.m
//  StudentsCheckIn
//
//  Created by ABDOUNI on 16/12/13.
//  Copyright (c) . ABDOUNI 2013 All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()

@end

@implementation WebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.biometrics-attendance.96.lt"]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
}


#pragma mark - Actions
- (IBAction)GoForward:(UIBarButtonItem *)sender {
   [self.webView goForward];
}

- (IBAction)GoBackword:(UIBarButtonItem *)sender {
     [self.webView goBack];
}
@end
