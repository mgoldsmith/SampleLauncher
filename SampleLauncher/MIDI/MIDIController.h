//
//  MIDIController.h
//  SampleLauncher
//

#import <Foundation/Foundation.h>
#import "MIDIInput.h"

@class SampleBank;

NS_ASSUME_NONNULL_BEGIN

@interface MIDIController : NSObject <MIDIInputDelegate>

- (instancetype)initWithMIDIInput:(MIDIInput *)midiInput sampleBank:(SampleBank *)sampleBank;

@end

NS_ASSUME_NONNULL_END
