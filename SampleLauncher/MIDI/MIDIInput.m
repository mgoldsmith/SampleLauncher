//
//  MIDIInput.m
//  SampleLauncher
//

#import "MIDIInput.h"
#import <CoreMIDI/CoreMIDI.h>
#import <CoreMIDI/MIDIMessages.h>

static void MIDINotificationCallback(const MIDINotification *message, void *refCon);

@interface MIDIInput ()
@property (nonatomic, assign) MIDIEndpointRef selectedSource;
@property (nonatomic, assign) MIDIClientRef midiClient;
@property (nonatomic, assign) MIDIPortRef inputPort;
@end

@implementation MIDIInput

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedSource = 0;
        _inputPort = 0;

        // Create MIDI client to receive notifications
        MIDIClientCreate(CFSTR("SampleLauncher MIDI Client"), MIDINotificationCallback, (__bridge void *)self, &_midiClient);

        // Create input port with block-based callback (MIDI 2.0 protocol, backwards compatible with MIDI 1.0)
        OSStatus status = MIDIInputPortCreateWithProtocol(
            _midiClient,
            CFSTR("SampleLauncher Input"),
            kMIDIProtocol_2_0,
            &_inputPort,
            ^(const MIDIEventList *eventList, void *srcConnRefCon) {
                [self handleMIDIEventList:eventList];
            }
        );

        if (status != noErr) {
            NSLog(@"Failed to create MIDI input port: %d", status);
        }
    }
    return self;
}

#pragma mark - MIDI Message Handling

// Visitor callback for MIDIEventListForEachEvent
static void MIDIEventVisitorCallback(void *context, MIDITimeStamp timeStamp, MIDIUniversalMessage message) {
    MIDIInput *self = (__bridge MIDIInput *)context;

    switch (message.type) {
        case kMIDIMessageTypeChannelVoice1: {
            // Return early if not a note on message
            if (message.channelVoice1.status != kMIDICVStatusNoteOn) {
                return;
            }

            UInt8 noteNumber = message.channelVoice1.note.number;
            UInt8 velocity = message.channelVoice1.note.velocity;

            // Ignore velocity-0 note-ons (they're really note-offs)
            if (velocity > 0) {
                [self.inputDelegate midiInput:self didReceiveNoteOn:noteNumber];
            }
            break;
        }

        case kMIDIMessageTypeChannelVoice2: {
            // Return early if not a note on message
            if (message.channelVoice2.status != kMIDICVStatusNoteOn) {
                return;
            }

            UInt8 noteNumber = message.channelVoice2.note.number;
            UInt16 velocity = message.channelVoice2.note.velocity;

            // Ignore velocity-0 note-ons
            if (velocity > 0) {
                [self.inputDelegate midiInput:self didReceiveNoteOn:noteNumber];
            }
            break;
        }

        default:
            // Ignore other message types
            return;
    }
}

- (void)handleMIDIEventList:(const MIDIEventList *)eventList {
    MIDIEventListForEachEvent(eventList, MIDIEventVisitorCallback, (__bridge void *)self);
}

- (void)dealloc {
    // Disconnect source
    if (_selectedSource != 0 && _inputPort != 0) {
        MIDIPortDisconnectSource(_inputPort, _selectedSource);
    }

    // Dispose port
    if (_inputPort != 0) {
        MIDIPortDispose(_inputPort);
    }

    // Dispose client
    if (_midiClient != 0) {
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

        // TODO: __bridge_transfer?
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

    // Disconnect previous source if any
    if (_selectedSource != 0 && _inputPort != 0) {
        MIDIPortDisconnectSource(_inputPort, _selectedSource);
    }

    // Select new source
    _selectedSource = MIDIGetSource((ItemCount)index);

    // Connect new source to input port
    if (_selectedSource != 0 && _inputPort != 0) {
        OSStatus status = MIDIPortConnectSource(_inputPort, _selectedSource, NULL);
        if (status != noErr) {
            NSLog(@"Failed to connect MIDI source: %d", status);
            return NO;
        }
    }

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
    //TODO: return early
    if (message->messageID == kMIDIMsgObjectAdded || message->messageID == kMIDIMsgObjectRemoved) {
        // Post notification on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MIDIDevicesChanged" object:nil];
        });
    }
}
