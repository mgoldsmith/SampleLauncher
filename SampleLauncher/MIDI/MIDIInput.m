//
//  MIDIInput.m
//  SampleLauncher
//

#import "MIDIInput.h"
#import <CoreMIDI/CoreMIDI.h>

@implementation MIDIInput

- (instancetype)init {
    self = [super init];
    if (self) {
        // Future: MIDI client setup will go here
    }
    return self;
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

@end
