//
//  MIDIController.m
//  SampleLauncher
//

#import "MIDIController.h"
#import "SampleBank.h"
#import "SampleSlot.h"

@interface MIDIController ()
@property (nonatomic, weak) MIDIInput *midiInput;
@property (nonatomic, weak) SampleBank *sampleBank;
@end

@implementation MIDIController

- (instancetype)initWithMIDIInput:(MIDIInput *)midiInput sampleBank:(SampleBank *)sampleBank {
    self = [super init];
    if (self) {
        _midiInput = midiInput;
        _sampleBank = sampleBank;

        // Set self as delegate to receive MIDI events
        midiInput.inputDelegate = self;
    }
    return self;
}

#pragma mark - MIDIInputDelegate

- (void)midiInput:(MIDIInput *)input didReceiveNoteOn:(UInt8)noteNumber {
    // Map MIDI note to sample slot
    // C2 (note 48) → slot 0, D#3 (note 63) → slot 15
    if (noteNumber < 48 || noteNumber > 63) {
        return;  // Out of range
    }

    NSUInteger slotIndex = noteNumber - 48;
    SampleSlot *slot = [self.sampleBank slotAtIndex:slotIndex];

    if (slot) {
        [slot toggleQuantized];

        // Notify UI on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"SampleSlotDidChange"
                                                                object:slot
                                                              userInfo:@{@"slotIndex": @(slotIndex)}];
        });
    }
}

@end
