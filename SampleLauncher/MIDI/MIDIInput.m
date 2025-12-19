//
//  MIDIInput.m
//  SampleLauncher
//

#import "MIDIInput.h"
#import <CoreMIDI/CoreMIDI.h>

static void MIDINotificationCallback(const MIDINotification *message, void *refCon);

@interface MIDIInput ()
@property (nonatomic, assign) MIDIEndpointRef selectedSource;
@property (nonatomic, assign) MIDIClientRef midiClient;
@end

@implementation MIDIInput

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedSource = 0;

        // Create MIDI client to receive notifications
        MIDIClientCreate(CFSTR("SampleLauncher MIDI Client"), MIDINotificationCallback, (__bridge void *)self, &_midiClient);
    }
    return self;
}

- (void)dealloc {
    if (_midiClient) {
        MIDIClientDispose(_midiClient);
    }
}

- (NSArray<NSString *> *)listSources {
    NSMutableArray<NSString *> *sources = [NSMutableArray array];

    ItemCount sourceCount = MIDIGetNumberOfSources();
    for (ItemCount i = 0; i < sourceCount; i++) {
        MIDIEndpointRef source = MIDIGetSource(i);

        // Get the device name
        CFStringRef name = NULL;
        MIDIObjectGetStringProperty(source, kMIDIPropertyName, &name);

        if (name) {
            [sources addObject:(__bridge NSString *)name];
            CFRelease(name);
        } else {
            [sources addObject:[NSString stringWithFormat:@"MIDI Source %d", (int)i]];
        }
    }

    return [sources copy];
}

- (BOOL)selectSourceAtIndex:(NSUInteger)index {
    ItemCount sourceCount = MIDIGetNumberOfSources();

    if (index >= sourceCount) {
        return NO;
    }

    self.selectedSource = MIDIGetSource((ItemCount)index);
    return YES;
}

- (NSString *)selectedSourceName {
    if (self.selectedSource == 0) {
        return nil;
    }

    CFStringRef name = NULL;
    MIDIObjectGetStringProperty(self.selectedSource, kMIDIPropertyName, &name);

    if (name) {
        NSString *sourceName = (__bridge_transfer NSString *)name;
        return sourceName;
    }

    return nil;
}

@end

#pragma mark - MIDI Notification Callback

static void MIDINotificationCallback(const MIDINotification *message, void *refCon) {
    if (message->messageID == kMIDIMsgObjectAdded || message->messageID == kMIDIMsgObjectRemoved) {
        // Post notification on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MIDIDevicesChanged" object:nil];
        });
    }
}
