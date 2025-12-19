//
//  ViewController.m
//  SampleLauncher
//
//  Created by Matthew Goldsmith on 12/16/25.
//

#import "ViewController.h"
#import "SampleBankView.h"
#import "AppDelegate.h"
#import "MIDIInput.h"

@interface ViewController () <NSMenuDelegate>

@property (nonatomic, strong) SampleBankView *bankView;
@property (nonatomic, strong) NSPopUpButton *midiSourcePopup;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Create MIDI source popup button
    self.midiSourcePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
    self.midiSourcePopup.translatesAutoresizingMaskIntoConstraints = NO;
    [self.midiSourcePopup setTarget:self];
    [self.midiSourcePopup setAction:@selector(midiSourceSelected:)];

    [self.view addSubview:self.midiSourcePopup];

    // Listen for MIDI input ready notification to populate sources
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(midiInputReady:)
                                                 name:@"MIDIInputReady"
                                               object:nil];

    // Listen for MIDI device changes to refresh sources
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(midiDevicesChanged:)
                                                 name:@"MIDIDevicesChanged"
                                               object:nil];

    // Create and add sample bank view
    self.bankView = [[SampleBankView alloc] initWithFrame:NSZeroRect capacity:16];
    self.bankView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bankView];

    // Layout constraints - popup at top, bank view below it
    [NSLayoutConstraint activateConstraints:@[
        // MIDI popup constraints
        [self.midiSourcePopup.topAnchor constraintEqualToAnchor:self.view.topAnchor constant:20],
        [self.midiSourcePopup.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.midiSourcePopup.widthAnchor constraintGreaterThanOrEqualToConstant:200],

        // Bank view constraints
        [self.bankView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.bankView.topAnchor constraintEqualToAnchor:self.midiSourcePopup.bottomAnchor constant:20],
        [self.bankView.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.view.leadingAnchor constant:20],
        [self.bankView.trailingAnchor constraintLessThanOrEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.bankView.bottomAnchor constraintLessThanOrEqualToAnchor:self.view.bottomAnchor constant:-20],
    ]];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - MIDI Source Management

- (void)midiInputReady:(NSNotification *)notification {
    [self refreshMIDISources];

    // Auto-select the first MIDI source on startup
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    if (self.midiSourcePopup.numberOfItems > 0 && self.midiSourcePopup.isEnabled) {
        [self.midiSourcePopup selectItemAtIndex:0];
        [appDelegate.midiInput selectSourceAtIndex:0];
    }
}

- (void)midiDevicesChanged:(NSNotification *)notification {
    [self refreshMIDISources];
}

- (void)refreshMIDISources {
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    NSArray<NSString *> *sources = [appDelegate.midiInput listSources];

    // Clear existing items
    [self.midiSourcePopup removeAllItems];

    if (sources.count == 0) {
        // No MIDI sources available
        [self.midiSourcePopup addItemWithTitle:@"No MIDI Devices"];
        [self.midiSourcePopup setEnabled:NO];
    } else {
        // Add all sources to the popup
        for (NSString *sourceName in sources) {
            [self.midiSourcePopup addItemWithTitle:sourceName];
        }
        [self.midiSourcePopup setEnabled:YES];
    }
}

- (void)midiSourceSelected:(id)sender {
    AppDelegate *appDelegate = (AppDelegate *)[NSApp delegate];
    NSInteger selectedIndex = [self.midiSourcePopup indexOfSelectedItem];

    if (selectedIndex >= 0) {
        [appDelegate.midiInput selectSourceAtIndex:selectedIndex];
        NSLog(@"Selected MIDI source: %@", appDelegate.midiInput.selectedSourceName);
    }
}

@end
