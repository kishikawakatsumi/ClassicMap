//
//  WMDetailViewController.h
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/27.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <AddressBookUI/AddressBookUI.h>
#import <iAd/iAd.h>

@interface WMDetailViewController : UITableViewController

@property (weak, nonatomic) MKMapView *mapView;
@property (weak, nonatomic) MKPlacemark *placemark;

@end
