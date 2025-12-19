//
//  MIDISourceSelector.m
//  SampleLauncher
//
//  Manages MIDI source selection UI
//

#import "MIDISourceSelector.h"
#import "MIDIInput.h"

@interface MIDISourceSelector ()

@property (nonatomic, strong, readwrite) NSPopUpButton *popupButton;
@property (nonatomic, weak) MIDIInput *midiInput;

@end

@implementation MIDISourceSelector

- (instancetype)init {
    self = [super init];
    if (self) {
        // Create popup button
        _popupButton = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _popupButton.translatesAutoresizingMaskIntoConstraints = NO;
        [_popupButton setTarget:self];
        [_popupButton setAction:@selector(sourceSelected:)];

        // Listen for MIDI device changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(midiDevicesChanged:)
                                                     name:@"MIDIDevicesChanged"
                                                   object:nil];

        // Listen for MIDI input ready
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(midiInputReady:)
                                                     name:@"MIDIInputReady"
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Notification Handlers

- (void)midiInputReady:(NSNotification *)notification {
    // Get the MIDIInput from the notification
    self.midiInput = notification.object;

    [self refreshSources];

    // Auto-select the first MIDI source on startup
    if (self.popupButton.numberOfItems == 0 || !self.popupButton.isEnabled) {
        return;
    }

    [self.popupButton selectItemAtIndex:0];
    [self.midiInput selectSourceAtIndex:0];
}

- (void)midiDevicesChanged:(NSNotification *)notification {
    [self refreshSources];
}

#pragma mark - Source Management

- (void)refreshSources {
    NSArray<NSString *> *sources = [self.midiInput listSources];

    // Remember the currently selected source name
    NSString *previousSelection = [self.popupButton titleOfSelectedItem];

    // Clear existing items
    [self.popupButton removeAllItems];

    if (sources.count == 0) {
        // No MIDI sources available
        [self.popupButton addItemWithTitle:@"No MIDI Devices"];
        [self.popupButton setEnabled:NO];
        return;
    }

    // Add all sources to the popup
    for (NSString *sourceName in sources) {
        [self.popupButton addItemWithTitle:sourceName];
    }
    [self.popupButton setEnabled:YES];

    // Try to restore previous selection
    if (previousSelection && [sources containsObject:previousSelection]) {
        [self.popupButton selectItemWithTitle:previousSelection];
        NSUInteger index = [sources indexOfObject:previousSelection];
        [self.midiInput selectSourceAtIndex:index];
        return;
    }

    if (sources.count > 0) {
        // Previous selection no longer available, select first item
        [self.popupButton selectItemAtIndex:0];
        [self.midiInput selectSourceAtIndex:0];
    }
}

- (void)sourceSelected:(id)sender {
    NSInteger selectedIndex = [self.popupButton indexOfSelectedItem];

    if (selectedIndex < 0) {
        return;
    }

    [self.midiInput selectSourceAtIndex:selectedIndex];
    NSLog(@"Selected MIDI source: %@", self.midiInput.selectedSourceName);
}

@end
