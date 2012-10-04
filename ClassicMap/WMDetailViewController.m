//
//  WMDetailViewController.m
//  WorldMap
//
//  Created by kishikawa katsumi on 2012/09/27.
//  Copyright (c) 2012 kishikawa katsumi. All rights reserved.
//

#import "WMDetailViewController.h"

@interface WMDetailViewController () <ADBannerViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *removePinLabel;
@property (weak, nonatomic) IBOutlet ADBannerView *bannerView;

@end

@implementation WMDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Info", nil);
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    _headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    _titleLabel.text = [NSString stringWithFormat:@"<%g/%g>", _placemark.coordinate.latitude, _placemark.coordinate.longitude];
    _addressTitleLabel.text = NSLocalizedString(@"Address", nil);
    NSArray *addressLines = [_placemark.addressDictionary objectForKey:@"FormattedAddressLines"];
    if (addressLines) {
        _addressLabel.text = [addressLines componentsJoinedByString:@", "];
    }
    else {
        _addressLabel.text = ABCreateStringWithAddressDictionary(_placemark.addressDictionary, YES);
    }
    
    _removePinLabel.text = NSLocalizedString(@"Remove Pin", nil);
    
    _bannerView.hidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [self setHeaderView:nil];
    [self setTitleLabel:nil];
    [self setAddressLabel:nil];
    [self setAddressTitleLabel:nil];
    [self setRemovePinLabel:nil];
    [self setBannerView:nil];
    [super viewDidUnload];
}

#pragma mark -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        [_mapView removeAnnotation:_placemark];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark -

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    banner.hidden = NO;
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    banner.hidden = YES;
}

@end
