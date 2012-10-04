//
//  WMMasterViewController.h
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/24.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import "WMOverlayConstants.h"
#import "WMConfigurationViewController.h"

@interface WMMapViewController : UIViewController <MKMapViewDelegate, WMConfigurationViewControllerDelegate>

@property (assign, nonatomic) MKMapType mapType;
@property (assign, nonatomic) WMMapSource mapSource;

@end
