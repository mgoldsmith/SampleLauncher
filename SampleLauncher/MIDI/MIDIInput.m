//
//  MIDIInput.m
//  SampleLauncher
//

#import "MIDIInput.h"
#import <CoreMIDI/CoreMIDI.h>
#import <CoreMIDI/MIDIMessages.h>
#import <stdatomic.h>

// Lock-free ring buffer for passing MIDI events from realtime thread
#define MIDI_RING_BUFFER_SIZE 256

typedef struct {
    UInt8 noteNumber;
    UInt8 velocity;
} MIDINoteEvent;

typedef struct {
    MIDINoteEvent events[MIDI_RING_BUFFER_SIZE];
    _Atomic int writeIndex;
    _Atomic int readIndex;
} MIDIRingBuffer;

static void MIDINotificationCallback(const MIDINotification *message, void *refCon);

@interface MIDIInput ()
@property (nonatomic, assign) MIDIEndpointRef selectedSource;
@property (nonatomic, assign) MIDIClientRef midiClient;
@property (nonatomic, assign) MIDIPortRef inputPort;
@property (nonatomic, assign) MIDIRingBuffer *ringBuffer;
@property (nonatomic, strong) dispatch_queue_t processingQueue;
@property (nonatomic, strong) dispatch_source_t processingTimer;
@end

// Write event to ring buffer (called from realtime thread)
static inline bool MIDIRingBufferWrite(MIDIRingBuffer *buffer, UInt8 noteNumber, UInt8 velocity) {
    int write = atomic_load_explicit(&buffer->writeIndex, memory_order_relaxed);
    int next = (write + 1) % MIDI_RING_BUFFER_SIZE;
    int read = atomic_load_explicit(&buffer->readIndex, memory_order_acquire);

    // Check if buffer is full
    if (next == read) {
        return false;  // Buffer full, drop event
    }

    // Write event data
    buffer->events[write].noteNumber = noteNumber;
    buffer->events[write].velocity = velocity;

    // Advance write pointer
    atomic_store_explicit(&buffer->writeIndex, next, memory_order_release);
    return true;
}

// Read event from ring buffer (called from worker thread)
static inline bool MIDIRingBufferRead(MIDIRingBuffer *buffer, MIDINoteEvent *event) {
    int read = atomic_load_explicit(&buffer->readIndex, memory_order_relaxed);
    int write = atomic_load_explicit(&buffer->writeIndex, memory_order_acquire);

    // Check if buffer is empty
    if (read == write) {
        return false;  // No events available
    }

    // Read event data
    *event = buffer->events[read];

    // Advance read pointer
    int next = (read + 1) % MIDI_RING_BUFFER_SIZE;
    atomic_store_explicit(&buffer->readIndex, next, memory_order_release);
    return true;
}

@implementation MIDIInput

- (instancetype)init {
    self = [super init];
    if (self) {
        _selectedSource = 0;
        _inputPort = 0;

        // Allocate ring buffer
        _ringBuffer = (MIDIRingBuffer *)calloc(1, sizeof(MIDIRingBuffer));
        atomic_init(&_ringBuffer->writeIndex, 0);
        atomic_init(&_ringBuffer->readIndex, 0);

        // Create processing queue
        dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(
            DISPATCH_QUEUE_SERIAL,
            QOS_CLASS_USER_INTERACTIVE,
            0
        );
        _processingQueue = dispatch_queue_create("com.samplelauncher.midi.processing", attr);

        // Create timer to poll ring buffer (runs at ~1ms intervals)
        _processingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _processingQueue);
        dispatch_source_set_timer(_processingTimer,
                                  dispatch_time(DISPATCH_TIME_NOW, 0),
                                  1 * NSEC_PER_MSEC,  // 1ms interval
                                  100 * NSEC_PER_USEC);  // 100us leeway

        __weak MIDIInput *weakSelf = self;
        dispatch_source_set_event_handler(_processingTimer, ^{
            [weakSelf processPendingMIDIEvents];
        });

        dispatch_resume(_processingTimer);

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
            if (message.channelVoice1.status != kMIDICVStatusNoteOn) {
                return;
            }

            UInt8 noteNumber = message.channelVoice1.note.number;
            UInt8 velocity = message.channelVoice1.note.velocity;

            // Velocity 0 note-ons are treated as note-offs in MIDI
            if (velocity == 0) {
                return;
            }

            // Write to ring buffer (realtime-safe)
            MIDIRingBufferWrite(self->_ringBuffer, noteNumber, velocity);
            break;
        }

        case kMIDIMessageTypeChannelVoice2: {
            if (message.channelVoice2.status != kMIDICVStatusNoteOn) {
                return;
            }

            UInt8 noteNumber = message.channelVoice2.note.number;
            UInt16 velocity = message.channelVoice2.note.velocity;

            // Velocity 0 note-ons are treated as note-offs in MIDI
            if (velocity == 0) {
                return;
            }

            // Convert MIDI 2.0 16-bit velocity to 8-bit (use most significant byte)
            UInt8 velocity8 = (UInt8)(velocity >> 8);

            // Write to ring buffer (realtime-safe)
            MIDIRingBufferWrite(self->_ringBuffer, noteNumber, velocity8);
            break;
        }

        default:
            return;
    }
}

- (void)handleMIDIEventList:(const MIDIEventList *)eventList {
    MIDIEventListForEachEvent(eventList, MIDIEventVisitorCallback, (__bridge void *)self);
}

- (void)processPendingMIDIEvents {
    MIDINoteEvent event;

    // Process all available events
    while (MIDIRingBufferRead(self.ringBuffer, &event)) {
        [self.inputDelegate midiInput:self didReceiveNoteOn:event.noteNumber];
    }
}

- (void)dealloc {
    // Stop and release timer
    if (_processingTimer) {
        dispatch_source_cancel(_processingTimer);
        _processingTimer = nil;
    }

    // Process any remaining events
    if (_processingQueue && _ringBuffer) {
        dispatch_sync(_processingQueue, ^{
            [self processPendingMIDIEvents];
        });
    }

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

    // Free ring buffer
    if (_ringBuffer) {
        free(_ringBuffer);
        _ringBuffer = NULL;
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
