//
//  AppDelegate.m
//  SampleLauncher
//
//  Created by Matthew Goldsmith on 12/16/25.
//

#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
#import "SampleBank.h"
#import "SampleSlot.h"

@interface AppDelegate ()

@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SampleBank *sampleBank;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Initialize audio engine and its main mixer node
    self.audioEngine = [[AVAudioEngine alloc] init];
    [self.audioEngine mainMixerNode];

    // Initialize sample bank with 16 slots
    self.sampleBank = [[SampleBank alloc] init];

     // Attach all sample slots to the audio engine
    [self.sampleBank attachToAudioEngine:self.audioEngine];

    // Start the audio engine
    NSError *error = nil;
    if (![self.audioEngine startAndReturnError:&error]) {
        NSLog(@"Failed to start audio engine: %@", error);
    }

//    [[self.sampleBank slotAtIndex:1] play];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Stop the audio engine
    [self.audioEngine stop];
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
