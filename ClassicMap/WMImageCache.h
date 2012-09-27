//
//  WMImageCache.h
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/26.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^WMImageCacheResultBlock)(UIImage *image, NSData *data, NSError *error);

@interface WMImageCache : NSObject

+ (WMImageCache *)sharedInstance;

- (UIImage *)cachedImageWithPath:(NSString *)path;
- (UIImage *)imageWithURL:(NSURL *)URL block:(WMImageCacheResultBlock)block;
- (UIImage *)imageWithURL:(NSURL *)URL defaultImage:(UIImage *)defaultImage block:(WMImageCacheResultBlock)block;

- (void)storeImage:(UIImage *)image data:(NSData *)data path:(NSString *)path;
- (void)purgeMemoryCache;
- (void)deleteAllCacheFiles;

@end
