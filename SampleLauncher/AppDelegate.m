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
#import "MIDIInput.h"

@interface AppDelegate ()

@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong, readwrite) SampleBank *sampleBank;
@property (nonatomic, strong, readwrite) MIDIInput *midiInput;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Initialize audio engine and its main mixer node
    self.audioEngine = [[AVAudioEngine alloc] init];
    [self.audioEngine mainMixerNode];

    // Initialize MIDI input
    self.midiInput = [[MIDIInput alloc] init];

    // Post notification that MIDI input is ready
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MIDIInputReady" object:self.midiInput];

    // Initialize sample bank with stock samples
    self.sampleBank = [[SampleBank alloc] init];

    NSError *error = nil;
    if (![self loadStockSamples:&error]) {
        NSLog(@"Failed to load stock samples: %@", error);
        return;
    }

     // Attach all sample slots to the audio engine
    [self.sampleBank attachToAudioEngine:self.audioEngine];

    // Start the audio engine
    if (![self.audioEngine startAndReturnError:&error]) {
        NSLog(@"Failed to start audio engine: %@", error);
    }
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Stop the audio engine
    [self.audioEngine stop];
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

- (BOOL)loadStockSamples:(NSError **)error {
    NSString *samplesPath = [[NSBundle mainBundle] pathForResource:@"StockSamples" ofType:nil];

    if (!samplesPath) {
        if (error) {
            *error = [NSError errorWithDomain:@"SampleLauncherErrorDomain"
                                         code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"StockSamples folder not found in bundle"}];
        }
        return NO;
    }

    NSError *fileError = nil;
    NSArray<NSString *> *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:samplesPath error:&fileError];

    if (fileError) {
        if (error) {
            *error = fileError;
        }
        return NO;
    }

    // Filter for .aif files and sort alphabetically
    NSArray<NSString *> *sampleFiles = [[files filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self ENDSWITH '.aif'"]]
                                        sortedArrayUsingSelector:@selector(compare:)];

    // Load up to capacity samples
    NSUInteger samplesToLoad = MIN(sampleFiles.count, self.sampleBank.capacity);

    for (NSUInteger i = 0; i < samplesToLoad; i++) {
        NSString *samplePath = [samplesPath stringByAppendingPathComponent:sampleFiles[i]];

        NSError *loadError = nil;
        if (![self.sampleBank loadSampleAtIndex:i fromFile:samplePath error:&loadError]) {
            if (error) {
                *error = loadError;
            }
            return NO;
        }
    }

    // Make sure we loaded at least one sample
    if (self.sampleBank.count == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"SampleLauncherErrorDomain"
                                         code:2
                                     userInfo:@{NSLocalizedDescriptionKey: @"No samples were loaded from StockSamples folder"}];
        }
        return NO;
    }

    NSLog(@"Loaded %lu samples into bank", (unsigned long)self.sampleBank.count);

    // Post notification that samples are loaded
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SamplesDidLoad" object:self.sampleBank];

    return YES;
}

@end
