//
//  MIDIInputTests.m
//  SampleLauncherTests
//

#import <XCTest/XCTest.h>
#import <CoreMIDI/CoreMIDI.h>
#import "MIDIInput.h"

// Test delegate to capture MIDI events
@interface TestMIDIInputDelegate : NSObject <MIDIInputDelegate>
@property (nonatomic, strong) NSMutableArray<NSNumber *> *receivedNotes;
@property (nonatomic, strong) XCTestExpectation *expectation;
@property (nonatomic, assign) NSUInteger expectedCount;
@end

@implementation TestMIDIInputDelegate

- (instancetype)init {
    self = [super init];
    if (self) {
        _receivedNotes = [NSMutableArray array];
    }
    return self;
}

- (void)midiInput:(MIDIInput *)input didReceiveNoteOn:(UInt8)noteNumber {
    @synchronized(self.receivedNotes) {
        [self.receivedNotes addObject:@(noteNumber)];

        if (self.expectation && self.receivedNotes.count >= self.expectedCount) {
            [self.expectation fulfill];
        }
    }
}

@end

@interface MIDIInputTests : XCTestCase

@property (nonatomic, assign) MIDIClientRef testClient;
@property (nonatomic, assign) MIDIEndpointRef virtualSource1;
@property (nonatomic, assign) MIDIEndpointRef virtualSource2;

@end

@implementation MIDIInputTests

- (void)setUp {
    // Create a MIDI client for testing
    OSStatus status = MIDIClientCreate(CFSTR("Test MIDI Client"), NULL, NULL, &_testClient);
    XCTAssertEqual(status, noErr, @"Failed to create test MIDI client");

    // Create virtual MIDI sources for testing
    status = MIDISourceCreate(_testClient, CFSTR("Test Virtual Source 1"), &_virtualSource1);
    XCTAssertEqual(status, noErr, @"Failed to create virtual source 1");

    status = MIDISourceCreate(_testClient, CFSTR("Test Virtual Source 2"), &_virtualSource2);
    XCTAssertEqual(status, noErr, @"Failed to create virtual source 2");
}

- (void)tearDown {
    // Clean up virtual MIDI sources
    if (_virtualSource1) {
        MIDIEndpointDispose(_virtualSource1);
        _virtualSource1 = 0;
    }
    if (_virtualSource2) {
        MIDIEndpointDispose(_virtualSource2);
        _virtualSource2 = 0;
    }

    // Clean up MIDI client
    if (_testClient) {
        MIDIClientDispose(_testClient);
        _testClient = 0;
    }

    [super tearDown];
}

- (void)testListSourcesReturnsVirtualDevices {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    NSArray<NSString *> *sources = [midiInput listSources];

    // Should contain at least our two virtual sources
    XCTAssertGreaterThanOrEqual(sources.count, 2, @"Should find at least 2 MIDI sources");

    // Check that our virtual sources are in the list
    BOOL foundSource1 = NO;
    BOOL foundSource2 = NO;

    for (NSString *sourceName in sources) {
        if ([sourceName isEqualToString:@"Test Virtual Source 1"]) {
            foundSource1 = YES;
        }
        if ([sourceName isEqualToString:@"Test Virtual Source 2"]) {
            foundSource2 = YES;
        }
    }

    XCTAssertTrue(foundSource1, @"Should find Test Virtual Source 1");
    XCTAssertTrue(foundSource2, @"Should find Test Virtual Source 2");
}

- (void)testListSourcesReturnsEmptyArrayWhenNoDevices {
    // Dispose of virtual sources first
    if (_virtualSource1) {
        MIDIEndpointDispose(_virtualSource1);
        _virtualSource1 = 0;
    }
    if (_virtualSource2) {
        MIDIEndpointDispose(_virtualSource2);
        _virtualSource2 = 0;
    }

    MIDIInput *midiInput = [[MIDIInput alloc] init];
    NSArray<NSString *> *sources = [midiInput listSources];

    // May be empty or contain system MIDI sources depending on the machine
    XCTAssertNotNil(sources, @"listSources should return a non-nil array");
}

- (void)testListSourcesMultipleCalls {
    MIDIInput *midiInput = [[MIDIInput alloc] init];

    // Call listSources multiple times
    NSArray<NSString *> *sources1 = [midiInput listSources];
    NSArray<NSString *> *sources2 = [midiInput listSources];

    // Should return consistent results
    XCTAssertEqual(sources1.count, sources2.count, @"Multiple calls should return same count");
    XCTAssertEqualObjects(sources1, sources2, @"Multiple calls should return same sources");
}

- (void)testInitialSelectionIsNil {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    XCTAssertNil(midiInput.selectedSourceName, @"Initially no source should be selected");
}

- (void)testSelectSourceAtValidIndex {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    NSArray<NSString *> *sources = [midiInput listSources];

    // Should have at least 2 virtual sources from setUp
    XCTAssertGreaterThanOrEqual(sources.count, 2, @"Should have at least 2 sources");

    // Select the first source
    BOOL success = [midiInput selectSourceAtIndex:0];
    XCTAssertTrue(success, @"Should successfully select source at index 0");
    XCTAssertNotNil(midiInput.selectedSourceName, @"Selected source name should not be nil");
    XCTAssertEqualObjects(midiInput.selectedSourceName, sources[0], @"Selected source name should match");
}

- (void)testSelectSourceAtInvalidIndex {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    NSArray<NSString *> *sources = [midiInput listSources];

    // Try to select an index beyond the available sources
    BOOL success = [midiInput selectSourceAtIndex:sources.count + 100];
    XCTAssertFalse(success, @"Should fail to select source at invalid index");
    XCTAssertNil(midiInput.selectedSourceName, @"Selected source name should remain nil");
}

- (void)testSelectDifferentSources {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    NSArray<NSString *> *sources = [midiInput listSources];

    // Should have at least 2 virtual sources
    XCTAssertGreaterThanOrEqual(sources.count, 2, @"Should have at least 2 sources");

    // Select first source
    [midiInput selectSourceAtIndex:0];
    NSString *firstSourceName = midiInput.selectedSourceName;
    XCTAssertNotNil(firstSourceName, @"First source name should not be nil");

    // Select second source
    [midiInput selectSourceAtIndex:1];
    NSString *secondSourceName = midiInput.selectedSourceName;
    XCTAssertNotNil(secondSourceName, @"Second source name should not be nil");

    // Should be different sources
    XCTAssertNotEqualObjects(firstSourceName, secondSourceName, @"Different indices should select different sources");
    XCTAssertEqualObjects(secondSourceName, sources[1], @"Second source name should match");
}

#pragma mark - Ring Buffer Integration Tests

// Helper to send MIDI 2.0 events
- (void)sendMIDI2NoteOn:(UInt8)noteNumber velocity:(UInt16)velocity toSource:(MIDIEndpointRef)source {
    // Create MIDI 2.0 Universal MIDI Packet (UMP) for Note On
    // Format: [message_type, group, status, channel, note, 0, velocity_msb, velocity_lsb]
    MIDIEventList eventList;
    eventList.protocol = kMIDIProtocol_2_0;
    eventList.numPackets = 1;

    MIDIEventPacket *packet = (MIDIEventPacket *)&eventList.packet[0];
    packet->timeStamp = 0;
    packet->wordCount = 2; // MIDI 2.0 Channel Voice messages are 2 words (64 bits)

    // Word 0: [message_type:4][group:4][status:4][channel:4][note:8][attribute_type:8]
    // Word 1: [velocity:16][attribute_data:16]
    UInt32 word0 = (0x4 << 28) |        // Message type: Channel Voice 2.0
                   (0x0 << 24) |        // Group: 0
                   (0x9 << 20) |        // Status: Note On
                   (0x0 << 16) |        // Channel: 0
                   (noteNumber << 8) |  // Note number
                   (0x0);               // Attribute type: none

    UInt32 word1 = (velocity << 16);    // Velocity (16-bit)

    packet->words[0] = word0;
    packet->words[1] = word1;

    // Send the event
    OSStatus status = MIDIReceivedEventList(source, &eventList);
    if (status != noErr) {
        NSLog(@"Failed to send MIDI event: %d", status);
    }
}

- (void)testReceiveSingleMIDIEvent {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    TestMIDIInputDelegate *delegate = [[TestMIDIInputDelegate alloc] init];
    midiInput.inputDelegate = delegate;

    // Connect to virtual source 1
    NSArray<NSString *> *sources = [midiInput listSources];
    NSUInteger sourceIndex = [sources indexOfObject:@"Test Virtual Source 1"];
    XCTAssertNotEqual(sourceIndex, NSNotFound, @"Should find Test Virtual Source 1");
    [midiInput selectSourceAtIndex:sourceIndex];

    // Set up expectation
    delegate.expectation = [self expectationWithDescription:@"Receive MIDI event"];
    delegate.expectedCount = 1;

    // Send a MIDI note-on event (note 60, middle C)
    [self sendMIDI2NoteOn:60 velocity:0x8000 toSource:_virtualSource1];

    // Wait for the event to be processed through the ring buffer
    [self waitForExpectations:@[delegate.expectation] timeout:0.1];

    XCTAssertEqual(delegate.receivedNotes.count, 1, @"Should receive exactly 1 note");
    XCTAssertEqualObjects(delegate.receivedNotes[0], @(60), @"Should receive note 60");
}

- (void)testReceiveMultipleMIDIEvents {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    TestMIDIInputDelegate *delegate = [[TestMIDIInputDelegate alloc] init];
    midiInput.inputDelegate = delegate;

    // Connect to virtual source 1
    NSArray<NSString *> *sources = [midiInput listSources];
    NSUInteger sourceIndex = [sources indexOfObject:@"Test Virtual Source 1"];
    [midiInput selectSourceAtIndex:sourceIndex];

    // Set up expectation for 5 events
    delegate.expectation = [self expectationWithDescription:@"Receive multiple MIDI events"];
    delegate.expectedCount = 5;

    // Send multiple note-on events
    [self sendMIDI2NoteOn:60 velocity:0x8000 toSource:_virtualSource1];
    [self sendMIDI2NoteOn:64 velocity:0x7000 toSource:_virtualSource1];
    [self sendMIDI2NoteOn:67 velocity:0x6000 toSource:_virtualSource1];
    [self sendMIDI2NoteOn:72 velocity:0x5000 toSource:_virtualSource1];
    [self sendMIDI2NoteOn:76 velocity:0x4000 toSource:_virtualSource1];

    // Wait for events to be processed
    [self waitForExpectations:@[delegate.expectation] timeout:0.2];

    XCTAssertEqual(delegate.receivedNotes.count, 5, @"Should receive exactly 5 notes");
    XCTAssertEqualObjects(delegate.receivedNotes[0], @(60), @"First note should be 60");
    XCTAssertEqualObjects(delegate.receivedNotes[1], @(64), @"Second note should be 64");
    XCTAssertEqualObjects(delegate.receivedNotes[2], @(67), @"Third note should be 67");
    XCTAssertEqualObjects(delegate.receivedNotes[3], @(72), @"Fourth note should be 72");
    XCTAssertEqualObjects(delegate.receivedNotes[4], @(76), @"Fifth note should be 76");
}

- (void)testReceiveRapidMIDIEvents {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    TestMIDIInputDelegate *delegate = [[TestMIDIInputDelegate alloc] init];
    midiInput.inputDelegate = delegate;

    // Connect to virtual source 1
    NSArray<NSString *> *sources = [midiInput listSources];
    NSUInteger sourceIndex = [sources indexOfObject:@"Test Virtual Source 1"];
    [midiInput selectSourceAtIndex:sourceIndex];

    // Send 50 rapid events to stress test the ring buffer
    const NSUInteger eventCount = 50;
    delegate.expectation = [self expectationWithDescription:@"Receive rapid MIDI events"];
    delegate.expectedCount = eventCount;

    for (NSUInteger i = 0; i < eventCount; i++) {
        UInt8 note = 48 + (i % 16); // Cycle through notes 48-63
        [self sendMIDI2NoteOn:note velocity:0x8000 toSource:_virtualSource1];
    }

    // Wait for events to be processed
    [self waitForExpectations:@[delegate.expectation] timeout:1.0];

    XCTAssertEqual(delegate.receivedNotes.count, eventCount,
                   @"Should receive all %lu events without dropping any", (unsigned long)eventCount);
}

- (void)testIgnoresVelocityZeroNoteOn {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    TestMIDIInputDelegate *delegate = [[TestMIDIInputDelegate alloc] init];
    midiInput.inputDelegate = delegate;

    // Connect to virtual source 1
    NSArray<NSString *> *sources = [midiInput listSources];
    NSUInteger sourceIndex = [sources indexOfObject:@"Test Virtual Source 1"];
    [midiInput selectSourceAtIndex:sourceIndex];

    // Send velocity 0 note-on (should be ignored)
    [self sendMIDI2NoteOn:60 velocity:0x0000 toSource:_virtualSource1];

    // Send normal note-on (should be received)
    delegate.expectation = [self expectationWithDescription:@"Receive non-zero velocity event"];
    delegate.expectedCount = 1;
    [self sendMIDI2NoteOn:64 velocity:0x8000 toSource:_virtualSource1];

    // Wait for processing
    [self waitForExpectations:@[delegate.expectation] timeout:0.1];

    // Should only receive the non-zero velocity event
    XCTAssertEqual(delegate.receivedNotes.count, 1, @"Should only receive 1 note");
    XCTAssertEqualObjects(delegate.receivedNotes[0], @(64), @"Should receive note 64 only");
}

- (void)testRingBufferOrderPreserved {
    MIDIInput *midiInput = [[MIDIInput alloc] init];
    TestMIDIInputDelegate *delegate = [[TestMIDIInputDelegate alloc] init];
    midiInput.inputDelegate = delegate;

    // Connect to virtual source 1
    NSArray<NSString *> *sources = [midiInput listSources];
    NSUInteger sourceIndex = [sources indexOfObject:@"Test Virtual Source 1"];
    [midiInput selectSourceAtIndex:sourceIndex];

    // Send events in specific order
    delegate.expectation = [self expectationWithDescription:@"Receive ordered events"];
    delegate.expectedCount = 10;

    UInt8 expectedNotes[] = {48, 50, 52, 54, 56, 58, 60, 62, 61, 59};
    for (int i = 0; i < 10; i++) {
        [self sendMIDI2NoteOn:expectedNotes[i] velocity:0x8000 toSource:_virtualSource1];
    }

    // Wait for processing
    [self waitForExpectations:@[delegate.expectation] timeout:0.2];

    // Verify order is preserved
    XCTAssertEqual(delegate.receivedNotes.count, 10, @"Should receive all 10 notes");
    for (int i = 0; i < 10; i++) {
        XCTAssertEqualObjects(delegate.receivedNotes[i], @(expectedNotes[i]),
                             @"Note at index %d should match expected order", i);
    }
}

- (void)testMultipleSourcesIndependent {
    MIDIInput *midiInput1 = [[MIDIInput alloc] init];
    MIDIInput *midiInput2 = [[MIDIInput alloc] init];

    TestMIDIInputDelegate *delegate1 = [[TestMIDIInputDelegate alloc] init];
    TestMIDIInputDelegate *delegate2 = [[TestMIDIInputDelegate alloc] init];

    midiInput1.inputDelegate = delegate1;
    midiInput2.inputDelegate = delegate2;

    // Connect to different virtual sources
    NSArray<NSString *> *sources = [midiInput1 listSources];
    NSUInteger source1Index = [sources indexOfObject:@"Test Virtual Source 1"];
    NSUInteger source2Index = [sources indexOfObject:@"Test Virtual Source 2"];

    [midiInput1 selectSourceAtIndex:source1Index];
    [midiInput2 selectSourceAtIndex:source2Index];

    delegate1.expectation = [self expectationWithDescription:@"Receive from source 1"];
    delegate1.expectedCount = 1;

    delegate2.expectation = [self expectationWithDescription:@"Receive from source 2"];
    delegate2.expectedCount = 1;

    // Send different notes to different sources
    [self sendMIDI2NoteOn:60 velocity:0x8000 toSource:_virtualSource1];
    [self sendMIDI2NoteOn:72 velocity:0x8000 toSource:_virtualSource2];

    // Wait for both
    [self waitForExpectations:@[delegate1.expectation, delegate2.expectation] timeout:0.2];

    // Each should only receive their own events
    XCTAssertEqual(delegate1.receivedNotes.count, 1, @"Input 1 should receive 1 note");
    XCTAssertEqual(delegate2.receivedNotes.count, 1, @"Input 2 should receive 1 note");
    XCTAssertEqualObjects(delegate1.receivedNotes[0], @(60), @"Input 1 should receive note 60");
    XCTAssertEqualObjects(delegate2.receivedNotes[0], @(72), @"Input 2 should receive note 72");
}

@end
