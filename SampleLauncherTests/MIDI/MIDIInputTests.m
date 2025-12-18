//
//  MIDIInputTests.m
//  SampleLauncherTests
//

#import <XCTest/XCTest.h>
#import <CoreMIDI/CoreMIDI.h>
#import "MIDIInput.h"

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

@end
