//
//  MIDIInput.h
//  SampleLauncher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MIDIInput;

@protocol MIDIInputDelegate <NSObject>
- (void)midiInput:(MIDIInput *)input didReceiveNoteOn:(UInt8)noteNumber;
@end

@interface MIDIInput : NSObject

- (instancetype)init;

// Returns array of NSStrings representing available MIDI source names
- (NSArray<NSString *> *)listSources;

// Select a MIDI source by index (returns YES if index is valid)
- (BOOL)selectSourceAtIndex:(NSUInteger)index;

// Currently selected source name (nil if none selected)
@property (nonatomic, copy, readonly, nullable) NSString *selectedSourceName;

// Delegate to receive MIDI events
@property (nonatomic, weak, nullable) id<MIDIInputDelegate> inputDelegate;

@end

NS_ASSUME_NONNULL_END
