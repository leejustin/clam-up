import SwiftUI

enum Theme {
    static let abyss = Color(red: 0.02, green: 0.06, blue: 0.11)
    static let deep = Color(red: 0.03, green: 0.11, blue: 0.18)
    static let sea = Color(red: 0.05, green: 0.24, blue: 0.31)
    static let foam = Color(red: 0.86, green: 0.95, blue: 0.95)
    static let mist = Color(red: 0.62, green: 0.76, blue: 0.79)
    static let sand = Color(red: 0.94, green: 0.85, blue: 0.69)
    static let coral = Color(red: 0.98, green: 0.52, blue: 0.44)
    static let kelp = Color(red: 0.42, green: 0.72, blue: 0.56)
    static let nacre = Color(red: 0.95, green: 0.84, blue: 0.88)
    static let card = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.10)

    static func rarityColor(_ rarity: Rarity) -> Color {
        switch rarity {
        case .common: mist
        case .uncommon: kelp
        case .rare: Color(red: 0.45, green: 0.66, blue: 0.98)
        case .legendary: Color(red: 0.98, green: 0.80, blue: 0.36)
        case .regret: coral
        }
    }

    /// The oyster's voice. Serif italic reads like someone muttering.
    static func voice(_ size: CGFloat) -> Font { .system(size: size, design: .serif).italic() }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font { .system(size: size, weight: weight, design: .rounded) }
}

/// The inside of the shell, for screens that aren't split at the hinge.
struct OceanBackground: View {
    var body: some View {
        NacreSurface(half: .bowl, sheen: 0.3)
            .overlay(Color.black.opacity(0.3))
            .ignoresSafeArea()
    }
}

/// Deterministic randomness for decoration and tests.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

struct CardBackground: ViewModifier {
    var radius: CGFloat = 20
    func body(content: Content) -> some View {
        content
            .background(
                LinearGradient(colors: [Color.white.opacity(0.09), Color.white.opacity(0.04)], startPoint: .top, endPoint: .bottom),
                in: .rect(cornerRadius: radius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(LinearGradient(colors: [Color.white.opacity(0.16), Color.white.opacity(0.04)], startPoint: .top, endPoint: .bottom))
            )
    }
}

extension View {
    func card(radius: CGFloat = 20) -> some View { modifier(CardBackground(radius: radius)) }
}

struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = Theme.sand
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.ui(18, .semibold))
            .foregroundStyle(Theme.abyss)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: [color.mix(with: .white, by: 0.15), color], startPoint: .top, endPoint: .bottom),
                in: .capsule
            )
            .shadow(color: color.opacity(0.25), radius: 14, y: 6)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.ui(16, .medium))
            .foregroundStyle(Theme.mist)
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
            .background(Color.white.opacity(configuration.isPressed ? 0.14 : 0.07), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.cardStroke))
    }
}

/// A speech bubble with a small tail pointing down at whoever is talking.
struct SpeechBubble: Shape {
    var radius: CGFloat = 22
    var tail: CGFloat = 12

    func path(in r: CGRect) -> Path {
        let body = CGRect(x: r.minX, y: r.minY, width: r.width, height: r.height - tail)
        var p = Path(roundedRect: body, cornerRadius: radius, style: .continuous)
        var t = Path()
        t.move(to: CGPoint(x: r.midX - tail * 1.1, y: body.maxY - 1))
        t.addQuadCurve(to: CGPoint(x: r.midX + tail * 0.2, y: r.maxY), control: CGPoint(x: r.midX - tail * 0.1, y: body.maxY + tail * 0.4))
        t.addQuadCurve(to: CGPoint(x: r.midX + tail * 0.9, y: body.maxY - 1), control: CGPoint(x: r.midX + tail * 0.4, y: body.maxY + tail * 0.4))
        t.closeSubpath()
        p.addPath(t)
        return p
    }
}

struct Pill: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Theme.ui(14, .semibold))
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(.ultraThinMaterial.opacity(0.6), in: .capsule)
            .overlay(Capsule().strokeBorder(Theme.cardStroke))
    }
}

extension View {
    func pill() -> some View { modifier(Pill()) }
}
