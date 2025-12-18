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

// Select a MIDI source by index (returns YES if index is valid)
- (BOOL)selectSourceAtIndex:(NSUInteger)index;

// Currently selected source name (nil if none selected)
@property (nonatomic, copy, readonly, nullable) NSString *selectedSourceName;

@end

NS_ASSUME_NONNULL_END
