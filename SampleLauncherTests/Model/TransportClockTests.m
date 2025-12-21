//
//  TransportClockTests.m
//  SampleLauncherTests
//

#import <XCTest/XCTest.h>
#import "TransportClock.h"
#import "TestAudioEngineHelper.h"

@interface TransportClockTests : XCTestCase
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) TransportClock *clock;
@end

@implementation TransportClockTests

- (void)setUp {
    self.engine = [TestAudioEngineHelper createTestEngineWithTestCase:self];
}

- (void)tearDown {
    [self.engine stop];
    self.engine = nil;
    self.clock = nil;
}

#pragma mark - Initialization Tests

- (void)testInitialization {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];

    XCTAssertNotNil(self.clock, @"TransportClock should initialize");
    XCTAssertEqual(self.clock.bpm, 120.0, @"BPM should be set");
    XCTAssertEqual(self.clock.beatsPerBar, 4, @"BeatsPerBar should be set");
}

- (void)testInitWithDifferentBPM {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:128.0
                                                 beatsPerBar:4];

    XCTAssertEqual(self.clock.bpm, 128.0, @"BPM should match initialized value");
}

- (void)testInitWithDifferentBeatsPerBar {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:3];

    XCTAssertEqual(self.clock.beatsPerBar, 3, @"BeatsPerBar should match initialized value");
}

#pragma mark - Sample Rate Tests

- (void)testSampleRateSetAfterStart {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];
    [self.clock start];

    XCTAssertEqual(self.clock.sampleRate, 48000.0, @"Sample rate should be 48kHz");
}

#pragma mark - Timing Calculation Tests

- (void)testSamplesPerBeatAt120BPM {
    // At 120 BPM: 60/120 = 0.5 seconds per beat
    // At 48kHz: 0.5 * 48000 = 24000 samples per beat
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];
    [self.clock start];

    // Access private property for testing via KVC
    NSNumber *samplesPerBeat = [self.clock valueForKey:@"samplesPerBeat"];
    XCTAssertEqualWithAccuracy(samplesPerBeat.doubleValue, 24000.0, 0.1,
                               @"120 BPM should yield 24000 samples per beat at 48kHz");
}

- (void)testSamplesPerBeatAt128BPM {
    // At 128 BPM: 60/128 = 0.46875 seconds per beat
    // At 48kHz: 0.46875 * 48000 = 22500 samples per beat
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:128.0
                                                 beatsPerBar:4];
    [self.clock start];

    NSNumber *samplesPerBeat = [self.clock valueForKey:@"samplesPerBeat"];
    XCTAssertEqualWithAccuracy(samplesPerBeat.doubleValue, 22500.0, 0.1,
                               @"128 BPM should yield 22500 samples per beat at 48kHz");
}

- (void)testSamplesPerBarWith4Beats {
    // At 120 BPM, 4 beats per bar: 24000 * 4 = 96000 samples per bar
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];
    [self.clock start];

    NSNumber *samplesPerBar = [self.clock valueForKey:@"samplesPerBar"];
    XCTAssertEqualWithAccuracy(samplesPerBar.doubleValue, 96000.0, 0.1,
                               @"4 beats at 120 BPM should yield 96000 samples per bar");
}

- (void)testSamplesPerBarWith3Beats {
    // At 120 BPM, 3 beats per bar: 24000 * 3 = 72000 samples per bar
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:3];
    [self.clock start];

    NSNumber *samplesPerBar = [self.clock valueForKey:@"samplesPerBar"];
    XCTAssertEqualWithAccuracy(samplesPerBar.doubleValue, 72000.0, 0.1,
                               @"3 beats at 120 BPM should yield 72000 samples per bar");
}

#pragma mark - Bar Position Tests

- (void)testCurrentBarPositionAfterStart {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];
    [self.clock start];

    double position = [self.clock currentBarPosition];

    // Position should be very close to 0 right after starting
    XCTAssertEqualWithAccuracy(position, 0.0, 0.1,
                               @"Bar position should be near 0 immediately after start");
}

#pragma mark - Next Bar Boundary Tests

- (void)testNextBarBoundaryTimeReturnsValidTime {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];
    [self.clock start];

    AVAudioTime *nextBar = [self.clock nextBarBoundaryTime];

    XCTAssertNotNil(nextBar, @"Next bar boundary time should not be nil");
    XCTAssertGreaterThanOrEqual(nextBar.sampleTime, 0, @"Next bar sample time should be non-negative");
}

- (void)testNextBarBoundaryIsInFuture {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];
    [self.clock start];

    AVAudioTime *now = [self.engine.outputNode lastRenderTime];
    AVAudioTime *nextBar = [self.clock nextBarBoundaryTime];

    XCTAssertGreaterThanOrEqual(nextBar.sampleTime, now.sampleTime,
                                @"Next bar should be at or after current time");
}

- (void)testNextBarBoundarySampleRate {
    self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                         bpm:120.0
                                                 beatsPerBar:4];
    [self.clock start];

    AVAudioTime *nextBar = [self.clock nextBarBoundaryTime];

    XCTAssertEqual(nextBar.sampleRate, 48000.0,
                   @"Next bar time should use 48kHz sample rate");
}

#pragma mark - Multiple BPM/Bar Combinations

- (void)testVariousBPMAndBarCombinations {
    NSArray *testCases = @[
        @{@"bpm": @(120.0), @"beatsPerBar": @(4), @"expectedSamplesPerBar": @(96000.0)},
        @{@"bpm": @(128.0), @"beatsPerBar": @(4), @"expectedSamplesPerBar": @(90000.0)},
        @{@"bpm": @(140.0), @"beatsPerBar": @(4), @"expectedSamplesPerBar": @(82285.7)},
        @{@"bpm": @(120.0), @"beatsPerBar": @(3), @"expectedSamplesPerBar": @(72000.0)},
    ];

    for (NSDictionary *testCase in testCases) {
        double bpm = [testCase[@"bpm"] doubleValue];
        NSInteger beatsPerBar = [testCase[@"beatsPerBar"] integerValue];
        double expected = [testCase[@"expectedSamplesPerBar"] doubleValue];

        self.clock = [[TransportClock alloc] initWithAudioEngine:self.engine
                                                             bpm:bpm
                                                     beatsPerBar:beatsPerBar];
        [self.clock start];

        NSNumber *samplesPerBar = [self.clock valueForKey:@"samplesPerBar"];
        XCTAssertEqualWithAccuracy(samplesPerBar.doubleValue, expected, 1.0,
                                   @"BPM %.1f with %ld beats should yield %.1f samples per bar",
                                   bpm, (long)beatsPerBar, expected);
    }
}

@end
