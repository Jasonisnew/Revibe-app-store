//
//  DesignSystem.swift
//  Revibe
//

import SwiftUI

enum DS {
    enum Colors {
        // Backgrounds (deep navy)
        static let bgPrimary   = Color(red: 11/255, green: 15/255, blue: 26/255)     // #0B0F1A
        static let bgSecondary = Color(red: 20/255, green: 24/255, blue: 37/255)     // #141825
        static let bgTertiary  = Color(red: 28/255, green: 34/255, blue: 53/255)     // #1C2235

        // Text
        static let textPrimary   = Color.white
        static let textSecondary = Color(red: 160/255, green: 170/255, blue: 190/255) // #A0AABE
        static let textMuted     = Color(red: 90/255, green: 100/255, blue: 128/255)  // #5A6480
        static let textOnAccent  = Color(red: 11/255, green: 15/255, blue: 26/255)    // #0B0F1A

        // Accent (lime green)
        static let accent    = Color(red: 197/255, green: 244/255, blue: 103/255)     // #C5F467
        static let accentDim = Color(red: 157/255, green: 195/255, blue: 82/255)      // #9DC352

        // Blue accent (secondary — cards, highlights, calendar)
        static let blue      = Color(red: 52/255, green: 120/255, blue: 246/255)      // #3478F6
        static let blueDim   = Color(red: 37/255, green: 87/255, blue: 184/255)       // #2557B8
        static let blueDeep  = Color(red: 26/255, green: 48/255, blue: 85/255)        // #1A3055

        // Error / destructive
        static let error = Color(red: 255/255, green: 69/255, blue: 58/255)           // #FF453A

        // Highlight / selection
        static let highlight = Color(red: 197/255, green: 244/255, blue: 103/255)     // #C5F467

        // Borders / dividers (navy-tinted)
        static let border = Color(red: 30/255, green: 37/255, blue: 56/255)           // #1E2538

        // Progress bar gradient (lime shades)
        static let progressStart = Color(red: 197/255, green: 244/255, blue: 103/255) // #C5F467
        static let progressEnd   = Color(red: 162/255, green: 214/255, blue: 56/255)  // #A2D638

        // Success green
        static let success    = Color(red: 74/255, green: 222/255, blue: 128/255)     // #4ADE80
        static let successDim = Color(red: 74/255, green: 222/255, blue: 128/255).opacity(0.15)

        // Card surface palette (blue-navy tinted)
        static let cardSurface1 = Color(red: 22/255, green: 30/255, blue: 50/255)     // deep navy
        static let cardSurface2 = Color(red: 18/255, green: 32/255, blue: 52/255)     // blue-teal navy
        static let cardSurface3 = Color(red: 26/255, green: 28/255, blue: 48/255)     // indigo navy
        static let cardSurface4 = Color(red: 24/255, green: 35/255, blue: 44/255)     // teal navy
        static let cardSurface5 = Color(red: 20/255, green: 26/255, blue: 44/255)     // cool navy
        static let cardSurface6 = Color(red: 28/255, green: 24/255, blue: 46/255)     // violet navy

        static let cardPalette: [Color] = [cardSurface1, cardSurface2, cardSurface3, cardSurface4, cardSurface5, cardSurface6]

        // Legacy aliases
        static let cardSand        = bgSecondary
        static let paleYellowPeach = bgTertiary
        static let greenBlueStart  = success
        static let peachStart      = bgSecondary
        static let peachEnd        = bgTertiary
        static let paleOrange      = bgSecondary

        // Elevation
        static let shadowLight = Color.black.opacity(0.5)
    }

    enum Gradients {
        /// Blue card gradient (like activity cards in the reference)
        static let blueCard = LinearGradient(
            colors: [DS.Colors.blueDeep, DS.Colors.blue.opacity(0.6)],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
        /// Subtle blue surface gradient (for hero cards)
        static let blueSurface = LinearGradient(
            colors: [DS.Colors.bgSecondary, DS.Colors.blueDeep.opacity(0.6)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        /// Progress bar: lime green
        static let progress = LinearGradient(
            colors: [DS.Colors.progressStart, DS.Colors.progressEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
        /// Kept for compatibility
        static let peachToPink = LinearGradient(
            colors: [DS.Colors.bgSecondary, DS.Colors.bgTertiary],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let paleOrange = LinearGradient(
            colors: [DS.Colors.bgSecondary, DS.Colors.bgTertiary],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let greenBlue = LinearGradient(
            colors: [DS.Colors.bgSecondary, DS.Colors.bgTertiary],
            startPoint: .leading,
            endPoint: .trailing
        )
        static let cardYellowPeach = LinearGradient(
            colors: [DS.Colors.bgSecondary, DS.Colors.bgSecondary],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    enum Radius {
        static let button: CGFloat    = 12
        static let card: CGFloat      = 16
        static let input: CGFloat     = 12
    }

    enum Spacing {
        static let xs: CGFloat  = 8
        static let sm: CGFloat  = 16
        static let md: CGFloat  = 24
        static let lg: CGFloat  = 32
        static let xl: CGFloat  = 48
        static let xxl: CGFloat = 64
    }
}

// MARK: - View Modifiers

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundColor(DS.Colors.textOnAccent)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(isEnabled ? DS.Colors.accent : DS.Colors.textMuted)
            .cornerRadius(DS.Radius.button)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .foregroundColor(DS.Colors.textPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(DS.Colors.bgSecondary)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
            .cornerRadius(DS.Radius.button)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
