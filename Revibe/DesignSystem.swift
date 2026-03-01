//
//  DesignSystem.swift
//  Revibe
//

import SwiftUI

enum DS {
    enum Colors {
        // Backgrounds
        static let bgPrimary   = Color(red: 1, green: 1, blue: 1)           // #FFFFFF
        static let bgSecondary = Color(red: 248/255, green: 248/255, blue: 248/255) // subtle section

        // Text
        static let textPrimary   = Color(red: 51/255,  green: 51/255,  blue: 51/255)   // #333333
        static let textSecondary = Color(red: 51/255,  green: 51/255,  blue: 51/255)   // #333333
        static let textMuted     = Color(red: 160/255, green: 160/255, blue: 160/255)  // #A0A0A0
        static let textOnDark    = Color.white

        // Accent & CTA
        static let accent = Color(red: 255/255, green: 77/255, blue: 77/255)   // #FF4D4D
        static let ctaRed = Color(red: 255/255, green: 59/255, blue: 48/255)    // #FF3B30

        // Highlight / selection (e.g. selected tab, date)
        static let highlight = Color.black

        // Borders / dividers / progress unfilled
        static let border = Color(red: 224/255, green: 224/255, blue: 224/255) // #E0E0E0

        // Peach / orange family (cards, banners, speech bubbles)
        static let peachStart     = Color(red: 255/255, green: 237/255, blue: 216/255) // #FFEDD8
        static let peachEnd       = Color(red: 253/255, green: 230/255, blue: 231/255) // #FDE6E7
        static let paleOrange     = Color(red: 255/255, green: 235/255, blue: 204/255) // #FFEBCC
        static let paleYellowPeach = Color(red: 255/255, green: 240/255, blue: 217/255) // #FFF0D9
        // Progress bar gradient
        static let progressStart  = Color(red: 253/255, green: 230/255, blue: 115/255) // #FDE673
        static let progressEnd    = Color(red: 255/255, green: 173/255, blue: 2/255)   // #FFAD02

        // Green–blue gradient (category cards)
        static let greenBlueStart = Color(red: 232/255, green: 248/255, blue: 232/255) // #E8F8E8
        static let greenBlueEnd   = Color(red: 224/255, green: 245/255, blue: 255/255) // #E0F5FF

        // Session / category card palette (soft pastels)
        static let cardSand       = Color(red: 255/255, green: 237/255, blue: 216/255) // #FFEDD8 (was cardSand)
        static let cardPeachOrange = Color(red: 255/255, green: 237/255, blue: 216/255) // #FFEDD8
        static let cardYellowPeach = Color(red: 255/255, green: 240/255, blue: 217/255) // #FFF0D9
        static let cardGreenBlue  = Color(red: 232/255, green: 248/255, blue: 232/255)  // #E8F8E8
        static let cardSage  = Color(red: 232/255, green: 248/255, blue: 232/255)  // #E8F8E8
        static let cardClay  = Color(red: 253/255, green: 230/255, blue: 231/255)  // #FDE6E7
        static let cardSlate = Color(red: 224/255, green: 245/255, blue: 255/255)  // #E0F5FF
        static let cardMauve = Color(red: 255/255, green: 235/255, blue: 204/255)  // #FFEBCC
        static let cardStone = Color(red: 255/255, green: 240/255, blue: 217/255)  // #FFF0D9

        static let cardPalette: [Color] = [cardPeachOrange, cardYellowPeach, cardGreenBlue, peachEnd, paleOrange, paleYellowPeach]

        // Elevation (very subtle)
        static let shadowLight = Color.black.opacity(0.05)
    }

    enum Gradients {
        /// Peach to pink-orange (banners, countdown cards)
        static let peachToPink = LinearGradient(
            colors: [DS.Colors.peachStart, DS.Colors.peachEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
        /// Pale yellow-orange (speech bubbles, avatar circles)
        static let paleOrange = LinearGradient(
            colors: [DS.Colors.paleOrange, DS.Colors.peachStart],
            startPoint: .leading,
            endPoint: .trailing
        )
        /// Progress bar: yellow to orange
        static let progress = LinearGradient(
            colors: [DS.Colors.progressStart, DS.Colors.progressEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
        /// Green to blue (category cards)
        static let greenBlue = LinearGradient(
            colors: [DS.Colors.greenBlueStart, DS.Colors.greenBlueEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
        /// Very subtle yellow-peach (uniform card)
        static let cardYellowPeach = LinearGradient(
            colors: [DS.Colors.paleYellowPeach, DS.Colors.paleYellowPeach],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    enum Radius {
        static let button: CGFloat    = 6
        static let card: CGFloat      = 8
        static let input: CGFloat     = 6
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
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(isEnabled ? DS.Colors.textPrimary : DS.Colors.textMuted)
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
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.button)
                    .stroke(DS.Colors.textPrimary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
