# Hawaian

**AI-powered multilingual conversation companion for iPhone.**

Hawaian is an earbud-first conversation assistant. It listens to a conversation, translates incoming speech, understands the user's selected conversation intent, proposes context-aware reply structures, fills required variables, and prepares a translated spoken response.

## Product principles

- Earbud-first, discreet interaction; no loudspeaker-first workflow.
- Conversation Intent describes *why* the conversation is happening.
- Context Memory keeps temporary facts and conversation state.
- Smart Reply proposes response patterns, not just literal translations.
- Variable Fill asks only for information that is genuinely missing.
- Multilingual architecture: language support is capability-driven, not hard-coded to Japanese and English.
- Siri / Apple Intelligence integration through public Apple APIs such as App Intents where available.

## Important platform boundary

Third-party apps cannot directly invoke or control Siri's private internal model, nor can they assume access to Siri's internal visualizer. Hawaian therefore provides its own Siri-inspired, animated voice visualizer and an AI-provider abstraction. Apple Intelligence and Siri integrations are added only through documented public APIs and on-device capabilities available to the device, OS version, region, and language. The app must never present a local placeholder as a live Siri response.

## Current project status

The first milestone establishes the native SwiftUI app shell, Liquid Glass-inspired interface, conversation intent selection, a custom animated voice visualizer, and GitHub Actions build/test automation. Live transcription, translation, Siri/App Intents integration, and spoken reply delivery are staged as separate, testable capabilities.

## Build

The Xcode project is generated from `project.yml` with XcodeGen:

```sh
brew install xcodegen
xcodegen generate
xcodebuild -project Hawaian.xcodeproj -scheme Hawaian -destination 'platform=iOS Simulator,name=iPhone 16e' build
```

## CI

GitHub Actions runs project generation, simulator build, and unit tests on macOS. The workflow does not sign or distribute an IPA; signing and device installation require separate provisioning configuration.
