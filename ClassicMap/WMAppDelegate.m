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
    [self registerDefaultsFromSettingsBundle];
    
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    BOOL clearAllFileCachesOnLaunch = [defs boolForKey:@"clearAllFileCachesOnLaunch"];
    if (clearAllFileCachesOnLaunch) {
        NSLog(@"%@", @"clear caches");
        [[WMImageCache sharedInstance] deleteAllCacheFiles];
        [defs setBool:NO forKey:@"clearAllFileCachesOnLaunch"];
        [defs synchronize];
    }
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[WMImageCache sharedInstance] purgeMemoryCache];
}

- (void)registerDefaultsFromSettingsBundle
{
    NSUserDefaults * defs = [NSUserDefaults standardUserDefaults];
    [defs synchronize];
    
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if (!settingsBundle) {
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    
    for (NSDictionary *prefSpecification in preferences) {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key) {
            id currentObject = [defs objectForKey:key];
            if (!currentObject) {
                id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                [defaultsToRegister setObject:objectToSet forKey:key];
            }
        }
    }
    
    [defs registerDefaults:defaultsToRegister];
    [defs synchronize];
}

@end
