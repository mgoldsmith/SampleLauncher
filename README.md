# SampleLauncher

Simple macOS app that acts similarly to Ableton's Clip view, launching a static set of loops based on MIDI input and clicks on the UI. Loops play in sync with each other at the resolution of one bar.

## System Requirements

`macOS` and `Xcode`. I tested with `macOS v15.6.1` and `Xcode v26.1.1`.

## Building, Running, and Testing

Open the XCode project, set your development team in the project settings, and run the `Run` or `Test` action.

## Usage

### MIDI Setup

Once you have at least one MIDI controller plugged in, make sure it's selected in the dropdown list at the top of the app.

### Controls

**MIDI Note Mapping:**
- C2 (note 48) → Sample slot 1
- C#2 (note 49) → Sample slot 2
- ...
- D#3 (note 63) → Sample slot 16

MIDI notes queue their respective loops to start playing from the beginning of the loop at the start of the next bar. MIDI notes on already-playing loops will immediately pause the loop.

**Mouse Controls:**

Click sample slots to achieve the same effect as triggering them via MIDI.

## App Design

My initial idea was to implement something similar to Native Instruments's Battery, or Ableton's Drum Rack. However, the spec designates that MIDI assignments should `Start/Stop Samples`. Toggling playstates didn't make sense to me for a "sampler" instrument that plays one-shots, so I decided to make the application work with loops and act more like Ableton's clip view.

After looking through some samples to add as stock samples, it quickly dawned on me that triggering clips won't lead to any decent-sounding results without playback sync. Implementing dynamic BPM and sample stretching felt way out of scope for the project, so I went with fixed length samples to avoid the need for timestretching. I picked an 8 bar section from one of my original tracks and bounced the 15 stems that were playing.

`TransportClock` acts similarly to Ableton's metronome, providing a source of truth for the individual sample slots and where we are in the bar. This means that even when no samples are playing, the first sample that starts will wait for the `TransportClock`'s timing. Ideally, if nothing's playing, the first loop would trigger immediately. However, the sync aspect of this already felt like a lot of extra scope, so I left it as-is.

## Architecture

### Model

The heart of the app is a `SampleBank` that houses a number of `SampleSlot`s. The `SampleSlot`s are responsible for holding stock samples and scheduling their audio into the slot's `AVAudioPlayerNode`. A `SampleSlot` also reports its play state, play progress, and sample name to the `SampleSlotView`. The `SampleBank` mainly exists to conveniently encapsulate its `SampleSlot`s.

### MIDI

MIDI handling is split into two classes: `MIDIController` and `MIDIInput`. `MIDIController` is minimal, and mainly responsible for connecting `MIDIInput` and `SampleBank` so that MIDI events can play and stop samples.

`MIDIInput` does the bulk of MIDI handling. It's responsible for listening to a specific MIDI source and sending the source's MIDI events to `MIDIController`. MIDI events are written to a lock-free ringbuffer to stay realtime-safe. The ringbuffer is then consumed by a separate thread, which handles MIDI events and ultimately schedules `SampleSlot` audio buffers into the `AVAudioEngine`.

## Limitations and Assumptions

- The app loads the stock samples and connects its slots to the audio engine on startup. Dynamic loading of user samples isn't supported (from the spec: `Audio content may be fixed`).
- As mentioned in the `App Design` section, only stock samples that are exactly 8 bars at 128 BPM are supported to maintain tempo and bar-level phrase sync.
- There are a few magic numbers baked into various places. For example, multiple places use the hard-coded `48khz` that I assume for the stock samples. I would normally replace these spots with constant definitions, but I ran out of time given the already-large scope and the time of year (December 23rd at the time of writing).

## General strategy and use of AI

I find AI to be especially useful for generating boilerplate code and tests. I began by designing the large-scale architecture such as the `SampleBank`, `SampleSlot` class responsibilities. Once I had an idea of how I would approach the application, I used Claude Code to generate the new classes one by one, closely reviewing each line and correcting mistakes I saw.

Using Claude allowed me to work much faster and fit everything I wanted into the app within the week I spent on it.

## Closing thoughts

I had a lot of fun working on this project. I'm sure there are more improvements I could make, but I'm calling it done today (Dec. 23rd) so that I can concentrate on spending time with my family. I hope you like it and I'm looking forward to your feedback!
