//
//  WMConfigurationViewController.h
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/24.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "WMOverlay.h"

@protocol WMConfigurationViewControllerDelegate;

@interface WMConfigurationViewController : UIViewController

@property (weak, nonatomic) id<WMConfigurationViewControllerDelegate> delegate;
@property (assign, nonatomic) WMMapSource mapSource;
@property (assign, nonatomic) MKMapType mapType;

@end

@protocol WMConfigurationViewControllerDelegate <NSObject>

- (void)configurationViewController:(WMConfigurationViewController *)controller mapSourceChanged:(WMMapSource)mapSource;
- (void)configurationViewController:(WMConfigurationViewController *)controller mapTypeChanged:(MKMapType)mapType;
- (void)configurationViewControllerWillAddPin:(WMConfigurationViewController *)controller;
- (void)configurationViewControllerWillPrintMap:(WMConfigurationViewController *)controller;

@end