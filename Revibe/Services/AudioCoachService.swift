//
//  AudioCoachService.swift
//  Revibe
//

import Foundation
import AVFoundation
import Combine

// MARK: - Motivation Mode

enum MotivationMode: String, CaseIterable, Codable {
    case calm       = "Calm"
    case energetic  = "Energetic"
    case coach      = "Coach"

    var iconName: String {
        switch self {
        case .calm:      return "waveform.path"
        case .energetic: return "bolt.fill"
        case .coach:     return "figure.stand.line.dotted.figure.stand"
        }
    }

    var description: String {
        switch self {
        case .calm:      return "Quiet support"
        case .energetic: return "High-energy hype"
        case .coach:     return "Form-focused guidance"
        }
    }
}

// MARK: - Phrase Category

private enum PhraseCategory {
    case formGood, halfwayThere, lastFewReps, setCompleted, sessionStart
}

// MARK: - Audio Coach Service

/// Provides optional voice encouragement and sound feedback during workouts.
/// All preferences are persisted in UserDefaults and can be toggled in Settings.
final class AudioCoachService: ObservableObject {

    // MARK: - UserDefaults keys

    private enum Keys {
        static let voiceEnabled      = "audioCoach.voiceEnabled"
        static let sfxEnabled        = "audioCoach.sfxEnabled"
        static let backgroundMusic   = "audioCoach.backgroundMusic"
        static let motivationMode    = "audioCoach.motivationMode"
    }

    // MARK: - Published settings

    @Published var isVoiceEnabled: Bool {
        didSet { UserDefaults.standard.set(isVoiceEnabled, forKey: Keys.voiceEnabled) }
    }
    @Published var areSFXEnabled: Bool {
        didSet { UserDefaults.standard.set(areSFXEnabled, forKey: Keys.sfxEnabled) }
    }
    @Published var allowBackgroundMusic: Bool {
        didSet {
            UserDefaults.standard.set(allowBackgroundMusic, forKey: Keys.backgroundMusic)
            configureAudioSession()
        }
    }
    @Published var motivationMode: MotivationMode {
        didSet { UserDefaults.standard.set(motivationMode.rawValue, forKey: Keys.motivationMode) }
    }

    // MARK: - Private

    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpeakTime: Date = .distantPast
    private let minSpeakInterval: TimeInterval = 8.0
    private var hasSpokenHalfway = false
    private var hasSpokenLastFew = false

    // MARK: - Phrase banks

    private let calmPhrases: [PhraseCategory: [String]] = [
        .sessionStart: ["Let's go. Take it steady."],
        .formGood:     ["Nice form", "Good control", "Stay smooth", "Well done"],
        .halfwayThere: ["Halfway there", "Keep breathing", "You're doing well"],
        .lastFewReps:  ["Almost done", "Last few", "Finish steady"],
        .setCompleted: ["Good set", "Take your rest", "Well done — rest up"]
    ]

    private let energeticPhrases: [PhraseCategory: [String]] = [
        .sessionStart: ["Let's go — let's get it!"],
        .formGood:     ["Let's go!", "That's it!", "Yes!", "Crushing it!"],
        .halfwayThere: ["Halfway — keep pushing!", "Don't stop now!", "You've got this!"],
        .lastFewReps:  ["Last few — finish strong!", "Push it!", "Come on, dig in!"],
        .setCompleted: ["Great set!", "Smashed it!", "Rest up and go again!"]
    ]

    private let coachPhrases: [PhraseCategory: [String]] = [
        .sessionStart: ["Alright — let's focus on quality reps."],
        .formGood:     ["Good form, keep it controlled", "Nice — stay tight", "That's the movement"],
        .halfwayThere: ["Halfway — quality over speed", "Stay focused on form", "Keep the tension"],
        .lastFewReps:  ["Last few — make them count", "Finish strong, stay controlled", "These are the ones that matter"],
        .setCompleted: ["Good set — use your rest", "Note your form for next time", "Solid work"]
    ]

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.isVoiceEnabled      = defaults.object(forKey: Keys.voiceEnabled) as? Bool ?? true
        self.areSFXEnabled       = defaults.object(forKey: Keys.sfxEnabled)   as? Bool ?? false
        self.allowBackgroundMusic = defaults.object(forKey: Keys.backgroundMusic) as? Bool ?? false
        let modeRaw = defaults.string(forKey: Keys.motivationMode) ?? MotivationMode.coach.rawValue
        self.motivationMode = MotivationMode(rawValue: modeRaw) ?? .coach
        configureAudioSession()
    }

    // MARK: - Public API

    func speakOnSessionStart() {
        guard isVoiceEnabled else { return }
        guard let phrase = pick(.sessionStart) else { return }
        speak(phrase)
    }

    func speakOnRepCompleted(repNumber: Int, totalReps: Int) {
        guard isVoiceEnabled else { return }

        // Halfway cue — fires once per set
        if repNumber == totalReps / 2 && !hasSpokenHalfway {
            hasSpokenHalfway = true
            if let phrase = pick(.halfwayThere) { speak(phrase); return }
        }

        // Last 2 reps cue — fires once per set
        if repNumber >= totalReps - 2 && !hasSpokenLastFew {
            hasSpokenLastFew = true
            if let phrase = pick(.lastFewReps) { speak(phrase); return }
        }

        // Periodic form-good encouragement (throttled)
        let now = Date()
        guard now.timeIntervalSince(lastSpeakTime) >= minSpeakInterval else { return }
        if let phrase = pick(.formGood) { speak(phrase) }
    }

    func speakOnSetCompleted() {
        guard isVoiceEnabled else { return }
        if let phrase = pick(.setCompleted) { speak(phrase) }
        resetSetState()
    }

    /// Speaks a danger warning immediately, bypassing all throttles and toggles
    func speakDangerWarning(_ message: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: message)
        utterance.rate = 0.45
        utterance.pitchMultiplier = 0.95
        utterance.volume = 1.0
        synthesizer.speak(utterance)
    }

    func resetSetState() {
        hasSpokenHalfway = false
        hasSpokenLastFew = false
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Private

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = motivationMode == .energetic ? 0.54 : 0.48
        utterance.pitchMultiplier = motivationMode == .energetic ? 1.08 : 1.0
        utterance.volume = 0.9
        lastSpeakTime = Date()
        synthesizer.speak(utterance)
    }

    private func pick(_ category: PhraseCategory) -> String? {
        let bank: [PhraseCategory: [String]]
        switch motivationMode {
        case .calm:      bank = calmPhrases
        case .energetic: bank = energeticPhrases
        case .coach:     bank = coachPhrases
        }
        guard let phrases = bank[category], !phrases.isEmpty else { return nil }
        return phrases[Int.random(in: 0..<phrases.count)]
    }

    private func configureAudioSession() {
        // Use `.playback` so workout music + TTS coaching play at full volume
        // even with the silent switch on. `.mixWithOthers` keeps the user's
        // own background music (Spotify, Apple Music, etc.) playing alongside.
        // `.duckOthers` is added when the user opts into background music so
        // their music dips slightly while the coach speaks.
        let options: AVAudioSession.CategoryOptions = allowBackgroundMusic
            ? [.mixWithOthers, .duckOthers]
            : [.mixWithOthers]
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: options)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
}
