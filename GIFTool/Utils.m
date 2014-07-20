//
//  Utils.m
//  GIFTool
//
//  Created by Haris on 5/24/14.
//  Copyright (c) 2014 HarisHussain. All rights reserved.
//

#import "Utils.h"

@implementation Utils

+ (void)removeAllFilesFromNSTemporaryDirectory {
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}


+ (void)removeAllFilesFromNSDocumentDirectory {  
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    
    for (NSString *file in filePathsArray) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", [paths objectAtIndex:0], file] error:NULL];
    }
}

+ (void)removeFileFromNSDocumentDirectory:(NSString*)filePath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *fullPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.png", filePath]];
    NSError *error;
    [fileManager removeItemAtPath:filePath error:&error];
    if (!error) {
        NSLog(@"file removed");
    } else {
        NSLog(@"Could Not Delet File at:%@ due to error:%@", filePath, error);
    }
}

+ (NSString*)generateFileNameWithExtension:(NSString *)extensionString
{
    // Extenstion string is like @".png"
    
    NSDate *time = [NSDate date];
    NSDateFormatter* df = [NSDateFormatter new];
    [df setDateFormat:@"dd-MM-yyyy-hh-mm-ss"];
    NSString *timeString = [df stringFromDate:time];
    NSString *fileName = [NSString stringWithFormat:@"File-%@%@", timeString, extensionString];
    
    return fileName;
}

+ (NSArray*)NSDocumentDirfiles {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSArray *filePathsArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:documentsDirectory  error:nil];
    
    NSMutableArray *array = [NSMutableArray new];
    
    [filePathsArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [array addObject:[documentsDirectory stringByAppendingPathComponent:obj]];
    }];
    
    NSLog(@"files array %@", array);
    
    return array;
}

+ (BOOL)NSStringIsEmpty:(NSString *)string {
    return [string isKindOfClass:[NSNull class]] || !string || [string isEqualToString:@""] || string.length <= 0;
}

+ (BOOL)NSStringIsValidEmail:(NSString *)string {
    BOOL        stricterFilter        = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString    *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString    *laxString            = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString    *emailRegex           = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest            = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:string];
}

+ (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    [[[UIAlertView alloc]
      initWithTitle:title message:message delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil] show];
}

+ (NSString*)userID {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"userID"];
}
+ (void)setUserID:(NSString*)userID {
    [[NSUserDefaults standardUserDefaults] setObject:userID forKey:@"userID"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)email {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"email"];
}
+ (void)setEmail:(NSString*)email {
    [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"email"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

+ (BOOL)isLoggedIn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"isLoggedIn"];
}
+ (void)setLoggedIn:(BOOL)loggedIn {
    [[NSUserDefaults standardUserDefaults] setBool:loggedIn forKey:@"isLoggedIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)clearUserData {
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"userID"];
    [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"email"];
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"isLoggedIn"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [Utils removeAllFilesFromNSDocumentDirectory];
}

@end