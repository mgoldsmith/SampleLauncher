//
//  MIDIInput.m
//  SampleLauncher
//

#import "MIDIInput.h"
#import <CoreMIDI/CoreMIDI.h>

@interface MIDIInput ()
@property (nonatomic, assign) MIDIEndpointRef selectedSource;
@end

@implementation MIDIInput

- (instancetype)init {
    self = [super init];
    if (self) {
        // Future: MIDI client setup will go here
        _selectedSource = 0;
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
