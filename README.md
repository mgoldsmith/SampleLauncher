## TODO

- Check all these `[super x]` calls.

## App design

My initial idea was to implement something similar to Native Instruments's Battery, or Ableton's Drum Rack. However, the spec designates that MIDI assignments should `Start/Stop Samples`. Toggling playstates didn't make sense to me for a "sampler" instrument that plays one-shots, so I decided to make the application work with loops and act more like Ableton's clip view.

After looking through some samples at add as stock samples, it quickly dawned on me that triggering clips won't lead to any decent-sounding results without playback sync. Implementing dynamic BPM and sample stretching felt way out of scope for the project, so I went with fixed length samples to avoid the need for timestretching. I picked an 8 bar section from one of my original tracks and bounced the 15 stems that were playing. To implement phrase syncing, I `INSERT PHRASE SYNCING STRATEGY HERE`.

## Limitations and assumptions

- The app loads the stock samples and connects its slots to the audio engine on startup. Dynamic loading of user samples isn't supported (from the spec: `Audio content may be fixed`).
- As mentioned in the `App Design` section, only stock samples that are exactly 8 bars at 128 BPM are supported to maintain tempo and bar-level phrase sync.