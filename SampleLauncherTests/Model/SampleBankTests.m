//
//  SampleBankTests.m
//  SampleLauncherTests
//

#import <XCTest/XCTest.h>
#import "SampleBank.h"
#import "SampleSlot.h"

// Test sample configuration
static NSString * const kTestSampleName = @"Rotations 3 Kick";

@interface SampleBankTests : XCTestCase
@property (nonatomic, strong) SampleBank *bank;
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, copy) NSString *testSamplePath;
@end

@implementation SampleBankTests

- (void)setUp {
    self.bank = [[SampleBank alloc] initWithCapacity:8];

    // Set up audio engine in manual rendering mode to avoid hardware access during tests
    self.engine = [[AVAudioEngine alloc] init];

    // Enable manual rendering mode (offline processing, no hardware I/O)
    AVAudioFormat *renderFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:48000.0
                                                                                 channels:2];
    [self.engine enableManualRenderingMode:AVAudioEngineManualRenderingModeOffline
                                    format:renderFormat
                         maximumFrameCount:4096
                                     error:nil];

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
    // Stop all slots first
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        [slot stop];
    }

    // Stop the engine
    [self.engine stop];

    // Detach any attached nodes
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        if (slot.playerNode.engine == self.engine) {
            [self.engine detachNode:slot.playerNode];
        }
    }

    self.engine = nil;
    self.bank = nil;
}

#pragma mark - Initialization Tests

- (void)testDefaultInitialization {
    SampleBank *defaultBank = [[SampleBank alloc] init];
    XCTAssertNotNil(defaultBank, @"SampleBank should initialize with default init");
    XCTAssertEqual(defaultBank.capacity, 16, @"Default capacity should be 16");
    XCTAssertEqual(defaultBank.count, 0, @"Count should be 0 with no loaded samples");
}

- (void)testInitWithCapacity {
    XCTAssertNotNil(self.bank, @"SampleBank should initialize with custom capacity");
    XCTAssertEqual(self.bank.capacity, 8, @"Capacity should match initialized value");
}

- (void)testInitWithZeroCapacity {
    SampleBank *emptyBank = [[SampleBank alloc] initWithCapacity:0];
    XCTAssertNotNil(emptyBank, @"SampleBank should handle zero capacity");
    XCTAssertEqual(emptyBank.capacity, 0, @"Capacity should be 0");
    XCTAssertEqual(emptyBank.count, 0, @"Count should be 0");
}

- (void)testSlotsPrePopulated {
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        XCTAssertNotNil(slot, @"Slot at index %lu should be pre-populated", (unsigned long)i);
    }
}

- (void)testCapacityProperty {
    SampleBank *bank16 = [[SampleBank alloc] initWithCapacity:16];
    XCTAssertEqual(bank16.capacity, 16, @"Capacity should match init value");

    SampleBank *bank4 = [[SampleBank alloc] initWithCapacity:4];
    XCTAssertEqual(bank4.capacity, 4, @"Capacity should match init value");
}

- (void)testCountPropertyEmpty {
    XCTAssertEqual(self.bank.count, 0, @"Count should be 0 when no samples are loaded");
}

- (void)testCountPropertyPartial {
    // Load samples into some slots
    SampleSlot *slot0 = [self.bank slotAtIndex:0];
    SampleSlot *slot2 = [self.bank slotAtIndex:2];
    SampleSlot *slot5 = [self.bank slotAtIndex:5];

    [slot0 loadSampleFromFile:self.testSamplePath error:nil];
    [slot2 loadSampleFromFile:self.testSamplePath error:nil];
    [slot5 loadSampleFromFile:self.testSamplePath error:nil];

    XCTAssertEqual(self.bank.count, 3, @"Count should be 3 when 3 samples are loaded");
}

- (void)testCountPropertyFull {
    // Load samples into all slots
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        [slot loadSampleFromFile:self.testSamplePath error:nil];
    }

    XCTAssertEqual(self.bank.count, self.bank.capacity,
                   @"Count should equal capacity when all slots are loaded");
}

#pragma mark - Slot Access Tests

- (void)testSlotAtValidIndex {
    SampleSlot *slot = [self.bank slotAtIndex:0];
    XCTAssertNotNil(slot, @"Should return a valid SampleSlot for valid index");
    XCTAssertTrue([slot isKindOfClass:[SampleSlot class]],
                  @"Returned object should be a SampleSlot");
}

- (void)testSlotAtZeroIndex {
    SampleSlot *slot = [self.bank slotAtIndex:0];
    XCTAssertNotNil(slot, @"First slot should be accessible");
}

- (void)testSlotAtLastIndex {
    NSUInteger lastIndex = self.bank.capacity - 1;
    SampleSlot *slot = [self.bank slotAtIndex:lastIndex];
    XCTAssertNotNil(slot, @"Last slot should be accessible");
}

- (void)testSlotAtOutOfBoundsIndex {
    SampleSlot *slot = [self.bank slotAtIndex:self.bank.capacity];
    XCTAssertNil(slot, @"Should return nil for out of bounds index");

    SampleSlot *slot2 = [self.bank slotAtIndex:999];
    XCTAssertNil(slot2, @"Should return nil for way out of bounds index");
}

- (void)testAllSlotsUnique {
    NSMutableSet *slots = [NSMutableSet set];
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        XCTAssertFalse([slots containsObject:slot],
                       @"Each slot should be a unique instance");
        [slots addObject:slot];
    }
    XCTAssertEqual(slots.count, self.bank.capacity,
                   @"Should have unique instances for all slots");
}

#pragma mark - Slot State Tests

- (void)testSlotsStartEmpty {
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        XCTAssertNil(slot.sampleName,
                     @"Slot %lu should have nil sampleName initially", (unsigned long)i);
    }
}

- (void)testSlotsHavePlayerNodes {
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        XCTAssertNotNil(slot.playerNode,
                        @"Slot %lu should have a valid playerNode", (unsigned long)i);
    }
}

- (void)testSlotsNotPlaying {
    for (NSUInteger i = 0; i < self.bank.capacity; i++) {
        SampleSlot *slot = [self.bank slotAtIndex:i];
        XCTAssertFalse(slot.isPlaying,
                       @"Slot %lu should not be playing initially", (unsigned long)i);
    }
}

#pragma mark - Integration Tests

- (void)testLoadSampleIntoSlot {
    SampleSlot *slot = [self.bank slotAtIndex:0];
    NSError *error = nil;
    BOOL success = [slot loadSampleFromFile:self.testSamplePath error:&error];

    XCTAssertTrue(success, @"Should successfully load sample into slot");
    XCTAssertNil(error, @"No error should occur");
    XCTAssertNotNil(slot.sampleName, @"Slot should have sample name after loading");
    XCTAssertEqualObjects(slot.sampleName, kTestSampleName,
                         @"Sample name should match the loaded file");
}

- (void)testMultipleSlotsIndependent {
    SampleSlot *slot0 = [self.bank slotAtIndex:0];
    SampleSlot *slot1 = [self.bank slotAtIndex:1];

    [slot0 loadSampleFromFile:self.testSamplePath error:nil];

    XCTAssertNotNil(slot0.sampleName, @"Slot 0 should have a sample loaded");
    XCTAssertNil(slot1.sampleName, @"Slot 1 should still be empty");

    // Attach nodes and play slot 0
    [self.engine attachNode:slot0.playerNode];
    [self.engine connect:slot0.playerNode to:self.engine.mainMixerNode format:nil];
    [slot0 play];

    XCTAssertTrue(slot0.isPlaying, @"Slot 0 should be playing");
    XCTAssertFalse(slot1.isPlaying, @"Slot 1 should not be affected");
}

@end
