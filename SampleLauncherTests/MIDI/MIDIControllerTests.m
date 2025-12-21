//
//  MIDIControllerTests.m
//  SampleLauncherTests
//

#import <XCTest/XCTest.h>
#import "MIDIController.h"
#import "MIDIInput.h"
#import "SampleBank.h"
#import "SampleSlot.h"
#import "TestAudioEngineHelper.h"

@interface MIDIControllerTests : XCTestCase
@property (nonatomic, strong) MIDIController *controller;
@property (nonatomic, strong) MIDIInput *midiInput;
@property (nonatomic, strong) SampleBank *sampleBank;
@property (nonatomic, strong) AVAudioEngine *engine;
@property (nonatomic, strong) NSMutableArray *receivedNotifications;
@end

@implementation MIDIControllerTests

- (void)setUp {
    self.midiInput = [[MIDIInput alloc] init];
    self.sampleBank = [[SampleBank alloc] initWithCapacity:16];
    self.controller = [[MIDIController alloc] initWithMIDIInput:self.midiInput
                                                     sampleBank:self.sampleBank];

    // Set up audio engine for slot testing
    self.engine = [TestAudioEngineHelper createTestEngineWithTestCase:self];
    [self.sampleBank attachToAudioEngine:self.engine];

    // Set up notification tracking
    self.receivedNotifications = [NSMutableArray array];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSampleSlotNotification:)
                                                 name:@"SampleSlotDidChange"
                                               object:nil];
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    // Stop all slots
    for (NSUInteger i = 0; i < self.sampleBank.capacity; i++) {
        SampleSlot *slot = [self.sampleBank slotAtIndex:i];
        [slot stop];
    }

    [self.engine stop];
    self.engine = nil;
    self.controller = nil;
    self.midiInput = nil;
    self.sampleBank = nil;
    self.receivedNotifications = nil;
}

- (void)handleSampleSlotNotification:(NSNotification *)notification {
    [self.receivedNotifications addObject:notification];
}

#pragma mark - Initialization Tests

- (void)testInitialization {
    XCTAssertNotNil(self.controller, @"Controller should initialize");
}

- (void)testSetsItselfAsDelegate {
    XCTAssertEqual(self.midiInput.inputDelegate, self.controller,
                   @"Controller should set itself as MIDIInput delegate");
}

#pragma mark - Note Mapping Tests

- (void)testNoteOnMapsToCorrectSlot_FirstSlot {
    // Note 48 (C2) should map to slot 0
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:48];

    // Wait for async notification
    [self waitForNotificationWithTimeout:0.5];

    XCTAssertEqual(self.receivedNotifications.count, 1,
                   @"Should receive one notification");

    NSNotification *notification = self.receivedNotifications.firstObject;
    NSNumber *slotIndex = notification.userInfo[@"slotIndex"];
    XCTAssertEqualObjects(slotIndex, @(0),
                         @"Note 48 should map to slot 0");
}

- (void)testNoteOnMapsToCorrectSlot_LastSlot {
    // Note 63 (D#3) should map to slot 15
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:63];

    [self waitForNotificationWithTimeout:0.5];

    XCTAssertEqual(self.receivedNotifications.count, 1,
                   @"Should receive one notification");

    NSNotification *notification = self.receivedNotifications.firstObject;
    NSNumber *slotIndex = notification.userInfo[@"slotIndex"];
    XCTAssertEqualObjects(slotIndex, @(15),
                         @"Note 63 should map to slot 15");
}

- (void)testNoteOnMapsToCorrectSlot_MiddleSlot {
    // Note 55 (G2) should map to slot 7
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:55];

    [self waitForNotificationWithTimeout:0.5];

    XCTAssertEqual(self.receivedNotifications.count, 1,
                   @"Should receive one notification");

    NSNotification *notification = self.receivedNotifications.firstObject;
    NSNumber *slotIndex = notification.userInfo[@"slotIndex"];
    XCTAssertEqualObjects(slotIndex, @(7),
                         @"Note 55 should map to slot 7");
}

- (void)testAllNotesInRangeMapCorrectly {
    // Test all 16 notes in the valid range
    for (UInt8 note = 48; note <= 63; note++) {
        [self.receivedNotifications removeAllObjects];

        [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:note];
        [self waitForNotificationWithTimeout:0.5];

        NSUInteger expectedSlot = note - 48;
        NSNotification *notification = self.receivedNotifications.firstObject;
        NSNumber *slotIndex = notification.userInfo[@"slotIndex"];

        XCTAssertEqualObjects(slotIndex, @(expectedSlot),
                             @"Note %d should map to slot %lu", note, (unsigned long)expectedSlot);
    }
}

#pragma mark - Out of Range Tests

- (void)testIgnoresNoteBelowRange {
    // Note 47 is below the valid range
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:47];

    [self waitForNotificationWithTimeout:0.5];

    XCTAssertEqual(self.receivedNotifications.count, 0,
                   @"Should not receive notification for note below range");
}

- (void)testIgnoresNoteAboveRange {
    // Note 64 is above the valid range
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:64];

    [self waitForNotificationWithTimeout:0.5];

    XCTAssertEqual(self.receivedNotifications.count, 0,
                   @"Should not receive notification for note above range");
}

- (void)testIgnoresVeryLowNote {
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:0];

    [self waitForNotificationWithTimeout:0.5];

    XCTAssertEqual(self.receivedNotifications.count, 0,
                   @"Should not receive notification for very low note");
}

- (void)testIgnoresVeryHighNote {
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:127];

    [self waitForNotificationWithTimeout:0.5];

    XCTAssertEqual(self.receivedNotifications.count, 0,
                   @"Should not receive notification for very high note");
}

#pragma mark - Notification Tests

- (void)testNotificationContainsCorrectSlot {
    SampleSlot *slot = [self.sampleBank slotAtIndex:5];

    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:53]; // Note 53 -> slot 5

    [self waitForNotificationWithTimeout:0.5];

    NSNotification *notification = self.receivedNotifications.firstObject;
    XCTAssertNotNil(notification, @"Should receive notification");
    XCTAssertEqualObjects(notification.object, slot,
                         @"Notification object should be the triggered slot");
}

- (void)testNotificationPostedOnMainThread {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Notification on main thread"];

    __block BOOL isMainThread = NO;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"SampleSlotDidChange"
                                                       object:nil
                                                        queue:nil
                                                   usingBlock:^(NSNotification *note) {
        isMainThread = [NSThread isMainThread];
        [expectation fulfill];
    }];

    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:48];

    [self waitForExpectations:@[expectation] timeout:1.0];

    XCTAssertTrue(isMainThread, @"Notification should be posted on main thread");
}

- (void)testMultipleNotesGenerateMultipleNotifications {
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:48];
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:50];
    [self.midiInput.inputDelegate midiInput:self.midiInput didReceiveNoteOn:52];

    [self waitForNotificationWithTimeout:0.5];

    XCTAssertGreaterThanOrEqual(self.receivedNotifications.count, 3,
                                @"Should receive at least 3 notifications");
}

#pragma mark - Helper Methods

- (void)waitForNotificationWithTimeout:(NSTimeInterval)timeout {
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while ([timeoutDate timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
    }
}

@end
