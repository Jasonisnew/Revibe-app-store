//
//  SettingsView.swift
//  Revibe
//

import SwiftUI
import AVFoundation

struct SettingsView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var goal = ""
    @State private var daysPerWeek = ""
    @State private var sessionLength = ""
    @State private var equipment = ""
    @State private var injuryArea = ""
    @State private var injuryNote = ""

    @State private var saveError: String?
    @State private var isSaving = false

    // MARK: - Audio & Feedback settings (UserDefaults backed via AppStorage)
    @AppStorage("audioCoach.voiceEnabled")    private var voiceEnabled: Bool = true
    @AppStorage("audioCoach.sfxEnabled")      private var sfxEnabled: Bool = false
    @AppStorage("audioCoach.backgroundMusic") private var backgroundMusic: Bool = false
    @AppStorage("audioCoach.motivationMode")  private var motivationModeRaw: String = MotivationMode.coach.rawValue

    private var motivationMode: MotivationMode {
        MotivationMode(rawValue: motivationModeRaw) ?? .coach
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    Text("These match the answers from your first-time setup. Change anything below and tap Save.")
                        .font(.subheadline)
                        .foregroundColor(DS.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)

                    sectionTitle("Account")
                    settingsField(title: "Display name") {
                        TextField("Your name", text: $displayName)
                            .textContentType(.name)
                            .foregroundColor(DS.Colors.textPrimary)
                            .padding(12)
                            .background(DS.Colors.bgSecondary)
                            .cornerRadius(DS.Radius.input)
                            .overlay(
                                RoundedRectangle(cornerRadius: DS.Radius.input)
                                    .stroke(DS.Colors.border, lineWidth: 1)
                            )
                    }

                    sectionTitle("Training preferences")
                    Text("Same questions as when you joined Revibe")
                        .font(.caption)
                        .foregroundColor(DS.Colors.textMuted)
                        .padding(.bottom, 4)

                    pickerField(
                        title: "What do you want most right now?",
                        selection: $goal,
                        options: OnboardingOptions.goals
                    )
                    pickerField(
                        title: "How many days per week can you commit to?",
                        selection: $daysPerWeek,
                        options: OnboardingOptions.daysPerWeek
                    )
                    pickerField(
                        title: "How long should most workouts be?",
                        selection: $sessionLength,
                        options: OnboardingOptions.sessionLengths
                    )
                    pickerField(
                        title: "Where will you usually work out?",
                        selection: $equipment,
                        options: OnboardingOptions.equipment
                    )
                    pickerField(
                        title: "Any body areas you want us to be careful with?",
                        selection: $injuryArea,
                        options: OnboardingOptions.injuryAreas
                    )

                    if injuryArea == "Other" {
                        settingsField(title: "Tell us briefly") {
                            TextField("Describe briefly", text: $injuryNote)
                                .foregroundColor(DS.Colors.textPrimary)
                                .padding(12)
                                .background(DS.Colors.bgSecondary)
                                .cornerRadius(DS.Radius.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DS.Radius.input)
                                        .stroke(DS.Colors.border, lineWidth: 1)
                                )
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    // MARK: Audio & Feedback
                    sectionTitle("Audio & Feedback")

                    audioToggleRow(
                        icon: "waveform",
                        title: "Voice Encouragement",
                        subtitle: "Hear coaching phrases during your workout",
                        isOn: $voiceEnabled
                    )

                    audioToggleRow(
                        icon: "music.quarternote.3",
                        title: "Background Music Support",
                        subtitle: "Allow music to play while working out",
                        isOn: $backgroundMusic
                    )

                    audioToggleRow(
                        icon: "bell.badge",
                        title: "Sound Effects",
                        subtitle: "Rep ticks and set completion chimes",
                        isOn: $sfxEnabled
                    )

                    if voiceEnabled {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Motivation Style")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(DS.Colors.textSecondary)

                            HStack(spacing: 8) {
                                ForEach(MotivationMode.allCases, id: \.self) { mode in
                                    Button {
                                        motivationModeRaw = mode.rawValue
                                    } label: {
                                        VStack(spacing: 5) {
                                            Image(systemName: mode.iconName)
                                                .font(.system(size: 18))
                                                .foregroundColor(motivationModeRaw == mode.rawValue ? DS.Colors.textOnAccent : DS.Colors.textMuted)
                                            Text(mode.rawValue)
                                                .font(.system(size: 11, weight: .semibold))
                                                .foregroundColor(motivationModeRaw == mode.rawValue ? DS.Colors.textOnAccent : DS.Colors.textMuted)
                                            Text(mode.description)
                                                .font(.system(size: 10))
                                                .foregroundColor(motivationModeRaw == mode.rawValue ? DS.Colors.textOnAccent.opacity(0.7) : DS.Colors.textMuted.opacity(0.7))
                                                .multilineTextAlignment(.center)
                                                .lineLimit(2)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: DS.Radius.button)
                                                .fill(motivationModeRaw == mode.rawValue ? DS.Colors.accent : DS.Colors.bgSecondary)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DS.Radius.button)
                                                .stroke(motivationModeRaw == mode.rawValue ? Color.clear : DS.Colors.border, lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    if let saveError {
                        Text(saveError)
                            .font(.footnote)
                            .foregroundColor(DS.Colors.error)
                            .padding(.top, 4)
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(DS.Colors.textOnAccent)
                            }
                            Text(isSaving ? "Saving…" : "Save changes")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundColor(DS.Colors.textOnAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isSaving ? DS.Colors.textMuted : DS.Colors.accent)
                        .cornerRadius(DS.Radius.button)
                    }
                    .disabled(isSaving)
                    .padding(.top, DS.Spacing.sm)
                }
                .padding(DS.Spacing.md)
                .padding(.bottom, DS.Spacing.xl)
            }
            .background(DS.Colors.bgPrimary.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .onChange(of: injuryArea) { _, newValue in
                if newValue != "Other" { injuryNote = "" }
            }
            .task {
                await viewModel.loadProfile()
                syncFromViewModel()
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(DS.Colors.textMuted)
            .textCase(.uppercase)
            .tracking(0.5)
    }

    private func settingsField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(DS.Colors.textSecondary)
            content()
        }
    }

    private func pickerField(title: String, selection: Binding<String>, options: [String]) -> some View {
        settingsField(title: title) {
            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) { selection.wrappedValue = option }
                }
            } label: {
                HStack(alignment: .top, spacing: 8) {
                    Text(selection.wrappedValue.isEmpty ? "Select" : selection.wrappedValue)
                        .foregroundColor(selection.wrappedValue.isEmpty ? DS.Colors.textMuted : DS.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(DS.Colors.textMuted)
                }
                .padding(12)
                .background(DS.Colors.bgSecondary)
                .cornerRadius(DS.Radius.input)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.input)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )
            }
        }
    }

    private func audioToggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DS.Colors.bgTertiary)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundColor(isOn.wrappedValue ? DS.Colors.accent : DS.Colors.textMuted)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(DS.Colors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(DS.Colors.textMuted)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DS.Colors.accent)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )
        )
    }

    private func syncFromViewModel() {
        displayName = viewModel.displayName
        goal = OnboardingOptions.resolveGoal(viewModel.goal)
        daysPerWeek = OnboardingOptions.resolveDaysPerWeek(viewModel.daysPerWeek)
        sessionLength = OnboardingOptions.resolveSessionLength(viewModel.sessionLength)
        equipment = OnboardingOptions.resolveEquipment(viewModel.equipment)
        injuryArea = OnboardingOptions.resolveInjuryArea(viewModel.injuryArea)
        injuryNote = viewModel.injuryNote
    }

    private func save() async {
        saveError = nil
        guard !goal.isEmpty, !daysPerWeek.isEmpty, !sessionLength.isEmpty, !equipment.isEmpty, !injuryArea.isEmpty else {
            saveError = "Please choose all training preferences."
            return
        }
        isSaving = true
        let err = await viewModel.saveSettings(
            displayName: displayName,
            goal: goal,
            daysPerWeek: daysPerWeek,
            sessionLength: sessionLength,
            equipment: equipment,
            injuryArea: injuryArea,
            injuryNote: injuryNote
        )
        isSaving = false
        if let err {
            saveError = err
        } else {
            dismiss()
        }
    }
}

#Preview {
    SettingsView(viewModel: ProfileViewModel())
}
