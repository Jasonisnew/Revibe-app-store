//
//  OnboardingView.swift
//  Revibe
//

import SwiftUI
import Supabase

struct OnboardingView: View {
    var onComplete: () -> Void

    @State private var currentPage = 0
    @State private var goal = ""
    @State private var daysPerWeek = ""
    @State private var sessionLength = ""
    @State private var equipment = ""
    @State private var injuryArea = ""
    @State private var injuryNote = ""
    @State private var showInjuryInput = false
    @State private var isSubmitting = false
    @State private var generationProgress: Double = 0
    @State private var generationTimer: Timer?

    private let totalPages = 6

    private var isFormComplete: Bool {
        !goal.isEmpty && !daysPerWeek.isEmpty && !sessionLength.isEmpty
            && !equipment.isEmpty && !injuryArea.isEmpty
    }

    private var canAdvance: Bool {
        switch currentPage {
        case 0: return true
        case 1: return !goal.isEmpty
        case 2: return !daysPerWeek.isEmpty
        case 3: return !sessionLength.isEmpty
        case 4: return !equipment.isEmpty
        case 5: return !injuryArea.isEmpty
        default: return false
        }
    }

    /// Step labels for the question pages (pages 1–5)
    private var stepLabel: String {
        switch currentPage {
        case 1: return "Your Goals"
        case 2: return "Your Schedule"
        case 3: return "Your Sessions"
        case 4: return "Your Setup"
        case 5: return "Your Safety"
        default: return ""
        }
    }

    /// Number of question pages (excludes the intro page)
    private let questionCount = 5

    var body: some View {
        ZStack {
            DS.Colors.bgPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: DS.Spacing.lg) {
                    if currentPage > 0 {
                        progressBar
                            .padding(.horizontal, DS.Spacing.md)
                    }

                    questionContent
                        .padding(.horizontal, currentPage == 0 ? DS.Spacing.md : 56)
                }

                Spacer()

                bottomArea
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, DS.Spacing.md)
            }

            navigationArrows
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 6) {
            HStack {
                Text("Question \(currentPage) of \(questionCount)")
                    .font(.caption)
                    .foregroundColor(DS.Colors.textMuted)
                Spacer()
                Text(stepLabel)
                    .font(.caption.weight(.medium))
                    .foregroundColor(DS.Colors.accent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Colors.border)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(DS.Gradients.progress)
                        .frame(width: geo.size.width * CGFloat(currentPage) / CGFloat(questionCount), height: 6)
                        .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Question Content (centered)

    @ViewBuilder
    private var questionContent: some View {
        switch currentPage {
        case 0:
            introPage
        case 1:
            questionPage(
                title: "What do you want most right now?",
                subtitle: "We use this to shape the type of exercises in your plan.",
                options: OnboardingOptions.goals,
                selection: $goal
            )
        case 2:
            questionPage(
                title: "How many days per week can you commit to?",
                subtitle: "Your plan will fit around your availability — no pressure.",
                options: OnboardingOptions.daysPerWeek,
                selection: $daysPerWeek
            )
        case 3:
            questionPage(
                title: "How long should most workouts be?",
                subtitle: "Short or long, every session is designed to count.",
                options: OnboardingOptions.sessionLengths,
                selection: $sessionLength
            )
        case 4:
            questionPage(
                title: "Where will you usually work out?",
                subtitle: "We only suggest exercises that match what you have.",
                options: OnboardingOptions.equipment,
                selection: $equipment
            )
        case 5:
            injuryPage()
        default:
            EmptyView()
        }
    }

    // MARK: - Intro Page

    private var introPage: some View {
        VStack(spacing: DS.Spacing.md) {
            Text("Welcome to Revibe")
                .font(.system(size: 26, weight: .regular, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)
                .tracking(-0.3)

            Text("Answer a few quick questions and we'll build a plan personalized for you.")
                .font(.subheadline)
                .foregroundColor(DS.Colors.textMuted)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                introFeatureRow(
                    icon: "camera.viewfinder",
                    title: "Track form with camera guidance",
                    detail: "Real-time feedback on your movement"
                )
                introFeatureRow(
                    icon: "cross.case",
                    title: "Get safer exercise suggestions",
                    detail: "Injury-aware recommendations"
                )
                introFeatureRow(
                    icon: "figure.run",
                    title: "Follow a plan matched to you",
                    detail: "Built around your body and goals"
                )
            }
            .padding(.top, DS.Spacing.xs)
        }
    }

    private func introFeatureRow(icon: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(DS.Colors.bgSecondary)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 17))
                    .foregroundColor(DS.Colors.accent)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(DS.Colors.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundColor(DS.Colors.textMuted)
            }
            Spacer()
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

    // MARK: - Question Page

    private func questionPage(title: String, subtitle: String, options: [String], selection: Binding<String>) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.3)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(DS.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    optionButton(label: option, isSelected: selection.wrappedValue == option) {
                        withAnimation(.easeInOut(duration: 0.15)) { selection.wrappedValue = option }
                        advanceAfterDelay()
                    }
                }
            }
        }
    }

    private func advanceAfterDelay() {
        guard currentPage < totalPages - 1 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentPage += 1
            }
        }
    }

    // MARK: - Injury Page

    private func injuryPage() -> some View {
        let options = OnboardingOptions.injuryAreas

        return VStack(spacing: 20) {
            VStack(spacing: 6) {
                Text("Any body areas you want us to be careful with?")
                    .font(.system(size: 24, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .tracking(-0.3)

                Text("We'll avoid loading these areas and offer safer alternatives.")
                    .font(.caption)
                    .foregroundColor(DS.Colors.textMuted)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    optionButton(label: option, isSelected: injuryArea == option) {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            injuryArea = option
                            showInjuryInput = (option == "Other")
                            if option != "Other" { injuryNote = "" }
                        }
                    }
                }
            }

            if showInjuryInput {
                TextField("", text: $injuryNote, prompt: Text("Tell us briefly").foregroundColor(DS.Colors.textMuted))
                    .foregroundColor(DS.Colors.textPrimary)
                    .padding(12)
                    .background(DS.Colors.bgSecondary)
                    .cornerRadius(DS.Radius.input)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.input)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Navigation Arrows

    private var navigationArrows: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage = max(0, currentPage - 1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2.weight(.medium))
                    .foregroundColor(currentPage > 0 ? DS.Colors.textPrimary : DS.Colors.border)
                    .frame(width: 44, height: 44)
            }
            .disabled(currentPage == 0)

            Spacer()

            if currentPage < totalPages - 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentPage = min(totalPages - 1, currentPage + 1)
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title2.weight(.medium))
                        .foregroundColor(canAdvance ? DS.Colors.textPrimary : DS.Colors.border)
                        .frame(width: 44, height: 44)
                }
                .disabled(!canAdvance)
            }
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        if currentPage == 0 {
            // Intro page — "Get Started" button
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentPage = 1
                }
            } label: {
                Text("Get Started")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(DS.Colors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DS.Colors.accent)
                    .cornerRadius(DS.Radius.button)
            }
        } else if currentPage == totalPages - 1 {
            VStack(spacing: 12) {
                if isSubmitting {
                    generationProgressView
                } else {
                    // Bridge summary: benefit rows + trust signal
                    if isFormComplete {
                        bridgeSummary
                    }

                    HStack {
                        Spacer()
                        Button {
                            Task { await submit() }
                        } label: {
                            Text("Build My Revibe Plan")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(DS.Colors.textOnAccent)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 28)
                                .background(isFormComplete ? DS.Colors.accent : DS.Colors.textMuted)
                                .cornerRadius(DS.Radius.button)
                        }
                        .disabled(!isFormComplete || isSubmitting)
                    }

                    HStack {
                        Spacer()
                        Text("Adjustable anytime as your condition changes.")
                            .font(.caption)
                            .foregroundColor(DS.Colors.textMuted)
                    }
                }
            }
        } else {
            Color.clear.frame(height: 1)
        }
    }

    // MARK: - Bridge Summary

    private var bridgeSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Based on your answers, you'll get:")
                .font(.caption.weight(.medium))
                .foregroundColor(DS.Colors.textMuted)

            bridgeBenefitRow(icon: "figure.run", text: "Personalized exercise plan")
            bridgeBenefitRow(icon: "camera.viewfinder", text: "Real-time movement feedback")
            bridgeBenefitRow(icon: "cross.case", text: "Injury-aware recommendations")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.card)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )
        )
    }

    private func bridgeBenefitRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(DS.Colors.accent)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
                .foregroundColor(DS.Colors.textPrimary)
        }
    }

    // MARK: - Generation Progress

    private var generationProgressView: some View {
        VStack(spacing: 10) {
            Text("Building your personalized plan…")
                .font(.subheadline.weight(.medium))
                .foregroundColor(DS.Colors.textPrimary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(DS.Colors.border)
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(DS.Gradients.progress)
                        .frame(width: geo.size.width * generationProgress, height: 10)
                        .animation(.easeInOut(duration: 0.4), value: generationProgress)
                }
            }
            .frame(height: 10)

            Text("\(Int(generationProgress * 100))%")
                .font(.caption.monospacedDigit())
                .foregroundColor(DS.Colors.textMuted)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Option Button

    private func optionButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(DS.Colors.textPrimary)
                Spacer()
                Circle()
                    .strokeBorder(isSelected ? DS.Colors.accent : DS.Colors.border, lineWidth: isSelected ? 6 : 1.5)
                    .frame(width: 22, height: 22)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(isSelected ? DS.Colors.bgSecondary : Color.clear)
            .cornerRadius(DS.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(isSelected ? DS.Colors.accent : DS.Colors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Submit

    private func submit() async {
        isSubmitting = true
        generationProgress = 0
        startProgressSimulation()

        do {
            let userId = try await supabase.auth.session.user.id.uuidString

            let response = OnboardingResponse(
                userId: userId,
                goal: goal,
                daysPerWeek: daysPerWeek,
                sessionLength: sessionLength,
                equipment: equipment,
                injuryArea: injuryArea,
                injuryNote: injuryNote.isEmpty ? nil : injuryNote
            )

            try await supabase
                .from("onboarding_responses")
                .insert(response)
                .execute()

            try await supabase.functions.invoke(
                "generate-plan",
                options: .init(body: ["user_id": userId])
            )

            await finishProgress()
            onComplete()
        } catch {
            stopProgressSimulation()
            isSubmitting = false
            onComplete()
        }
    }

    private func startProgressSimulation() {
        generationTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            Task { @MainActor in
                if generationProgress < 0.85 {
                    generationProgress += Double.random(in: 0.02...0.06)
                }
            }
        }
    }

    private func stopProgressSimulation() {
        generationTimer?.invalidate()
        generationTimer = nil
    }

    @MainActor
    private func finishProgress() async {
        stopProgressSimulation()
        withAnimation(.easeInOut(duration: 0.4)) {
            generationProgress = 1.0
        }
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
