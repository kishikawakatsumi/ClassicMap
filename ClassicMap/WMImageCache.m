//
//  WMImageCache.m
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/26.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import "WMImageCache.h"
#import "AFNetworking.h"
#import <CommonCrypto/CommonHMAC.h>

@interface WMImageCache () {
    NSFileManager *fileManager;
    NSString *cacheDirectory;
    
    NSCache *cache;
    NSOperationQueue *networkQueue;
}

@end

@implementation WMImageCache

+ (WMImageCache *)sharedInstance
{
    static WMImageCache *sharedInstance;
    static dispatch_once_t pred;
    dispatch_once(&pred, ^{
        sharedInstance = [[WMImageCache alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
        cache = [[NSCache alloc] init];
        cache.countLimit = 400;
        
        fileManager = [[NSFileManager alloc] init];
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        cacheDirectory = [[paths lastObject] stringByAppendingPathComponent:@"Images"];
        
        [self createDirectories];
        
        networkQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)createDirectories
{
    BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
    if (!exists || !isDirectory) {
        [fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    for (int i = 0; i < 16; i++) {
        for (int j = 0; j < 16; j++) {
            NSString *subDir = [NSString stringWithFormat:@"%@/%X%X", cacheDirectory, i, j];
            BOOL isDir = NO;
            BOOL existsSubDir = [fileManager fileExistsAtPath:subDir isDirectory:&isDir];
            if (!existsSubDir || !isDir) {
                [fileManager createDirectoryAtPath:subDir withIntermediateDirectories:YES attributes:nil error:nil];
            }
        }
    }
}

- (void)didReceiveMemoryWarning:(NSNotification *)note
{
    [self purgeMemoryCache];
}

#pragma mark -

- (UIImage *)cachedImageWithPath:(NSString *)path
{
    NSString *key = [self keyForPath:path];
    UIImage *cachedImage = [cache objectForKey:key];
    if (cachedImage) {
        return cachedImage;
    }
    
    cachedImage = [UIImage imageWithContentsOfFile:[self filePathForKey:key]];
    if (cachedImage && key) {
        [cache setObject:cachedImage forKey:key];
    }
    
    return cachedImage;
}

#pragma mark -

- (UIImage *)imageWithURL:(NSURL *)URL block:(WMImageCacheResultBlock)block
{
    return [self imageWithURL:URL defaultImage:nil block:block];
}

- (UIImage *)imageWithURL:(NSURL *)URL defaultImage:(UIImage *)defaultImage block:(WMImageCacheResultBlock)block
{
    if (!URL) {
        return defaultImage;
    }
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5.0];
    request.HTTPShouldUsePipelining = YES;
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         NSHTTPURLResponse *response = operation.response;
         NSData *data = operation.responseData;
         if ([response statusCode] == 200 && data) {
             UIImage *image = [UIImage imageWithData:data];
             if (block) {
                 block(image, data, nil);
             }
         } else {
             block(nil, nil, nil);
         }
     } failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         block(nil, nil, error);
     }];
    
    [networkQueue addOperation:op];
    
    return defaultImage;
}

#pragma mark -

- (void)storeImage:(UIImage *)image data:(NSData *)data path:(NSString *)path
{
    NSString *key = [self keyForPath:path];
    if (!key || !image) {
        return;
    }
    [cache setObject:image forKey:key];
    
    if (data) {
        [data writeToFile:[self filePathForKey:key] atomically:YES];
    }
}

- (void)purgeMemoryCache
{
    [cache removeAllObjects];
}

- (void)deleteAllCacheFiles
{
    [cache removeAllObjects];
    
    if ([fileManager fileExistsAtPath:cacheDirectory]) {
        if ([fileManager removeItemAtPath:cacheDirectory error:nil]) {
            [self createDirectories];
        }
    }
    
    BOOL isDirectory = NO;
    BOOL exists = [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
    if (!exists || !isDirectory) {
        [fileManager createDirectoryAtPath:cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

#pragma mark -

- (NSString *)keyForPath:(NSString *)path
{
	if (path.length == 0) {
		return nil;
	}
	const char *cStr = [path UTF8String];
	unsigned char result[16];
	CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]];
}

- (NSString *)filePathForKey:(NSString *)key
{
    NSString *filePath = [NSString stringWithFormat:@"%@/%@/%@", cacheDirectory, [key substringToIndex:2], key];
    return filePath;
}

@end
