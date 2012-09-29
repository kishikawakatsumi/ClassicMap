//
//  WMAppDelegate.m
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/24.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import "WMAppDelegate.h"
#import "WMImageCache.h"
#import "AFNetworking.h"

@implementation WMAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[WMImageCache sharedInstance] deleteAllCacheFiles];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[WMImageCache sharedInstance] purgeMemoryCache];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[WMImageCache sharedInstance] deleteAllCacheFiles];
}

@end
