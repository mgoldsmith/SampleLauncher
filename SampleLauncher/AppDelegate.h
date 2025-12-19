//
//  AppDelegate.h
//  SampleLauncher
//
//  Created by Matthew Goldsmith on 12/16/25.
//

#import <Cocoa/Cocoa.h>

@class SampleBank;
@class MIDIInput;
@class MIDIController;

NS_ASSUME_NONNULL_BEGIN

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong, readonly) SampleBank *sampleBank;
@property (nonatomic, strong, readonly) MIDIInput *midiInput;
@property (nonatomic, strong, readonly) MIDIController *midiController;

@end

NS_ASSUME_NONNULL_END

