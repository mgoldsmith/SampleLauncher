//
//  TestAudioEngineHelper.m
//  SampleLauncherTests
//

#import "TestAudioEngineHelper.h"

@implementation TestAudioEngineHelper

+ (AVAudioEngine *)createTestEngineWithTestCase:(XCTestCase *)testCase {
    // Set up audio engine in manual rendering mode to avoid hardware access during tests
    AVAudioEngine *engine = [[AVAudioEngine alloc] init];

    // Enable manual rendering mode (offline processing, no hardware I/O)
    AVAudioFormat *renderFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000.0
                                                                                 channels:2];
    NSError *error = nil;
    BOOL success = [engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline
                                              format:renderFormat
                                   maximumFrameCount:4096
                                               error:&error];
    XCTAssertTrue(success, @"Failed to enable manual rendering mode: %@", error);

    error = nil;
    success = [engine startAndReturnError:&error];
    XCTAssertTrue(success, @"Failed to start engine: %@", error);

    return engine;
}

@end
