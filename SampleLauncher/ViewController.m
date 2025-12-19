//
//  ViewController.m
//  SampleLauncher
//
//  Created by Matthew Goldsmith on 12/16/25.
//

#import "ViewController.h"
#import "SampleBankView.h"
#import "AppDelegate.h"
#import "MIDISourceSelector.h"

@interface ViewController ()

@property (nonatomic, strong) SampleBankView *bankView;
@property (nonatomic, strong) MIDISourceSelector *midiSourceSelector;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create MIDI source selector
    self.midiSourceSelector = [[MIDISourceSelector alloc] init];
    [self.view addSubview:self.midiSourceSelector.popupButton];

    // Create and add sample bank view
    self.bankView = [[SampleBankView alloc] initWithFrame:NSZeroRect capacity:16];
    self.bankView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bankView];

    // Layout constraints - popup at top, bank view below it
    [NSLayoutConstraint activateConstraints:@[
        // MIDI popup constraints
        [self.midiSourceSelector.popupButton.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20],
        [self.midiSourceSelector.popupButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.midiSourceSelector.popupButton.widthAnchor constraintGreaterThanOrEqualToConstant:200],

        // Bank view constraints
        [self.bankView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.bankView.topAnchor constraintEqualToAnchor:self.midiSourceSelector.popupButton.bottomAnchor constant:20],
        [self.bankView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.bankView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.bankView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-20],
    ]];
}

@end
