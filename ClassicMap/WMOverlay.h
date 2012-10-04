//
//  WMOverlay.h
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/26.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

enum {
    WMMapSourceStandard = 0,
    WMMapSourceGoogle
};
typedef NSUInteger WMMapSource;

@interface WMOverlay : NSObject <MKOverlay>

@property (nonatomic, readonly) MKMapType mapType;

- (id)initWithMapType:(MKMapType)mapType;
- (NSURL *)imageURLWithTilePath:(NSString *)path;

@end
