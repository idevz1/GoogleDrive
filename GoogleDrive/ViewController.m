//
//  ViewController.m
//  GoogleDrive
//
//  Created by George on 9/16/16.
//  Copyright © 2016 George Ciobanu. All rights reserved.
//


#import "ViewController.h"

static NSString *const kKeychainItemName = @"Drive API";
static NSString *const kClientID = @"272992205191-ta61ugo4pt4eie4r20a34ljslo1pm98l.apps.googleusercontent.com";

@implementation ViewController

@synthesize service = _service;
@synthesize output = _output;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.folderStack = [[NSMutableArray alloc]init];
    [self.folderStack addObject:@"root"];

   
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height-80)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    
    // Initialize the Drive API service & load existing credentials from the keychain if available.
    self.service = [[GTLServiceDrive alloc] init];
    self.service.authorizer =
    [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                          clientID:kClientID
                                                      clientSecret:nil];
    
    self.backBtn = [[UIButton alloc]initWithFrame:CGRectMake(20, 20, 200, 40)];
    [self.backBtn setTitle:@"Back" forState:UIControlStateNormal];
    [self.backBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted | UIControlStateFocused | UIControlStateSelected];
    self.backBtn.alpha = 0.0f;
    [self.backBtn addTarget:self action:@selector(goPreviousFolder) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backBtn];
    
}

-(void)goPreviousFolder{
    
    NSLog(@"ce plm self.fold %@", self.folderStack);
    
    if (self.folderStack.count>1)
        [self.folderStack removeObjectAtIndex:0];
    
    [self loadFolder:[self.folderStack objectAtIndex:0]];
   
    if (self.folderStack.count==1)
        self.backBtn.alpha = 0.0f;
    
}

- (void)viewDidAppear:(BOOL)animated {
    if (!self.service.authorizer.canAuthorize) {

        [self presentViewController:[self createAuthController] animated:YES completion:nil];
        
    } else {
        [self fetchFiles];
    }
}

- (void)fetchFiles {

    
    NSString *parentId = @"root";
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = [NSString stringWithFormat:@"'%@' in parents", parentId];
    query.pageSize = 10;
    query.fields = @"nextPageToken, files(id, name, mimeType, kind)";

    [self.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                  GTLDriveFileList *fileList,
                                                  NSError *error) {
        if (error == nil) {
            NSLog(@"Have results");

            self.rootObjects = [NSMutableArray arrayWithArray:fileList.files];
            self.pageToken = fileList.nextPageToken;
            
            [self.tableView reloadData];
            // Iterate over fileList.files array
        } else {
            NSLog(@"An error occurred: %@", error);
        }
    }];


}



- (GTMOAuth2ViewControllerTouch *)createAuthController {
    GTMOAuth2ViewControllerTouch *authController;

    NSArray *scopes = [NSArray arrayWithObjects:kGTLAuthScopeDrive, nil];
    authController = [[GTMOAuth2ViewControllerTouch alloc]
                      initWithScope:[scopes componentsJoinedByString:@" "]
                      clientID:kClientID
                      clientSecret:nil
                      keychainItemName:kKeychainItemName
                      delegate:self
                      finishedSelector:@selector(viewController:finishedWithAuth:error:)];
    return authController;
}


- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)authResult
                 error:(NSError *)error {
    if (error != nil) {
        [self showAlert:@"Authentication Error" message:error.localizedDescription];
        self.service.authorizer = nil;
    }
    else {
        self.service.authorizer = authResult;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)showAlert:(NSString *)title message:(NSString *)message {
    UIAlertController *alert =
    [UIAlertController alertControllerWithTitle:title
                                        message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *ok =
    [UIAlertAction actionWithTitle:@"OK"
                             style:UIAlertActionStyleDefault
                           handler:^(UIAlertAction * action)
     {
         [alert dismissViewControllerAnimated:YES completion:nil];
     }];
    [alert addAction:ok];
    [self presentViewController:alert animated:YES completion:nil];
    
}


#pragma Mark UITableViewDelegate & UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section{
    
    
    return self.rootObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static NSString *simpleTableIdentifier = @"DriveCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:simpleTableIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:simpleTableIdentifier];
    }
    
    GTLDriveFile *file = [self.rootObjects objectAtIndex:indexPath.row];

    
    cell.textLabel.text = file.name;
    
    if ([file.mimeType isEqualToString:@"application/vnd.google-apps.folder"]){
        cell.contentView.backgroundColor = [UIColor blueColor];
        cell.textLabel.textColor = [UIColor colorWithRed:0.294 green:0.748 blue:1.000 alpha:1.00];
    } else {
        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.textLabel.textColor = [UIColor blackColor];

        
    }
    
    NSLog(@"kkkx %@", file.mimeType);
    
    return cell;
    
}
- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger lastSectionIndex = [tableView numberOfSections] - 1;
    NSInteger lastRowIndex = [tableView numberOfRowsInSection:lastSectionIndex] - 1;
    if (indexPath.row == lastRowIndex) {
        // This is the last cell
        [self loadNextPage];
    }
}


-(void)loadNextPage{
    
    if (![self.pageToken isEqualToString:@""]){
        
        
        NSString *parentId = @"root";
        
        GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
        query.q = [NSString stringWithFormat:@"'%@' in parents", parentId];
        query.pageSize = 10;
        query.fields = @"nextPageToken, files(id, name, mimeType, kind)";
        query.pageToken = self.pageToken;
        [self.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                             GTLDriveFileList *fileList,
                                                             NSError *error) {
            if (error == nil) {
                
                [self.rootObjects addObjectsFromArray:fileList.files];
                
                if ([self.pageToken isEqualToString:fileList.nextPageToken] || fileList.nextPageToken.length==0){
                    self.pageToken = @"";
                }
                else
                    self.pageToken = fileList.nextPageToken;
                
                [self.tableView reloadData];
                // Iterate over fileList.files array
            } else {
                NSLog(@"An error occurred: %@", error);
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

    GTLDriveFile *file = [self.rootObjects objectAtIndex:indexPath.row];
    if ([file.mimeType isEqualToString:@"application/vnd.google-apps.folder"]){

        [self loadFolder:file.identifier];
        [self.folderStack insertObject:file.identifier atIndex:0];

    } else {
        
        NSString *url = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v3/files/%@?alt=media",
                         file.identifier];
        GTMSessionFetcher *fetcher = [self.service.fetcherService fetcherWithURLString:url];
        
        [fetcher beginFetchWithCompletionHandler:^(NSData *data, NSError *error) {
            if (error == nil) {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{

                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                    NSString *documentsDirectory = [paths objectAtIndex:0];
                    
                    
                    
                    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"test.%@", [self getExtension:file.mimeType]]];
                    
                    [[NSUserDefaults standardUserDefaults]setObject:dataPath forKey:@"dataPath"];
                    
                    [data writeToFile:dataPath atomically:YES];
                    
                    QLPreviewController *previewer = [[QLPreviewController alloc] init];
                    [previewer setDataSource:self];
                    [previewer setCurrentPreviewItemIndex:indexPath.row];
                    
                    [self presentViewController:previewer animated:YES completion:nil];
                    
                });

                // Do something with data
            } else {
                NSLog(@"An error occurred: %@", error);
            }
        }];
    }
    
    
}

-(void)loadFolder:(NSString *)folder{
    
    self.backBtn.alpha = 1.0f;
    
    
    GTLQueryDrive *query = [GTLQueryDrive queryForFilesList];
    query.q = [NSString stringWithFormat:@"'%@' in parents", folder];
    [self.service executeQuery:query completionHandler:^(GTLServiceTicket *ticket,
                                                  GTLDriveFileList *fileList,
                                                  NSError *error) {
        if (error == nil) {

            self.rootObjects = [NSMutableArray arrayWithArray:fileList.files];
            
            if ([self.pageToken isEqualToString:fileList.nextPageToken] || fileList.nextPageToken.length==0){
                self.pageToken = @"";
            }
            else
                self.pageToken = fileList.nextPageToken;
            
            
            [self.tableView reloadData];

        
        } else {
            NSLog(@"An error occurred: %@", error);
        }
    }];

    
}

#pragma Mark QLPreviewController delegate

- (NSInteger) numberOfPreviewItemsInPreviewController: (QLPreviewController *) controller
{
    return 1;
}

- (id <QLPreviewItem>)previewController: (QLPreviewController *)controller previewItemAtIndex:(NSInteger)index
{
    
    return [NSURL fileURLWithPath:[[NSUserDefaults standardUserDefaults]objectForKey:@"dataPath"]];
}

-(NSString *)getExtension:(NSString *)mimeType{
    
    
    NSString *extension = @"";
    
    if ([mimeType isEqualToString:@"image/png"])
        extension = @"png";
    if ([mimeType isEqualToString:@"text/plain"])
        extension = @"txt";
    if ([mimeType isEqualToString:@"image/jpeg"])
        extension = @"jpg";
    if ([mimeType isEqualToString:@"text/html"])
        extension = @"html";
    if ([mimeType isEqualToString:@"application/pdf"])
        extension = @"pdf";

    return extension;
}

@end

