//
//  SampleSlotTests.m
//  SampleLauncherTests
//

#import <XCTest/XCTest.h>
#import "SampleSlot.h"

// Test sample configuration - change this to use a different sample
static NSString * const kTestSampleName = @"Rotations 3 Kick";

@interface SampleSlotTests : XCTestCase
@property (nonatomic, strong) SampleSlot *slot;
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, copy) NSString *testSamplePath;
@end

@implementation SampleSlotTests

- (void)setUp {
    self.slot = [[SampleSlot alloc] init];

    // Set up audio engine in manual rendering mode to avoid hardware access during tests
    self.engine = [[AVAudioEngine alloc] init];

    // Enable manual rendering mode (offline processing, no hardware I/O)
    AVAudioFormat *renderFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000.0
                                                                                 channels:2];
    [self.engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline
                                    format:renderFormat
                         maximumFrameCount:4096
                                     error:nil];

    [self.engine attachNode:self.slot.playerNode];
    [self.engine connect:self.slot.playerNode
                      to:self.engine.mainMixerNode
                  format:nil];

    NSError *error = nil;
    [self.engine startAndReturnError:&error];
    XCTAssertNil(error, @"Engine should start without error");

    // Get path to test sample from test bundle
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    self.testSamplePath = [testBundle pathForResource:kTestSampleName
                                                ofType:@"aif"];

    if (!self.testSamplePath) {
        NSLog(@"WARNING: Test sample not found in bundle. Available resources: %@",
              [testBundle pathsForResourcesOfType:@"aif" inDirectory:nil]);
    }
}

- (void)tearDown {
    [self.slot stop];
    [self.engine stop];
    [self.engine detachNode:self.slot.playerNode];
    self.engine = nil;
    self.slot = nil;
}

- (void)testInitialization {
    XCTAssertNotNil(self.slot, @"SampleSlot should initialize");
    XCTAssertNotNil(self.slot.playerNode, @"Player node should be created on init");
    XCTAssertNil(self.slot.sampleName, @"Sample name should be nil before loading");
    XCTAssertFalse(self.slot.isPlaying, @"Should not be playing initially");
}

- (void)testLoadSampleSuccess {
    NSError *error = nil;
    BOOL success = [self.slot loadSampleFromFile:self.testSamplePath error:&error];

    XCTAssertTrue(success, @"Loading should succeed");
    XCTAssertNil(error, @"No error should occur");
    XCTAssertNotNil(self.slot.sampleName, @"Sample name should be set");
    XCTAssertEqualObjects(self.slot.sampleName, kTestSampleName,
                         @"Sample name should match filename without extension");
}

- (void)testLoadSampleWithInvalidPath {
    NSError *error = nil;
    BOOL success = [self.slot loadSampleFromFile:@"/invalid/path/to/file.aif" error:&error];

    XCTAssertFalse(success, @"Loading should fail with invalid path");
    XCTAssertNotNil(error, @"Error should be set");
}

- (void)testPlayWithoutLoadedSample {
    XCTAssertNoThrow([self.slot play], @"Playing without a sample should not crash");
    XCTAssertFalse(self.slot.isPlaying, @"Should not be playing without a sample");
}

- (void)testPlayAndStop {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    [self.slot play];
    XCTAssertTrue(self.slot.isPlaying, @"Should be playing after play is called");

    [self.slot stop];
    XCTAssertFalse(self.slot.isPlaying, @"Should not be playing after stop is called");
}

- (void)testToggleFromStopped {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    XCTAssertFalse(self.slot.isPlaying, @"Should start stopped");

    [self.slot toggle];
    XCTAssertTrue(self.slot.isPlaying, @"Toggle should start playback");
}

- (void)testToggleFromPlaying {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    [self.slot play];
    XCTAssertTrue(self.slot.isPlaying, @"Should be playing");

    [self.slot toggle];
    XCTAssertFalse(self.slot.isPlaying, @"Toggle should stop playback");
}

- (void)testRetriggerWhilePlaying {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    [self.slot play];
    XCTAssertTrue(self.slot.isPlaying, @"Should be playing");

    [self.slot play];
    XCTAssertTrue(self.slot.isPlaying, @"Should still be playing after re-trigger");
}

- (void)testPlayerNodeExists {
    XCTAssertNotNil(self.slot.playerNode, @"Player node should exist");
    XCTAssertTrue([self.slot.playerNode isKindOfClass:[AVAudioPlayerNode class]],
                 @"Player node should be an AVAudioPlayerNode");
}

@end
