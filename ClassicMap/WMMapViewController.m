//
//  WMMasterViewController.m
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/24.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import "WMMapViewController.h"
#import "WMDetailViewController.h"
#import "WMConfigurationViewController.h"
#import "WMPlacemark.h"
#import "WMOverlay.h"
#import "WMOverlayView.h"
#import "AFNetworking.h"

@interface WMMapViewController () <UISearchBarDelegate, MKMapViewDelegate, WMConfigurationViewControllerDelegate> {
    WMPlacemark *droppedPin;
}

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchBarBarButtonItem;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *dimView;
@property (weak, nonatomic) IBOutlet UIToolbar *topToolbar;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) WMOverlay *overlay;

@end

@implementation WMMapViewController

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Map", nil);
    _searchBar.placeholder = NSLocalizedString(@"Search or Address", nil);
    UIBarButtonItem *userTrackingButton = [[MKUserTrackingBarButtonItem alloc] initWithMapView:_mapView];
    UIBarButtonItem *configurationButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPageCurl target:self action:@selector(configure:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        _topToolbar.items = @[flexibleSpace, userTrackingButton, _searchBarBarButtonItem];
    } else {
        [self.navigationController setNavigationBarHidden:YES animated:YES];
        _toolbar.items = @[userTrackingButton, flexibleSpace, configurationButton];
    }
    
    self.mapSource = WMMapSourceGoogle;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [self restoreSessionState];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self saveSessionState];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _mapView.showsUserLocation = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
    self.searchBar = nil;
    self.searchBarBarButtonItem = nil;
    self.mapView = nil;
    self.dimView = nil;
    self.topToolbar = nil;
    self.toolbar = nil;
    self.overlay = nil;
    [super viewDidUnload];
}

#pragma mark -

- (void)refresh {
    [_mapView removeOverlay:_overlay];
    
    if (_mapSource == WMMapSourceGoogle) {
        self.overlay = [[WMOverlay alloc] initWithMapType:_mapType];
        [_mapView addOverlay:_overlay];
    }
}

- (void)setMapSource:(WMMapSource)mapSource {
    _mapSource = mapSource;
    [self refresh];
}

- (void)setMapType:(MKMapType)mapType {
    _mapType = mapType;
    _mapView.mapType = mapType;
    
    [self refresh];
}

#pragma mark -

- (void)configure:(id)sender {
    [self performSegueWithIdentifier:@"Configure" sender:self];
}

#pragma mark -

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^
     {
         _dimView.alpha = 0.7f;
     } completion:nil];
    return YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSArray *annotations = _mapView.annotations;
    for (id annotation in annotations) {
        if (annotation != _mapView.userLocation) {
            [_mapView removeAnnotation:annotation];
        }
    }

    NSString *searchString = [searchBar.text stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=true", searchString]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *status = [JSON valueForKeyPath:@"status"];
        if ([status isEqualToString:@"OK"]) {
            NSArray *results = [JSON valueForKeyPath:@"results"];
            NSInteger index = 0;
            for (id result in results) {
                CLLocationCoordinate2D coord = [self coordinateFromJSON:result];
                NSDictionary *addressDictionary = [self addressDictionaryFromJSON:result];
                if (index == 0) {
                    [_mapView setCenterCoordinate:coord animated:NO];
                }
                MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coord addressDictionary:addressDictionary];
                [_mapView addAnnotation:placemark];
                index++;
            }
        }
    } failure:nil];
    [operation start];
    
    [self finishSearch];
}

- (IBAction)dimmingViewTapped:(id)sender {
    [self finishSearch];
}

- (void)finishSearch
{
    [UIView animateWithDuration:0.25 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^
     {
         self.dimView.alpha = 0.0f;
     } completion:nil];
    
    [self.searchBar resignFirstResponder];
}

- (CLLocationDistance)getDistanceFrom:(CLLocationCoordinate2D)start to:(CLLocationCoordinate2D)end
{
	CLLocation *startLoccation = [[CLLocation alloc] initWithLatitude:start.latitude longitude:start.longitude];
	CLLocation *endLoccation = [[CLLocation alloc] initWithLatitude:end.latitude longitude:end.longitude];
    
	return [startLoccation distanceFromLocation:endLoccation];
}

- (CLLocationCoordinate2D)coordinateFromJSON:(id)JSON
{
    NSDictionary *location = [[JSON valueForKey:@"geometry"] valueForKey:@"location"];
    NSNumber *lat = [location valueForKey:@"lat"];
    NSNumber *lng = [location valueForKey:@"lng"];
    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake([lat doubleValue], [lng doubleValue]);
    return coord;
}

- (NSDictionary *)addressDictionaryFromJSON:(id)JSON
{
    NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] init];
    addressDictionary[@"FormattedAddressLines"] = [((NSString *)[JSON valueForKey:@"formatted_address"]) componentsSeparatedByString:@", "];
    for (id component in [JSON valueForKey:@"address_components"]) {
        NSArray *types = [component valueForKey:@"types"];
        id longName = [component valueForKey:@"long_name"];
        id shortName = [component valueForKey:@"short_name"];
        for (NSString *type in types) {
            if ([type isEqualToString:@"postal_code"]) {
                addressDictionary[@"ZIP"] = longName;
            }
            else if ([type isEqualToString:@"country"]) {
                addressDictionary[@"Country"] = longName;
                addressDictionary[@"CountryCode"] = shortName;
            }
            else if ([type isEqualToString:@"administrative_area_level_1"]) {
                addressDictionary[@"State"] = longName;
            }
            else if ([type isEqualToString:@"administrative_area_level_2"]) {
                addressDictionary[@"SubAdministrativeArea"] = longName;
            }
            else if ([type isEqualToString:@"locality"]) {
                addressDictionary[@"City"] = longName;
            }
            else if ([type isEqualToString:@"sublocality"]) {
                addressDictionary[@"SubLocality"] = longName;
            }
            else if ([type isEqualToString:@"establishment"]) {
                addressDictionary[@"Name"] = longName;
            }
            else if ([type isEqualToString:@"route"]) {
                addressDictionary[@"Thoroughfare"] = longName;
            }
            else if ([type isEqualToString:@"street_number"]) {
                addressDictionary[@"SubThoroughfare"] = longName;
            }
        }
    }
    return addressDictionary;
}

#pragma mark -

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation; {
	if (annotation == mapView.userLocation) {
		return nil;
	}
    
    if (annotation == droppedPin) {
        MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"];
        annotationView.pinColor = MKPinAnnotationColorPurple;
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
            annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        
        annotationView.annotation = annotation;
        [mapView selectAnnotation:annotation animated:YES];
        
        return annotationView;
    }
    
	MKPinAnnotationView *annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"];
    annotationView.pinColor = MKPinAnnotationColorRed;
    annotationView.canShowCallout = YES;
    annotationView.animatesDrop = YES;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    }
    
	annotationView.annotation = annotation;
    [mapView selectAnnotation:annotation animated:YES];
    
	return annotationView;
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    WMOverlayView *view = [[WMOverlayView alloc] initWithOverlay:overlay];
    return view;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    [self performSegueWithIdentifier:@"Details" sender:view];
}

#pragma mark -

- (void)configurationViewController:(WMConfigurationViewController *)controller mapSourceChanged:(WMMapSource)mapSource
{
    self.mapSource = mapSource;
}

- (void)configurationViewController:(WMConfigurationViewController *)controller mapTypeChanged:(MKMapType)mapType
{
    self.mapType = mapType;
}

- (void)configurationViewControllerWillAddPin:(WMConfigurationViewController *)controller
{
    CLLocationCoordinate2D centerCoordinate = _mapView.centerCoordinate;
    
    [_mapView removeAnnotation:droppedPin];
    
    droppedPin = [[WMPlacemark alloc] initWithCoordinate:centerCoordinate addressDictionary:nil];
    droppedPin.coordinate = centerCoordinate;
    droppedPin.title = NSLocalizedString(@"Dropped Pin", nil);
    [_mapView addAnnotation:droppedPin];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?latlng=%f%%2C%f&sensor=true", centerCoordinate.latitude, centerCoordinate.longitude]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSString *status = [JSON valueForKeyPath:@"status"];
        if ([status isEqualToString:@"OK"]) {
            NSArray *results = [JSON valueForKeyPath:@"results"];
            if (results.count > 0) {
                NSDictionary *addressDictionary = [self addressDictionaryFromJSON:results[0]];
                NSArray *addressLines = [addressDictionary objectForKey:@"FormattedAddressLines"];
                if (addressLines) {
                    droppedPin.subtitle = [addressLines componentsJoinedByString:@", "];
                }
                else {
                    droppedPin.subtitle = ABCreateStringWithAddressDictionary(addressDictionary, NO);
                }
                droppedPin.addressDictionary = addressDictionary;
            }
        }
    } failure:nil];
    [operation start];
}

- (void)configurationViewControllerWillPrintMap:(WMConfigurationViewController *)configurationViewController
{
    UIPrintInteractionController *controller = [UIPrintInteractionController sharedPrintController];
    if(!controller){
        return;
    }
    
    UIPrintInteractionCompletionHandler completionHandler = ^(UIPrintInteractionController *printController, BOOL completed, NSError *error) {
        if(completed && error) {
            return;
        }
    };
    
    UIPrintInfo *printInfo = [UIPrintInfo printInfo];
    printInfo.outputType = UIPrintInfoOutputPhoto;
    
    controller.printInfo = printInfo;
    controller.printFormatter = [_mapView viewPrintFormatter];
    
    [controller presentAnimated:YES completionHandler:completionHandler];
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Configure"]) {
        WMConfigurationViewController *controller = segue.destinationViewController;
        controller.delegate = self;
        controller.mapSource = _mapSource;
        controller.mapType = _mapType;
    } else if ([segue.identifier isEqualToString:@"Details"]) {
        WMDetailViewController *controller = segue.destinationViewController;
        controller.mapView = _mapView;
        controller.placemark = [sender annotation];
    }
}

#pragma mark -

- (void)saveSessionState {
    MKCoordinateRegion region = _mapView.region;
    CLLocationCoordinate2D center = region.center;
    MKCoordinateSpan span = region.span;
    
    NSMutableDictionary *lastSession = [NSMutableDictionary dictionary];
    [lastSession setObject:[NSNumber numberWithDouble:center.latitude] forKey:@"center.latitude"];
    [lastSession setObject:[NSNumber numberWithDouble:center.longitude] forKey:@"center.longitude"];
    [lastSession setObject:[NSNumber numberWithDouble:span.latitudeDelta] forKey:@"span.latitudeDelta"];
    [lastSession setObject:[NSNumber numberWithDouble:span.longitudeDelta] forKey:@"span.longitudeDelta"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:lastSession forKey:@"LastSession"];
}

- (void)restoreSessionState {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *lastSession = [defaults objectForKey:@"LastSession"];
    
    if (lastSession) {
        NSNumber *latitude = [lastSession objectForKey:@"center.latitude"];
        NSNumber *longitude = [lastSession objectForKey:@"center.longitude"];
        NSNumber *latitudeDelta = [lastSession objectForKey:@"span.latitudeDelta"];
        NSNumber *longitudeDelta = [lastSession objectForKey:@"span.longitudeDelta"];
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
        MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta.doubleValue, longitudeDelta.doubleValue);
        
        MKCoordinateRegion region = MKCoordinateRegionMake(center, span);
        _mapView.region = region;
    }
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    [self saveSessionState];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification
{
    [self restoreSessionState];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    [self saveSessionState];
}

@end
