//
//  GIFManager.m
//  QuickSnap
//
//  Created by Haris on 7/17/14.
//  Copyright (c) 2014 HarisHussain. All rights reserved.
//

#import "GIFManager.h"
#import "AFNetworking.h"
#import "Utils.h"
#import "SVProgressHUD.h"

#define KEY_FILE_ID             @"id"
#define KEY_FILE_NAME           @"file_name"
#define KEY_FILE_ORIGINAL_NAME  @"gifs_filename_original"
#define KEY_FILE_SERVER_URL     @"url"

@implementation GIFManager

@synthesize isAllFilesDownloaded;

+ (GIFManager *)shared {
    static dispatch_once_t onceQueue;
    static GIFManager *gIFManager = nil;
    
    dispatch_once(&onceQueue, ^{ gIFManager = [[self alloc] init]; });
    return gIFManager;
}

- (void)getList {
    
    if ([Utils isLoggedIn]) {
        NSMutableDictionary *list = [NSMutableDictionary new];
        
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        NSDictionary *parameters = @{@"key": @"123456789",
                                     @"get": @"list",
                                     @"id": [Utils userID]
                                     };
//        www.plego.info/quick_snap/api.php
        [manager POST:@"http://aceist.com/gifs/api.php"
           parameters:parameters
              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                  NSNumber * success = responseObject[@"header"][@"status"];
                  
                  if (success.boolValue) {
                      NSArray *array =responseObject[@"body"][@"list"];
                      [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                          File *file = [File objectWithDictionary:obj];
                          [list setObject:file forKey:file.fileName];
                      }];
                      
                      [self setFiles:list];
                      isAllFilesDownloaded = NO;
                      
                      [self checkLocalFiles];
                      
                  } else {
                      
                  }
                  
//                  NSLog(@"JSON: %@", responseObject);
              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                  [Utils showAlertWithTitle:nil andMessage:error.localizedDescription];
                  NSLog(@"Error: %@", error);
              }];
    }
}

- (void)checkLocalFiles {
    NSMutableSet *localFile = [NSMutableSet setWithArray:[Utils NSDocumentDirfiles]];
    NSMutableSet *fileNames = [NSMutableSet new];
    NSMutableDictionary *uploadedFiles = self.files;
    NSMutableSet *uploadedKeys = [NSMutableSet setWithArray:uploadedFiles.allKeys];
    
    [[localFile allObjects] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSString *fileName = [[obj componentsSeparatedByString:@"/"] lastObject];
        [fileNames addObject:fileName];
    }];
    
    NSSet *set = fileNames;
    
    if (uploadedKeys.count == fileNames.count && [set isEqualToSet:uploadedKeys]) {
        isAllFilesDownloaded = YES;
        return;
    }
    
    if ([uploadedKeys allObjects].count > fileNames.count || ![set isEqualToSet:uploadedKeys]) {
        for (int i = 0 ; i < uploadedKeys.count ; i++) {
            if (![fileNames containsObject:[uploadedKeys allObjects][i]]) {
                File *file = uploadedFiles[[uploadedKeys allObjects][i]];
                [self downloadGIF:file.url];
                break;
            }
        }
    }
    
    if (uploadedKeys.count < [fileNames allObjects].count || ![set isEqualToSet:uploadedKeys]) {
        
        for (int i = 0 ; i < [fileNames allObjects].count ; i++) {
            if (![uploadedKeys containsObject:[fileNames allObjects][i]]) {
                
                
                NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                                      inDomain:NSUserDomainMask
                                                                             appropriateForURL:nil
                                                                                        create:NO
                                                                                         error:nil];
                
                NSURL *fileURL = [documentsDirectoryURL URLByAppendingPathComponent:[fileNames allObjects][i]];
                
                File *newFile = [File objectWithDictionary:@{KEY_FILE_NAME: [fileNames allObjects][i]}];
                
                NSMutableDictionary *dic = self.files;
                
                [dic setObject:newFile forKey:newFile.fileName];
                self.files = dic;
                
                [self uploadGIF:fileURL.relativePath];
                break;
            }
        }
    }
}

- (void)downloadGIF:(NSString*)url {
    if (!self.downloadtasks) self.downloadtasks = [NSMutableSet new];
    
//    NSString *fileanme = [[url componentsSeparatedByString:@"/"] lastObject];
    
//    NSLog(@"File To Be Downloaded - %@", fileanme);
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    NSURL *URL = [NSURL URLWithString:url];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                                              inDomain:NSUserDomainMask
                                                                     appropriateForURL:nil
                                                                                create:NO
                                                                                 error:nil];
        
        NSString *downlaodedFileName = [[[response suggestedFilename] componentsSeparatedByString:@"_"] lastObject];
        
        return [documentsDirectoryURL URLByAppendingPathComponent:downlaodedFileName];
        
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        if (!isAllFilesDownloaded) [self checkLocalFiles];
        
        [self.delegate fileDownloaded];
//        NSLog(@"File downloaded to: %@", filePath);
    }];
    
    [self.downloadtasks addObject:downloadTask];
    
    [downloadTask resume];
        [manager setDownloadTaskDidWriteDataBlock:^(NSURLSession *session, NSURLSessionDownloadTask *downloadTask, int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
            
            [self.delegate downloadTask: (float)totalBytesWritten / (float)totalBytesExpectedToWrite];
            
//            NSLog(@"Downloading %@ - %lli / %lli",fileanme, totalBytesWritten , totalBytesExpectedToWrite);
            if (totalBytesWritten == totalBytesExpectedToWrite) {
                [self.downloadtasks removeObject:downloadTask];
            }
    }];
    
}

- (void)uploadGIF:(NSString*)path {
    NSString *fileanme = [[path componentsSeparatedByString:@"/"] lastObject];
    
    NSDictionary *parameters = @{@"key": @"123456789",
                                 @"get": @"upload",
                                 @"id": [Utils userID]};
    
    // 1. Create `AFHTTPRequestSerializer` which will create your request.
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    
    // 2. Create an `NSMutableURLRequest`.
    NSMutableURLRequest *request = [serializer multipartFormRequestWithMethod:@"POST"
                                                                    URLString:@"http://aceist.com/gifs/api.php"
                                                                   parameters:parameters
                                                    constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
                                                        
                                                        [formData appendPartWithFileURL:[NSURL fileURLWithPath:path]
                                                                                   name:@"filename"
                                                                               fileName:fileanme
                                                                               mimeType:@"image/gif"
                                                                                  error:nil];
                                                    } error:nil];
    
    // 3. Create and use `AFHTTPRequestOperationManager` to create an `AFHTTPRequestOperation` from the `NSMutableURLRequest` that we just created.
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    AFHTTPRequestOperation *operation =
    [manager HTTPRequestOperationWithRequest:request
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
//                                         NSLog(@"Success %@", responseObject);
                                         
                                         NSNumber * success = responseObject[@"header"][@"status"];
                                         
                                         if (success.boolValue) {
                                             NSMutableDictionary *uploadedGIFs = self.files;
                                             
                                             File *newFile = [File objectWithDictionary:responseObject[@"body"][@"gif"]];
                                             
                                             [uploadedGIFs setObject:newFile forKey:newFile.fileName];
                                             self.files = uploadedGIFs;
                                             
                                             if (!isAllFilesDownloaded) [self checkLocalFiles];
                                         } else {
                                             //                                             [Utils showAlertWithTitle:nil andMessage:responseObject[@"header"][@"message"]];
                                         }
                                         
                                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         NSLog(@"Failure %@", error.description);
                                     }];
    
    // 4. Set the progress block of the operation.
    [operation setUploadProgressBlock:^(NSUInteger __unused bytesWritten,
                                        long long totalBytesWritten,
                                        long long totalBytesExpectedToWrite) {
        NSLog(@"Uploading %@ %lld/%lld", fileanme, totalBytesWritten, totalBytesExpectedToWrite);
    }];
    
    // 5. Begin!
    [operation start];
}

- (NSMutableDictionary *)files
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [defaults objectForKey:@"uploadedGIFs"];
    NSMutableDictionary *dictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    [defaults synchronize];
    return dictionary;
}

- (void)setFiles:(NSMutableDictionary *)aFiles
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:aFiles];
    [defaults setObject:data forKey:@"uploadedGIFs"];
    [defaults synchronize];
}

- (void)deleteGIF:(NSString*)path completionHandler:(void (^)())completion{
    
//    NSString *fileanme = [[path componentsSeparatedByString:@"/"] lastObject];
    
//    File *file = self.files[fileanme];
//    
//    if (file && file.Id) {
//        [SVProgressHUD showWithStatus:@"Deleting.."];
    
//        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//        NSDictionary *parameters = @{@"key": @"123456789",
//                                     @"get": @"delete",
//                                     @"id": file.Id};
//        [manager POST:@"http://aceist.com/gifs/api.php" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
////            NSLog(@"JSON: %@", responseObject);
//            [SVProgressHUD dismiss];
//            
//            NSNumber * success = responseObject[@"header"][@"status"];
//            
//            if (success.boolValue) {
//                NSMutableDictionary *uploadedGIFs = self.files;
//                [uploadedGIFs removeObjectForKey:fileanme];
//                self.files = uploadedGIFs;
    
                [Utils removeFileFromNSDocumentDirectory:path];
                
                completion();
                
//            }
//            
//            else {
//                [Utils showAlertWithTitle:nil andMessage:responseObject[@"header"][@"message"]];
//            }
//            
//        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//            [SVProgressHUD dismiss];
//            [Utils showAlertWithTitle:nil andMessage:error.localizedDescription];
//            NSLog(@"Error: %@", error);
//        }];
//    } else {
//        [Utils showAlertWithTitle:@"QuickSnap Delete Error" andMessage:@"Data is Syncing with Server, please wait a while before trying again."];
//    }
}


@end

@implementation File

@synthesize Id;
@synthesize fileName;
@synthesize fileNameOriginal;
@synthesize gifsCreated;
@synthesize url;

+ (id) objectWithDictionary:(NSDictionary*)dictionary
{
    id obj = [[File alloc] initWithDictionary:dictionary];
    return obj;
}

- (id) initWithDictionary:(NSDictionary*)dictionary
{
    self=[super init];
    if(self)
    {
        Id = [dictionary objectForKey:KEY_FILE_ID];
        fileName = [dictionary objectForKey:KEY_FILE_NAME];
        fileNameOriginal = [dictionary objectForKey:KEY_FILE_ORIGINAL_NAME];
        gifsCreated = [dictionary objectForKey:@"gifs_created"];
        url = [dictionary objectForKey:KEY_FILE_SERVER_URL];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.Id forKey:@"id"];
    [encoder encodeObject:self.fileName forKey:@"fileName"];
    [encoder encodeObject:self.fileNameOriginal forKey:@"fileNameOriginal"];
    [encoder encodeObject:self.gifsCreated forKey:@"gifsCreated"];
    [encoder encodeObject:self.url forKey:@"url"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.Id = [decoder decodeObjectForKey:@"id"];
        self.fileName = [decoder decodeObjectForKey:@"fileName"];
        self.fileNameOriginal = [decoder decodeObjectForKey:@"fileNameOriginal"];
        self.gifsCreated = [decoder decodeObjectForKey:@"gifsCreated"];
        self.url = [decoder decodeObjectForKey:@"url"];
    }
    return self;
}


@end
