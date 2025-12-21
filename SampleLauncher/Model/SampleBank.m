//
//  SampleBank.m
//  SampleLauncher
//

#import "SampleBank.h"
#import "SampleSlot.h"
#import "TransportClock.h"

@interface SampleBank ()
@property (nonatomic, strong) NSMutableArray<SampleSlot *> *slots;
@property (nonatomic, readwrite) NSUInteger capacity;
@end

@implementation SampleBank

- (instancetype)init {
    return [self initWithCapacity:16];
}

- (instancetype)initWithCapacity:(NSUInteger)capacity {
    self = [super init];
    if (self) {
        _capacity = capacity;
        _slots = [NSMutableArray arrayWithCapacity:capacity];

        for (NSUInteger i = 0; i < capacity; i++) {
            [_slots addObject:[[SampleSlot alloc] init]];
        }
    }
    return self;
}

- (nullable SampleSlot *)slotAtIndex:(NSUInteger)index {
    if (index >= self.capacity) {
        return nil;
    }
    return self.slots[index];
}

- (NSUInteger)count {
    NSUInteger loadedCount = 0;
    for (SampleSlot *slot in self.slots) {
        if (slot.sampleName != nil) {
            loadedCount++;
        }
    }
    return loadedCount;
}

- (void)setTransportClock:(TransportClock *)transportClock {
    _transportClock = transportClock;

    // Automatically distribute the clock to all slots
    for (SampleSlot *slot in self.slots) {
        slot.transportClock = transportClock;
    }
}

- (void)attachToAudioEngine:(AVAudioEngine *)engine {
    // Create static 48kHz format to match stock sample rate
    AVAudioFormat *outputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000.0 channels:2];

    for (NSUInteger i = 0; i < self.count; i++) {
        SampleSlot *slot = [self slotAtIndex:i];

        // Only attach slots that have loaded samples
        if (!slot) {
            continue;
        }

        [engine attachNode:slot.playerNode];

        // Connect with explicit 48kHz format to ensure mixer runs at 48kHz
        [engine connect:slot.playerNode
                     to:engine.mainMixerNode
                 format:outputFormat];

        NSLog(@"  Slot %lu connected with explicit %.0f Hz format", (unsigned long)i, outputFormat.sampleRate);
    }
}

- (BOOL)loadSampleAtIndex:(NSUInteger)index fromFile:(NSString *)filePath error:(NSError **)error {
    SampleSlot *slot = [self slotAtIndex:index];
    if (!slot) {
        if (error) {
            *error = [NSError errorWithDomain:@"SampleBankErrorDomain"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Invalid slot index"}];
        }
        return NO;
    }
    return [slot loadSampleFromFile:filePath error:error];
}

@end
