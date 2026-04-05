//
//  ProfileView.swift
//  Revibe
//

import SwiftUI
import Supabase

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showSettings = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {

                // MARK: - Top pills
                topPills
                    .padding(.top, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Avatar
                avatar
                    .padding(.top, DS.Spacing.md)

                // MARK: - Name + subtitle
                nameSection
                    .padding(.top, DS.Spacing.sm)

                // MARK: - Streak progress bar
                streakBar
                    .padding(.top, DS.Spacing.md)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Status text
                statusText
                    .padding(.top, 10)

                // MARK: - Info badges
                badgePills
                    .padding(.top, DS.Spacing.sm)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Plan card
                planCard
                    .padding(.top, DS.Spacing.md)
                    .padding(.horizontal, DS.Spacing.md)

                // MARK: - Sign out
                signOutButton
                    .padding(.top, DS.Spacing.lg)
                    .padding(.horizontal, DS.Spacing.md)
                    .padding(.bottom, 100)
            }
        }
        .background(DS.Colors.bgPrimary.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(DS.Colors.bgPrimary, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Profile")
                    .font(.system(size: 17, weight: .medium, design: .serif))
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
        .task {
            await viewModel.loadProfile()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(viewModel: viewModel)
        }
    }

    // MARK: - Top Pills

    private var topPills: some View {
        HStack {
            Button {
                showSettings = true
            } label: {
                pillLabelContent(text: "Settings", icon: "gearshape", filled: false)
            }
            .buttonStyle(.plain)

            Spacer()

            pillLabel(
                text: viewModel.streak > 0 ? "Active" : "Getting Started",
                icon: viewModel.streak > 0 ? "flame.fill" : "sparkle",
                filled: true
            )
        }
    }

    private func pillLabel(text: String, icon: String, filled: Bool) -> some View {
        pillLabelContent(text: text, icon: icon, filled: filled)
    }

    private func pillLabelContent(text: String, icon: String, filled: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .foregroundColor(filled ? DS.Colors.textOnAccent : DS.Colors.textPrimary)
        .background(
            Capsule()
                .fill(filled ? DS.Colors.accent : DS.Colors.bgSecondary)
        )
        .overlay(
            Capsule()
                .stroke(filled ? Color.clear : DS.Colors.border, lineWidth: 1)
        )
    }

    // MARK: - Avatar

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [DS.Colors.bgTertiary, DS.Colors.blueDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)

                Text(initials)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundColor(DS.Colors.textPrimary)
            }

            ZStack {
                Circle()
                    .fill(DS.Colors.bgPrimary)
                    .frame(width: 32, height: 32)
                Circle()
                    .fill(DS.Colors.accent.opacity(0.2))
                    .frame(width: 28, height: 28)
                Image(systemName: "figure.run")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.accent)
            }
            .offset(x: 2, y: 2)
        }
    }

    private var initials: String {
        let parts = viewModel.displayName.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let last = parts.count > 1 ? parts.last!.prefix(1) : ""
        return "\(first)\(last)".uppercased()
    }

    // MARK: - Name Section

    private var nameSection: some View {
        VStack(spacing: 4) {
            Text(viewModel.displayName.isEmpty ? "Revibe Athlete" : viewModel.displayName)
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .foregroundColor(DS.Colors.textPrimary)
                .tracking(-0.3)

            Text(viewModel.goal.isEmpty ? "Building a healthier you" : goalLabel)
                .font(.subheadline)
                .foregroundColor(DS.Colors.textSecondary)
        }
    }

    private var goalLabel: String {
        switch viewModel.goal {
        case "Build muscle": return "Building muscle"
        case "Lose fat": return "Losing fat"
        case "Stay fit and maintain my physique": return "Staying fit"
        case "Move better and feel less stiff": return "Moving better"
        default:
            switch viewModel.goal.lowercased() {
            case "build_muscle": return "Building muscle"
            case "lose_fat": return "Losing fat"
            case "stay_active": return "Staying active"
            case "rehab": return "Injury recovery"
            default: return viewModel.goal.replacingOccurrences(of: "_", with: " ").capitalized
            }
        }
    }

    // MARK: - Streak Progress Bar

    private var streakBar: some View {
        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 11))
                        .foregroundColor(DS.Colors.accent)
                    Text("\(viewModel.streak)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Colors.textPrimary)
                        .monospacedDigit()
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(DS.Colors.border)
                            .frame(height: 6)

                        Capsule()
                            .fill(DS.Gradients.progress)
                            .frame(
                                width: streakProgress(width: geo.size.width),
                                height: 6
                            )
                    }
                }
                .frame(height: 6)

                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11))
                        .foregroundColor(DS.Colors.accentDim)
                    Text("\(viewModel.longestStreak)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(DS.Colors.textPrimary)
                        .monospacedDigit()
                }
            }

            HStack {
                Text("Current streak")
                    .font(.system(size: 11))
                    .foregroundColor(DS.Colors.textMuted)
                Spacer()
                Text("Longest streak")
                    .font(.system(size: 11))
                    .foregroundColor(DS.Colors.textMuted)
            }
        }
        .padding(DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Colors.bgSecondary)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private func streakProgress(width: CGFloat) -> CGFloat {
        guard viewModel.longestStreak > 0 else { return 0 }
        let ratio = CGFloat(viewModel.streak) / CGFloat(viewModel.longestStreak)
        return max(6, width * min(ratio, 1.0))
    }

    // MARK: - Status Text

    private var statusText: some View {
        Text(viewModel.streak > 0
             ? "On a \(viewModel.streak)-day streak"
             : "Start your first workout today")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(DS.Colors.textSecondary)
    }

    // MARK: - Badge Pills

    private var badgePills: some View {
        FlowLayout(spacing: 8) {
            if !viewModel.daysPerWeek.isEmpty {
                infoBadge(icon: "calendar", text: "\(viewModel.daysPerWeek)x / week")
            }
            if !viewModel.sessionLength.isEmpty {
                infoBadge(icon: "clock", text: viewModel.sessionLength)
            }
            if !viewModel.equipment.isEmpty {
                infoBadge(icon: "dumbbell.fill", text: equipmentLabel)
            }
        }
    }

    private var equipmentLabel: String {
        switch viewModel.equipment {
        case "Full gym", "Dumbbells only", "Home, no equipment", "Bands / light equipment":
            return viewModel.equipment
        default:
            switch viewModel.equipment.lowercased() {
            case "full_gym": return "Full gym"
            case "dumbbells": return "Dumbbells"
            case "bodyweight": return "Bodyweight"
            case "bands": return "Resistance bands"
            default: return viewModel.equipment.replacingOccurrences(of: "_", with: " ").capitalized
            }
        }
    }

    private func infoBadge(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(DS.Colors.blue)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(DS.Colors.bgTertiary)
        )
    }

    // MARK: - Plan Card

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Plan")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(DS.Colors.accent)
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(viewModel.planSummary.isEmpty ? "No plan yet" : viewModel.planSummary)
                        .font(.system(size: 20, weight: .semibold, design: .serif))
                        .foregroundColor(DS.Colors.textPrimary)
                        .tracking(-0.3)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(DS.Colors.accent.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(DS.Colors.accent)
                }
            }

            if viewModel.planDayCount > 0 {
                Divider().overlay(DS.Colors.border)

                HStack(spacing: DS.Spacing.md) {
                    statItem(value: "\(viewModel.planDayCount)", label: "Days")
                    statItem(value: viewModel.daysPerWeek.isEmpty ? "-" : viewModel.daysPerWeek, label: "Per week")
                    statItem(value: viewModel.sessionLength.isEmpty ? "-" : viewModel.sessionLength, label: "Per session")
                }
            }
        }
        .padding(DS.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .fill(DS.Gradients.blueSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.card)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(DS.Colors.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(DS.Colors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Sign Out

    private var signOutButton: some View {
        Button(role: .destructive) {
            Task { try? await supabase.auth.signOut() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 14, weight: .medium))
                Text("Sign Out")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundColor(DS.Colors.error)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(DS.Colors.error.opacity(0.08))
            .cornerRadius(DS.Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .stroke(DS.Colors.error.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Flow Layout (horizontal wrapping badges)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: ProposedViewSize(subviews[index].sizeThatFits(.unspecified))
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
