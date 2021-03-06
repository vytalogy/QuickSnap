//
//  Utils.h
//  GIFTool
//
//  Created by Haris on 5/24/14.
//  Copyright (c) 2014 HarisHussain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

#define KEY_FPS             @"key_fps"
#define KEY_SEGMENT         @"key_segment"
#define KEY_INCREMENT       @"key_increment"

+ (void)removeAllFilesFromNSTemporaryDirectory;
+ (void)removeAllFilesFromNSDocumentDirectory;
+ (void)removeFileFromNSDocumentDirectory:(NSString*)fileName;

+ (NSString*)generateFileNameWithExtension:(NSString *)extensionString;

+ (NSDate *)dateFromString:(NSString *)filename;

+ (NSArray*)NSDocumentDirfiles;
+ (NSMutableDictionary*)NSDocumentDirFilesByDate;
+ (NSString *)renameFilefromName:(NSString *)oldName;
+ (void)renameFile;
+ (NSString *)filenameFromPath:(NSString *)filePath;

+ (BOOL)NSStringIsEmpty:(NSString *)string;
+ (BOOL)NSStringIsValidEmail:(NSString *)string;

+ (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;

+ (UIImage*)watermarkImage:(UIImage *)image;
+ (UIImage *)createThumbnail:(UIImage *)originalImage withSize:(CGSize)size;
+ (void)saveToPhotoAlbum:(NSString*)path;

+ (NSString*)userID;
+ (void)setUserID:(NSString*)userID;

+ (NSString*)email;
+ (void)setEmail:(NSString*)email;

+ (BOOL)isLoggedIn;
+ (void)setLoggedIn:(BOOL)loggedIn;

+ (void)setFPS:(NSDictionary *)fps;
+ (NSDictionary *)FPS;

+ (BOOL)shouldSaveToPhotoAlbum;
+ (void)setSaveToPhotoAlbum:(BOOL)shouldSave;

+ (BOOL)shouldAttachURL;
+ (void)setShouldAttachURL:(BOOL)shouldAttachURL;

+ (void)clearUserData;

@end

