//
//  WebViewController.m
//  StudentsCheckIn
//
//  Created by ABDOUNI on 16/12/13.
//  Copyright (c) . ABDOUNI 2013 All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController<UIWebViewDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *backward;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *Forward;



- (IBAction)GoForward:(UIBarButtonItem *)sender;
- (IBAction)GoBackword:(UIBarButtonItem *)sender;



 @end
