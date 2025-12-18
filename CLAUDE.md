# SampleLauncher - MIDI-Controlled Audio Sample Playback

A native macOS application that enables real-time audio sample playback controlled via USB MIDI devices.

## Project Overview

SampleLauncher demonstrates real-time audio processing with AVFoundation, MIDI integration using CoreMIDI, and native macOS application development with a clean, extensible architecture.

## Requirements

### Core Functionality
- Play back multiple different audio samples
- Connect USB MIDI device to start/stop samples using MIDI notes
- Intuitive UI presenting samples and their playback state
- Architected for configurability and future extensibility

### Technical Constraints
- **Language**: C / C++ / Objective-C
- **Platform**: Native macOS Application
- **Frameworks**: Apple system frameworks only (AppKit, AVFoundation, CoreMIDI)

### MIDI Mapping
- Fixed MIDI note assignments: C1 → Sample 1, C#1 → Sample 2, etc.
- Each MIDI note toggles playback of its assigned sample

## Architecture

### Overview

The application follows a clean MVC architecture with distinct separation of concerns:

- **Model Layer**: `SampleSlot` (individual samples) and `SampleBank` (collection manager)
- **View Layer**: `SampleSlotView` (individual UI cells) and `SampleBankView` (grid container)
- **Controller Layer**: `ViewController` (view management) and `AppDelegate` (app lifecycle, audio engine)
- **MIDI Layer**: `MIDIInput` (CoreMIDI integration)

**Data Flow:**
1. `AppDelegate` initializes audio engine and creates `SampleBank`
2. Stock samples loaded from bundle into `SampleBank` slots
3. All `AVAudioPlayerNode` instances attached to audio engine
4. `ViewController` creates `SampleBankView` with 16 slot views
5. (Future) MIDI events → `SampleSlot.toggle()` → UI updates

**Current State:**
- Model and View layers fully implemented
- Audio engine initialized and running
- MIDI enumeration working
- Integration between layers still in progress

### Core Components

#### SampleSlot (`SampleLauncher/Model/SampleSlot.h/.m`)
Encapsulates a single audio sample and its playback state.

**Key Features:**
- Uses `AVAudioPlayerNode` for sample playback
- Loads audio files into `AVAudioPCMBuffer` for efficient playback
- Provides play/stop/toggle operations
- Exposes `isPlaying` state for UI binding

**Public Interface:**
```objc
@interface SampleSlot : NSObject

@property (nonatomic, strong, readonly) AVAudioPlayerNode *playerNode;
@property (nonatomic, copy, readonly, nullable) NSString *sampleName;
@property (nonatomic, readonly) BOOL isPlaying;

- (instancetype)init;
- (BOOL)loadSampleFromFile:(NSString *)filePath error:(NSError **)error;
- (void)play;
- (void)stop;
- (void)toggle;

@end
```

**Implementation Details:**
- **Audio Engine Integration**: Each `SampleSlot` contains an `AVAudioPlayerNode` that must be attached to an `AVAudioEngine`
- **Sample Loading**: Reads entire audio file into memory via `AVAudioPCMBuffer` for zero-latency playback
- **Retriggering**: Calling `play()` while playing stops and restarts from the beginning
- **Sample Name**: Automatically extracted from filename (without extension)

#### SampleBank (`SampleLauncher/Model/SampleBank.h/.m`)
Manages a collection of `SampleSlot` instances as a cohesive bank.

**Key Features:**
- Pre-allocates `SampleSlot` array with configurable capacity (default 16)
- Provides safe indexed access to slots
- Tracks count of loaded samples
- Bulk attachment of all player nodes to audio engine

**Public Interface:**
```objc
@interface SampleBank : NSObject

@property (nonatomic, readonly) NSUInteger capacity;
@property (nonatomic, readonly) NSUInteger count;

- (instancetype)initWithCapacity:(NSUInteger)capacity;
- (nullable SampleSlot *)slotAtIndex:(NSUInteger)index;
- (void)attachToAudioEngine:(AVAudioEngine *)engine;
- (BOOL)loadSampleAtIndex:(NSUInteger)index fromFile:(NSString *)filePath error:(NSError **)error;

@end
```

**Implementation Details:**
- **Capacity vs Count**: `capacity` is fixed at initialization, `count` reflects loaded samples
- **Slot Pre-allocation**: All slots created at init, ready for sample loading
- **Engine Integration**: `attachToAudioEngine:` connects all player nodes to mixer in one call
- **Load Convenience**: `loadSampleAtIndex:fromFile:error:` provides simplified loading API

#### MIDIInput (`SampleLauncher/MIDI/MIDIInput.h/.m`)
Handles MIDI device enumeration and source selection using CoreMIDI.

**Key Features:**
- Lists all available MIDI sources
- Allows selection of MIDI input source by index
- Exposes selected source name

**Public Interface:**
```objc
@interface MIDIInput : NSObject

- (NSArray<NSString *> *)listSources;
- (BOOL)selectSourceAtIndex:(NSUInteger)index;
@property (nonatomic, copy, readonly, nullable) NSString *selectedSourceName;

@end
```

**Implementation Details:**
- **Source Enumeration**: Uses `MIDIGetNumberOfSources()` and `MIDIGetSource()`
- **Device Names**: Retrieves friendly names via `kMIDIPropertyName`
- **Selection**: Stores `MIDIEndpointRef` for selected source
- **Not Yet Implemented**: MIDI message parsing, note-on/note-off handling, callback setup

#### SampleSlotView (`SampleLauncher/Views/SampleSlotView.h/.m`)
Custom NSView representing a single sample slot in the UI.

**Key Features:**
- Displays MIDI note name
- Shows loaded sample name
- Visual feedback for playing state
- Horizontal progress meter for playback position

**Public Interface:**
```objc
@interface SampleSlotView : NSView

@property (nonatomic, copy) NSString *noteName;
@property (nonatomic, copy, nullable) NSString *sampleName;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) CGFloat progress; // 0.0 to 1.0

- (instancetype)initWithFrame:(NSRect)frameRect noteName:(NSString *)noteName;
- (void)updateFromSampleSlot:(SampleSlot *)sampleSlot;

@end
```

**Implementation Details:**
- **Note Label**: Large, semibold, centered display of MIDI note (e.g., "C1")
- **Sample Label**: Smaller text showing loaded sample name
- **Progress Layer**: CALayer animating horizontal fill during playback
- **Color States**: Different background colors for empty/loaded/playing states
- **Not Yet Implemented**: Click handling for manual triggering

#### SampleBankView (`SampleLauncher/Views/SampleBankView.h/.m`)
Container view displaying a grid of `SampleSlotView` instances.

**Key Features:**
- 4x4 grid layout for 16 samples
- Automatic MIDI note naming (C1 through D#2)
- Syncs with `SampleBank` model state

**Public Interface:**
```objc
@interface SampleBankView : NSView

- (instancetype)initWithFrame:(NSRect)frameRect capacity:(NSUInteger)capacity;
- (void)updateFromSampleBank:(SampleBank *)sampleBank;

@end
```

**Implementation Details:**
- **Grid Layout**: Uses Auto Layout constraints for 4 columns × 4 rows
- **Note Names**: Chromatic sequence starting from C1 (MIDI note 36)
- **Dynamic Updates**: `updateFromSampleBank:` refreshes all slot views from model
- **Not Yet Implemented**: Real-time updates during playback, user interaction

#### AppDelegate (`SampleLauncher/AppDelegate.h/.m`)
Application delegate managing audio engine lifecycle and stock sample loading.

**Key Features:**
- Initializes and starts `AVAudioEngine`
- Creates `SampleBank` with 16 slots
- Loads stock samples from bundle on launch
- Exposes `sampleBank` for app-wide access

**Public Interface:**
```objc
@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (nonatomic, strong, readonly) SampleBank *sampleBank;

@end
```

**Implementation Details:**
- **Audio Engine**: Created in `applicationDidFinishLaunching:`, started after sample loading
- **Stock Sample Loading**: Scans `StockSamples/` for `.aif` files, loads alphabetically
- **Error Handling**: Logs and gracefully handles loading/engine failures
- **Notification**: Posts `SamplesDidLoad` notification when loading completes
- **Cleanup**: Stops audio engine in `applicationWillTerminate:`

#### ViewController (`SampleLauncher/ViewController.h/.m`)
Main view controller displaying the sample bank UI.

**Key Features:**
- Creates and configures `SampleBankView`
- Sets up Auto Layout constraints
- Centers bank view in window with padding

**Implementation Details:**
- **View Setup**: Initializes `SampleBankView` with 16 capacity in `viewDidLoad`
- **Layout**: Centers view with 20pt padding on all sides
- **Not Yet Implemented**: Sample playback control, MIDI integration, state updates

### Stock Audio Samples

Located in `StockSamples/`, includes 16 high-quality audio samples:
- Custom-produced 8-bar loops at 128 BPM
- Stems from an original music track
- Includes drums, synths, bass, and melodic elements
- Format: 48kHz, stereo .aif files
- All samples exactly the same length for phrase-synchronized playback

**Design Decision:**
The application is designed to work with loop-based samples rather than one-shots, similar to Ableton's clip view. All stock samples are 8 bars at 128 BPM, avoiding the need for dynamic BPM detection or time-stretching. This ensures samples can be triggered and stopped while maintaining musical phrase alignment.

## Testing

### Unit Tests

#### SampleSlotTests (`SampleLauncherTests/Model/SampleSlotTests.m`)
Comprehensive test suite for `SampleSlot` class:

**Test Coverage:**
- Initialization state
- Sample loading (success and failure cases)
- Play/stop operations
- Toggle functionality
- Retriggering behavior
- Playing without loaded sample (safety)

**Testing Strategy:**
- Uses `AVAudioEngine` in **manual rendering mode** (offline processing)
- Avoids hardware I/O during tests
- Sample rate: 48kHz, Stereo, maximum 4096 frames
- Configurable test sample via `kTestSampleName` constant

#### SampleBankTests (`SampleLauncherTests/Model/SampleBankTests.m`)
Comprehensive test suite for `SampleBank` class:

**Test Coverage:**
- Default and custom capacity initialization
- Slot pre-population and access
- Count property (empty, partial, full states)
- Out-of-bounds index handling
- Slot independence
- Integration with `SampleSlot` loading

**Testing Strategy:**
- Uses `TestAudioEngineHelper` for consistent test engine setup
- Tests with capacity of 8 for faster execution
- Verifies each slot is unique instance

#### MIDIInputTests (`SampleLauncherTests/MIDI/MIDIInputTests.m`)
Test suite for `MIDIInput` class:

**Test Coverage:**
- Listing available MIDI sources
- Source selection (valid and invalid indices)
- Selected source name property
- Multiple source switching
- Virtual MIDI device detection

**Testing Strategy:**
- Creates virtual MIDI sources using `MIDISourceCreate()`
- Tests with 2 virtual devices ("Test Virtual Source 1" and "Test Virtual Source 2")
- Proper cleanup of MIDI resources in tearDown

#### TestAudioEngineHelper (`SampleLauncherTests/TestAudioEngineHelper.h/.m`)
Utility class providing consistent audio engine setup for tests:

**Functionality:**
- Creates `AVAudioEngine` configured for manual rendering mode
- Sets up 48kHz stereo format with 4096 frame buffer
- Enables offline processing for deterministic tests
- Centralizes test engine configuration

**Running Tests:**
```bash
xcodebuild test -scheme SampleLauncher -destination 'platform=macOS'
```

### UI Tests
Basic UI test scaffolding in `SampleLauncherUITests/`.

## Development Guidelines

### Current State

**Implemented:**
- [x] SampleSlot audio playback model
- [x] Sample loading from files
- [x] Play/stop/toggle controls
- [x] SampleBank collection manager (16 slots)
- [x] Audio engine setup and initialization (AppDelegate)
- [x] Stock sample loading on app launch
- [x] All player nodes attached to audio engine
- [x] SampleSlotView UI component (note, sample name, state, progress)
- [x] SampleBankView 4x4 grid layout
- [x] ViewController with centered bank view
- [x] MIDIInput source enumeration and selection
- [x] Comprehensive unit tests (SampleSlot, SampleBank, MIDIInput)
- [x] TestAudioEngineHelper for consistent test setup
- [x] Stock sample library (8-bar loops at 128 BPM)

**Not Yet Implemented:**
- [ ] MIDI note-on/note-off message parsing
- [ ] MIDI client and port setup with callbacks
- [ ] Connecting MIDI events to sample playback
- [ ] Real-time UI updates during sample playback
- [ ] Progress meter animation during playback
- [ ] Click handlers for manual sample triggering in UI
- [ ] Phrase-synchronized playback timing
- [ ] MIDI device connection/disconnection notifications
- [ ] Integration between ViewController and AppDelegate's SampleBank

### Extending the Application

The architecture is designed for easy extension:

#### Completing MIDI Support
The `MIDIInput` class provides source enumeration and selection. To complete MIDI integration:

1. **Add MIDI Client and Port Setup**
   - Create `MIDIClientRef` and `MIDIPortRef` in `MIDIInput`
   - Set up input port with `MIDIInputPortCreate()`
   - Connect selected source to port with `MIDIPortConnectSource()`

2. **Implement MIDI Message Parsing**
   - Create MIDI read callback function
   - Parse MIDI packets for note-on (status 0x90) and note-off (status 0x80)
   - Extract MIDI note number and velocity

3. **Map MIDI Notes to Sample Slots**
   - C1 (MIDI note 36) → slot 0
   - C#1 (MIDI note 37) → slot 1
   - Continue chromatically through D#2 (MIDI note 51) → slot 15

4. **Connect to Sample Playback**
   - Access `AppDelegate.sampleBank` from MIDI callback
   - Call `toggle` on corresponding `SampleSlot`
   - Consider velocity for future volume control

#### Connecting UI to Model
The UI components exist but need integration:

1. **Wire ViewController to SampleBank**
   - Get `sampleBank` reference from `AppDelegate`
   - Call `[bankView updateFromSampleBank:sampleBank]` after samples load
   - Listen for `SamplesDidLoad` notification

2. **Implement Real-time Updates**
   - Set up display link or timer in `ViewController`
   - Periodically call `updateFromSampleBank:` to refresh UI
   - Update progress meters based on playback position

3. **Add User Interaction**
   - Implement `mouseDown:` in `SampleSlotView`
   - Determine which slot was clicked
   - Call `toggle` on corresponding `SampleSlot`
   - Update UI immediately for responsive feedback

#### Implementing Phrase Sync
For synchronized loop playback:

1. **Track Playback Timeline**
   - Maintain global timeline based on 128 BPM (8 bars = ~15 seconds)
   - Calculate sample frame positions for phrase boundaries

2. **Schedule Playback at Phrase Boundaries**
   - When user triggers sample, calculate next phrase boundary
   - Use `scheduleBuffer:atTime:` with future `AVAudioTime`
   - Ensure all samples start/stop on phrase boundaries

3. **Progress Calculation**
   - Track current playback frame in each `SampleSlot`
   - Calculate progress as `currentFrame / totalFrames`
   - Update `SampleSlotView.progress` property

#### Configuration Options
Future configurability could include:
- Custom MIDI note mappings (via config file or UI)
- Dynamic sample loading (file picker)
- Sample volume/pan controls
- Multi-output routing
- Recording functionality
- Sample effects chain

### Code Style

- **Objective-C Modern Syntax**: Use modern Objective-C features (properties, literals, blocks)
- **Manual Memory Management**: Use ARC (Automatic Reference Counting)
- **Nullability Annotations**: Use `NS_ASSUME_NONNULL_BEGIN/END` and explicit `nullable` where needed
- **Error Handling**: Use `NSError **` pattern for operations that can fail
- **Thread Safety**: Consider main thread for UI updates, real-time thread for audio

### File Organization

```
SampleLauncher/
├── SampleLauncher.xcodeproj/     # Xcode project
├── SampleLauncher/               # Main application code
│   ├── Model/
│   │   ├── SampleSlot.h/.m       # Audio sample playback
│   │   └── SampleBank.h/.m       # Collection of sample slots
│   ├── MIDI/
│   │   └── MIDIInput.h/.m        # MIDI source enumeration and selection
│   ├── Views/
│   │   ├── SampleSlotView.h/.m   # Individual slot UI component
│   │   └── SampleBankView.h/.m   # 4x4 grid of slots
│   ├── AppDelegate.h/.m          # App lifecycle, audio engine, sample loading
│   ├── ViewController.h/.m       # Main view controller
│   ├── main.m                    # Application entry point
│   ├── Assets.xcassets/          # App icons, images
│   └── Base.lproj/
│       └── Main.storyboard       # UI layout
├── SampleLauncherTests/          # Unit tests
│   ├── Model/
│   │   ├── SampleSlotTests.m     # SampleSlot test suite
│   │   └── SampleBankTests.m     # SampleBank test suite
│   ├── MIDI/
│   │   └── MIDIInputTests.m      # MIDIInput test suite
│   ├── TestAudioEngineHelper.h/.m # Test audio engine utility
│   └── SampleLauncherTests.m     # Test bundle setup
├── SampleLauncherUITests/        # UI tests
├── StockSamples/                 # Audio sample library
│   └── *.aif                     # 16 samples (8-bar loops, 128 BPM)
├── CLAUDE.md                     # This file - project documentation
├── README.md                     # Project overview and design notes
└── spec.pdf                      # Project specification
```

## Building and Running

### Requirements
- macOS 10.15 or later
- Xcode 12.0 or later
- USB MIDI device (for MIDI functionality, when implemented)

### Build Instructions

1. Open `SampleLauncher.xcodeproj` in Xcode
2. Select the SampleLauncher scheme
3. Build and run (Cmd+R)

### Testing

Run unit tests:
- Product → Test (Cmd+U)
- Or use `xcodebuild test` from command line

## Future Enhancements

### High Priority (Core Functionality)
- **Complete MIDI Integration**:
  - MIDI client and port setup with callbacks
  - Note-on/note-off message parsing
  - Connect MIDI events to sample playback
- **UI Integration**:
  - Wire ViewController to SampleBank model
  - Real-time playback state updates
  - Progress meter animation
  - Click handlers for manual triggering
- **Phrase Synchronization**:
  - Global timeline tracking (128 BPM, 8-bar phrases)
  - Schedule playback at phrase boundaries
  - Synchronized start/stop of all loops

### Medium Priority (Enhanced Features)
- **MIDI Device Management**:
  - Device selection UI
  - Hot-plug detection and notification
  - Automatic reconnection
- **Sample Management**:
  - Load custom samples at runtime
  - Drag-and-drop sample loading
  - Sample library browser
- **Playback Control**:
  - Master start/stop for all playing samples
  - Solo and mute per slot
  - Volume and pan controls per slot
- **Visual Enhancements**:
  - Waveform display in slots
  - VU meters for output levels
  - Color-coding for sample types

### Low Priority (Advanced Features)
- **MIDI Mapping UI**: Configure custom note assignments
- **Performance Metrics**: Display CPU/memory usage
- **Preferences**: Save/load configuration and mappings
- **Recording**: Capture mixed output to file
- **Effects**: Add audio effects per sample or globally
- **Multi-bank**: Organize samples into multiple banks with switching
- **Keyboard Shortcuts**: Trigger samples via computer keyboard
- **BPM Detection**: Analyze and adapt to different tempo samples
- **Time-Stretching**: Support samples at different tempos

## Known Limitations

### Current Design Constraints
- **Sample Format**: Fixed to 8-bar loops at 128 BPM (stock samples only)
- **Memory Loading**: Samples loaded entirely into memory (no streaming)
- **Sample Rate**: Expected 48kHz .aif files (no automatic conversion)
- **Fixed Capacity**: 16 sample slots (matching MIDI note range C1-D#2)
- **Static Loading**: Samples loaded on app launch (no dynamic user loading yet)

### Technical Limitations
- **No Phrase Sync Yet**: Samples play immediately without phrase-boundary alignment
- **No UI Feedback**: Playback state not yet reflected in UI
- **MIDI Read-Only**: Can enumerate MIDI sources but not receive messages yet
- **No Click Interaction**: UI displays slots but doesn't respond to clicks
- **Fixed Buffer Size**: Tests use 4096 frame buffer

### By Design (Not Bugs)
- **Loop-Based Workflow**: Designed for loops, not one-shot samples (like Ableton clips)
- **Fixed Sample Length**: Avoids complexity of BPM detection and time-stretching
- **Toggle Behavior**: MIDI notes toggle playback rather than triggering one-shots
- **No Sample Conversion**: Expects pre-formatted samples at correct tempo/sample rate

## Technical Notes

### AVAudioPlayerNode Behavior
- **Scheduling**: Samples are scheduled in the buffer and played when `play()` is called
- **Retriggering**: Calling `play()` again stops current playback and restarts
- **Completion**: `scheduleBuffer:completionHandler:` can notify when sample finishes
- **Looping**: Not implemented, but could be added with completion handlers
- **Engine Attachment**: All 16 player nodes attached to mixer on app launch
- **Connection Format**: Uses `nil` format in `connect:to:format:` to use source node's format

### Sample Rate Handling
- Stock samples are 48kHz stereo
- Tests use 48kHz render format
- Production app should handle sample rate conversion if needed
- All stock samples have identical format for consistent playback

### Thread Considerations
- **Audio Thread**: AVAudioEngine runs audio processing on real-time thread
- **Main Thread**: UI updates and most API calls should be on main thread
- **MIDI Thread**: CoreMIDI callbacks occur on dedicated MIDI thread
  - Must dispatch to main thread before updating UI
  - Can call SampleSlot methods directly (thread-safe for audio)

### Notification System
- **SamplesDidLoad**: Posted by AppDelegate when stock samples finish loading
  - Object: SampleBank instance
  - Use to trigger initial UI update in ViewController

### UI Update Strategy
For real-time playback feedback:
- **Option 1**: CADisplayLink (60 Hz, synchronized with display refresh)
- **Option 2**: NSTimer with ~30ms interval (adequate for progress meters)
- **Option 3**: Audio tap on mixer node (most accurate but higher overhead)

### SampleBank Design
- Pre-allocates all slots at initialization
- `count` property calculated on demand (iterates slots)
- Could cache `count` and update on load/unload for better performance
- `attachToAudioEngine:` attaches and connects all nodes in one operation

### MIDIInput Architecture
- Stateless enumeration (calls `MIDIGetNumberOfSources()` each time)
- Could cache source list and update on MIDI device notifications
- Selected source stored as `MIDIEndpointRef` (handle, not name)
- Future: Add `MIDIClientRef` and `MIDIPortRef` as instance variables

## Resources

- [AVFoundation Documentation](https://developer.apple.com/av-foundation/)
- [CoreMIDI Programming Guide](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/CoreMIDIOverview/)
- [AVAudioEngine Tutorial](https://developer.apple.com/documentation/avfoundation/audio_playback_recording_and_processing/avaudioengine)
