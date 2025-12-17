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

#### AppDelegate (`SampleLauncher/AppDelegate.h/.m`)
Standard macOS application delegate. Currently minimal, ready for future audio engine and MIDI manager initialization.

#### ViewController (`SampleLauncher/ViewController.h/.m`)
Main UI controller. Currently placeholder, will manage:
- Sample slot UI representation
- Audio engine lifecycle
- MIDI manager integration
- Sample state visualization

### Stock Audio Samples

Located in `StockSamples/`, includes 16 high-quality audio samples:
- Kick, Snare, Shaker
- Cymbals, Hi-hats
- Synth loops
- Drum loops
- Bass sounds
- Total: ~21MB of audio content (48kHz, stereo .aif files)

All samples are the same length (2,880,054 bytes each), making them ideal for synchronized playback.

## Testing

### Unit Tests (`SampleLauncherTests/Model/SampleSlotTests.m`)

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
- [x] Unit tests with manual rendering mode
- [x] Stock sample library

**Not Yet Implemented:**
- [ ] MIDI input handling (CoreMIDI integration)
- [ ] Audio engine setup and routing
- [ ] UI for sample grid
- [ ] Visual feedback for sample playback state
- [ ] MIDI device connection/disconnection handling
- [ ] Sample slot assignment to MIDI notes

### Extending the Application

The architecture is designed for easy extension:

#### Adding MIDI Support
1. Create a `MIDIManager` class to handle CoreMIDI setup
2. Set up MIDI client and input port
3. Parse MIDI note-on/note-off messages
4. Map MIDI notes to sample slot indices
5. Call appropriate `SampleSlot` methods

#### Implementing the UI
1. Design grid layout in `Main.storyboard`
2. Create custom view/cell for each sample slot
3. Bind `SampleSlot.isPlaying` to visual state (color, animation)
4. Display `sampleName` in UI
5. Add click handlers for manual triggering

#### Audio Engine Setup
1. Initialize `AVAudioEngine` in `AppDelegate` or `ViewController`
2. Create array of `SampleSlot` instances
3. Attach all `playerNode`s to the engine
4. Connect nodes to `mainMixerNode`
5. Start the engine
6. Handle audio interruptions

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
│   │   ├── SampleSlot.h
│   │   └── SampleSlot.m
│   ├── AppDelegate.h
│   ├── AppDelegate.m
│   ├── ViewController.h
│   ├── ViewController.m
│   ├── main.m
│   ├── Assets.xcassets/          # App icons, images
│   └── Base.lproj/
│       └── Main.storyboard       # UI layout
├── SampleLauncherTests/          # Unit tests
│   └── Model/
│       └── SampleSlotTests.m
├── SampleLauncherUITests/        # UI tests
├── StockSamples/                 # Audio sample library
│   └── *.aif                     # 16 samples
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

### High Priority
- **MIDI Integration**: CoreMIDI setup for USB device support
- **UI Implementation**: Visual grid showing all samples
- **Audio Engine**: Global engine managing all sample slots
- **State Feedback**: Visual indicators for playing/stopped state

### Medium Priority
- **Sample Management**: Load custom samples at runtime
- **MIDI Mapping UI**: Configure note assignments
- **Performance Metrics**: Display CPU/memory usage
- **Preferences**: Save/load configuration

### Low Priority
- **Recording**: Capture mixed output
- **Effects**: Add audio effects per sample
- **Multi-bank**: Organize samples into banks
- **Keyboard Shortcuts**: Trigger samples via keyboard

## Known Limitations

- Samples must be loaded into memory (not streaming)
- Single audio format expected (48kHz .aif files work well)
- No automatic sample rate conversion
- Fixed buffer size in tests (4096 frames)

## Technical Notes

### AVAudioPlayerNode Behavior
- **Scheduling**: Samples are scheduled in the buffer and played when `play()` is called
- **Retriggering**: Calling `play()` again stops current playback and restarts
- **Completion**: `scheduleBuffer:completionHandler:` can notify when sample finishes
- **Looping**: Not implemented, but could be added with completion handlers

### Sample Rate Handling
- Stock samples are 48kHz
- Tests use 48kHz render format
- Production app should handle sample rate conversion if needed

### Thread Considerations
- **Audio Thread**: AVAudioEngine runs audio processing on real-time thread
- **Main Thread**: UI updates and most API calls should be on main thread
- **MIDI Thread**: CoreMIDI callbacks occur on dedicated MIDI thread

## Resources

- [AVFoundation Documentation](https://developer.apple.com/av-foundation/)
- [CoreMIDI Programming Guide](https://developer.apple.com/library/archive/documentation/MusicAudio/Conceptual/CoreMIDIOverview/)
- [AVAudioEngine Tutorial](https://developer.apple.com/documentation/avfoundation/audio_playback_recording_and_processing/avaudioengine)
