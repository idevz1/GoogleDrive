//
//  ViewController.h
//  GoogleDrive
//
//  Created by George on 9/16/16.
//  Copyright © 2016 George Ciobanu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

#import "GTMOAuth2ViewControllerTouch.h"
#import "GTLDrive.h"

@interface ViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, QLPreviewControllerDataSource>

@property (nonatomic, strong) GTLServiceDrive *service;
@property (nonatomic, strong) UITextView *output;

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *rootObjects;
@property (nonatomic, strong) NSArray *currentPageObj;

@property (nonatomic, strong) NSString *pageToken;

@property (nonatomic, strong) NSMutableArray *folderStack;

@property (strong, nonatomic) UIButton *backBtn;


@property (strong, nonatomic) GTMOAuth2ViewControllerTouch *authController;
@end

