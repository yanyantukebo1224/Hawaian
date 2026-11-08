# Hawaian

**Earbud-first, multilingual live conversation translator for iPhone.**

Hawaian captures nearby speech, transcribes it, translates it into the selected language, and helps the user prepare a translated spoken reply.

## Integrated systems

- **Live Audio Engine:** AVAudioEngine captures microphone audio after explicit permission.
- **Live Translation:** Apple Speech provides partial transcription; Apple Translation translates detected speech into the selected language.
- **Language Engine:** input and output languages are discovered at runtime from Speech and Translation framework availability. The preferred iOS language is excluded from input candidates by default. Auto mode runs up to eight language recognizers concurrently to limit battery and latency; a manual source-language picker is also available.
- **Smart Reply:** conversation intent and recent translated turns shape reply structures. Required variables can be filled by the user; the chosen reply is translated back into the detected speaker language and spoken.
- **AirPods / audio routing:** AVAudioSession uses Bluetooth input/output routing and AVSpeechSynthesizer speaks through the active iOS route. Route changes and audio interruptions are handled.
- **Siri AI:** App Intents and App Shortcuts expose start listening, stop listening, and latest translation actions to Siri, Shortcuts, and Apple Intelligence/Siri AI.

## Siri AI integration

Hawaian uses Apple's public App Intents integration so Siri AI can discover and execute app actions. This is the supported integration model; the app does not embed or directly call Siri's private model. Apple's Siri AI developer preview begins with iOS 27.3. Availability depends on compatible hardware, Apple Intelligence settings, supported Siri/device language, and region.

## Recognition and privacy notes

- The app requests microphone and speech-recognition permissions only when the user starts a session.
- Apple Translation processes translation text on device. Some Speech locales require a network connection and may use Apple's speech-recognition service.
- Auto recognition compares up to eight supported locale recognizers. It is a practical candidate-selection strategy, not a guarantee of perfect language identification in noisy or overlapping conversations. Manual source-language selection is available.
- Audio is not intentionally recorded or saved by Hawaian. Recent translated context is held only in memory for the active session and cleared when the session stops.
- Audio continues through the system route, including supported Bluetooth earbuds. Background audio mode is enabled to support an active listening session while the screen is locked.

## Build and test

The project is generated from `project.yml` with XcodeGen and requires Xcode 27 / iOS 27.2 SDK.

Install XcodeGen, run `xcodegen generate`, then build and test the `Hawaian` scheme for an iOS 27 simulator with code signing disabled.

GitHub Actions runs project generation, simulator build, and unit tests. GitHub Actions creates an unsigned device IPA as a downloadable artifact. It is not installable as-is; sign it with a sideloading tool and a valid provisioning profile before installing.