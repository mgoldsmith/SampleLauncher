//
//  SampleSlotTests.m
//  SampleLauncherTests
//

#import <XCTest/XCTest.h>
#import "SampleSlot.h"
#import "TransportClock.h"
#import "TestAudioEngineHelper.h"

// Test sample configuration - change this to use a different sample
static NSString * const kTestSampleName = @"01 Kick";

@interface SampleSlotTests : XCTestCase
@property (nonatomic, strong) SampleSlot *slot;
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) TransportClock *transportClock;
@property (nonatomic, copy) NSString *testSamplePath;
@end

@implementation SampleSlotTests

- (void)setUp {
    self.slot = [[SampleSlot alloc] init];

    // Set up audio engine in manual rendering mode
    self.engine = [TestAudioEngineHelper createTestEngineWithTestCase:self];

    [self.engine attachNode:self.slot.playerNode];
    [self.engine connect:self.slot.playerNode
                      to:self.engine.mainMixerNode
                  format:nil];

    // Get path to test sample from test bundle
    NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
    self.testSamplePath = [testBundle pathForResource:kTestSampleName
                                                ofType:@"aif"
                                                inDirectory:@"StockSamples"];

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

#pragma mark - Quantized Playback Tests

- (void)testPlayAtNextBarBoundaryWithoutTransportClock {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    // Should not crash, but should not play either
    XCTAssertNoThrow([self.slot playAtNextBarBoundary],
                     @"Should not crash without transport clock");
    XCTAssertFalse(self.slot.isPlaying,
                   @"Should not be playing without transport clock");
}

- (void)testPlayAtNextBarBoundaryWithoutSample {
    // Set up transport clock
    self.transportClock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                                  bpm:128.0
                                                          beatsPerBar:4];
    self.slot.transportClock = self.transportClock;
    [self.transportClock start];

    // Should not crash, but should not play either
    XCTAssertNoThrow([self.slot playAtNextBarBoundary],
                     @"Should not crash without sample");
    XCTAssertFalse(self.slot.isPlaying,
                   @"Should not be playing without sample");
}

- (void)testPlayAtNextBarBoundaryWithTransportClock {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    // Set up transport clock
    self.transportClock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                                  bpm:128.0
                                                          beatsPerBar:4];
    self.slot.transportClock = self.transportClock;
    [self.transportClock start];

    [self.slot playAtNextBarBoundary];

    // Player node should be playing (schedules for future but starts immediately)
    XCTAssertTrue(self.slot.isPlaying,
                  @"Should be playing after playAtNextBarBoundary");
}

- (void)testToggleQuantizedWhenStopped {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    // Set up transport clock
    self.transportClock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                                  bpm:128.0
                                                          beatsPerBar:4];
    self.slot.transportClock = self.transportClock;
    [self.transportClock start];

    XCTAssertFalse(self.slot.isPlaying, @"Should start stopped");

    [self.slot toggleQuantized];

    XCTAssertTrue(self.slot.isPlaying,
                  @"toggleQuantized should start playback when stopped");
}

- (void)testToggleQuantizedWhenPlaying {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    // Set up transport clock
    self.transportClock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                                  bpm:128.0
                                                          beatsPerBar:4];
    self.slot.transportClock = self.transportClock;
    [self.transportClock start];

    [self.slot playAtNextBarBoundary];
    XCTAssertTrue(self.slot.isPlaying, @"Should be playing");

    [self.slot toggleQuantized];
    XCTAssertFalse(self.slot.isPlaying,
                   @"toggleQuantized should stop playback when playing");
}

- (void)testToggleQuantizedMultipleTimes {
    [self.slot loadSampleFromFile:self.testSamplePath error:nil];

    // Set up transport clock
    self.transportClock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                                  bpm:128.0
                                                          beatsPerBar:4];
    self.slot.transportClock = self.transportClock;
    [self.transportClock start];

    // Toggle on
    [self.slot toggleQuantized];
    XCTAssertTrue(self.slot.isPlaying, @"First toggle should start");

    // Toggle off
    [self.slot toggleQuantized];
    XCTAssertFalse(self.slot.isPlaying, @"Second toggle should stop");

    // Toggle on again
    [self.slot toggleQuantized];
    XCTAssertTrue(self.slot.isPlaying, @"Third toggle should start again");
}

- (void)testTransportClockProperty {
    XCTAssertNil(self.slot.transportClock, @"Transport clock should be nil initially");

    self.transportClock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                                  bpm:128.0
                                                          beatsPerBar:4];
    self.slot.transportClock = self.transportClock;

    XCTAssertEqual(self.slot.transportClock, self.transportClock,
                   @"Transport clock should be set correctly");
}

@end
