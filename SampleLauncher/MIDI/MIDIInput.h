//
//  MIDIInput.h
//  SampleLauncher
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MIDIInput : NSObject

- (instancetype)init;

// Returns array of NSStrings representing available MIDI source names
- (NSArray<NSString *> *)listSources;

@end

NS_ASSUME_NONNULL_END
