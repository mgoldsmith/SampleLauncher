//
//  ViewController.m
//  SampleLauncher
//
//  Created by Matthew Goldsmith on 12/16/25.
//

#import "ViewController.h"
#import "SampleBankView.h"

@interface ViewController ()

@property (nonatomic, strong) SampleBankView *bankView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create and add sample bank view
    self.bankView = [[SampleBankView alloc] initWithFrame:NSZeroRect capacity:16];
    self.bankView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bankView];

    // Layout constraints - center in view with padding
    [NSLayoutConstraint activateConstraints:@[
        [self.bankView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.bankView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.bankView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.bankView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.bankView.topAnchor constraintGreaterThanOrEqualToAnchor:self.view.topAnchor constant:20],
        [self.bankView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-20],
    ]];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end
