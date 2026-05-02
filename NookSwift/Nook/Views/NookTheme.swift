import SwiftUI

enum NookTheme {
    // MARK: - Brand Colors (from v1 design)

    static let blue = Color(hex: "#0066FF")
    static let blueDark = Color(hex: "#3C8CFF")
    static let blueBg = Color(hex: "#0066FF").opacity(0.08)
    static let blueBgDark = Color(hex: "#3C8CFF").opacity(0.12)

    static let red = Color(hex: "#D32F2F")
    static let redDark = Color(hex: "#EF5350")
    static let orange = Color(hex: "#FFB300")
    static let orangeDark = Color(hex: "#FFC107")
    static let teal = Color(hex: "#0288D1")
    static let tealDark = Color(hex: "#42A5F5")

    // MARK: - Light Theme
    enum Light {
        static let bg = Color(hex: "#FCFCFD")
        static let bg2 = Color(hex: "#F1F1F4")
        static let bgHover = Color(hex: "#E8E8ED")
        static let t1 = Color(hex: "#1E1E2A")
        static let t2 = Color(hex: "#5C5C6E")
        static let t3 = Color(hex: "#8A8A96")
        static let t4 = Color(hex: "#BBBBC2")
        static let line = Color(hex: "#DDDDE2")
        static let pn = Color(hex: "#D4D4DA")
        static let tagOn = Color(hex: "#3A3A48")
        static let tagOnFg = Color(hex: "#F7F7FA")
        // HTML --snip-bg: rgba(232,232,238,0.74)
        static let snippetBg = Color(hex: "#E8E8EE").opacity(0.74)
        static let snippetFg = Color(hex: "#4A4A55")
        static let snippetFg2 = Color(hex: "#8E8E98")
    }

    // MARK: - Dark Theme
    enum Dark {
        static let bg = Color(hex: "#1A1A26")
        static let bg2 = Color(hex: "#2E2E3C")
        static let bgHover = Color(hex: "#343442")
        static let t1 = Color(hex: "#E5E5EA")
        static let t2 = Color(hex: "#8A8A96")
        static let t3 = Color(hex: "#646470")
        static let t4 = Color(hex: "#777784")
        static let line = Color(hex: "#383846")
        static let pn = Color(hex: "#4A4A54")
        static let tagOn = Color(hex: "#E5E5EA")
        static let tagOnFg = Color(hex: "#1A1A26")
        static let snippetBg = Color(hex: "#18182A")
        static let snippetFg = Color(hex: "#AAAAB2")
        static let snippetFg2 = Color(hex: "#646470")
    }

    // MARK: - Confetti Colors
    static let confettiColors: [String] = [
        "#FF6B6B", "#4FC3F7", "#81C784", "#FFD54F",
        "#BA68C8", "#FF8A65", "#0066FF"
    ]

    static func bg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.bg : Light.bg
    }

    static func bg2(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.bg2 : Light.bg2
    }

    static func bgHover(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.bgHover : Light.bgHover
    }

    static func t1(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.t1 : Light.t1
    }

    static func t2(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.t2 : Light.t2
    }

    static func t3(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.t3 : Light.t3
    }

    static func t4(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.t4 : Light.t4
    }

    static func line(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.line : Light.line
    }

    static func accent(_ scheme: ColorScheme) -> Color {
        // Brand accent matches the active "all" tag — dark almost-black in light mode,
        // light gray in dark mode. No more blue.
        scheme == .dark ? Dark.tagOn : Light.tagOn
    }

    static func blueBg(_ scheme: ColorScheme) -> Color {
        // Subtle accent tint for chip backgrounds, hover states, etc.
        scheme == .dark ? Dark.tagOn.opacity(0.12) : Light.tagOn.opacity(0.08)
    }

    static func tagOn(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.tagOn : Light.tagOn
    }

    static func tagOnFg(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Dark.tagOnFg : Light.tagOnFg
    }

    static func panelBorder(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: "#383846").opacity(0.5) : Color(hex: "#E5E5EA").opacity(0.6)
    }
}

// MARK: - Nook Font

extension Font {
    /// PingFang SC (Chinese) + SF Pro (latin) — macOS system standard.
    static func nook(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("PingFang SC", size: size).weight(weight)
    }
}
