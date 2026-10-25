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

struct OceanBackground: View {
    var tint: Color = Theme.sea

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.abyss, Theme.deep, tint], startPoint: .top, endPoint: .bottom)
            Bubbles()
                .opacity(0.5)
        }
        .ignoresSafeArea()
    }
}

/// Slow rising bubbles. Purely decorative, drawn in one Canvas.
struct Bubbles: View {
    private struct Bubble {
        let x: Double, speed: Double, size: Double, wobble: Double, offset: Double
    }

    private let bubbles: [Bubble] = (0..<14).map { i in
        var g = SeededGenerator(seed: UInt64(i + 1) * 7919)
        return Bubble(
            x: .random(in: 0...1, using: &g), speed: .random(in: 0.015...0.04, using: &g),
            size: .random(in: 3...9, using: &g), wobble: .random(in: 4...14, using: &g), offset: .random(in: 0...1, using: &g)
        )
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                for b in bubbles {
                    let progress = (b.offset + t * b.speed).truncatingRemainder(dividingBy: 1)
                    let y = size.height * (1.05 - progress * 1.1)
                    let x = size.width * b.x + sin(t * 0.8 + b.offset * 10) * b.wobble
                    let rect = CGRect(x: x, y: y, width: b.size, height: b.size)
                    context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.35 * (1 - progress))), lineWidth: 1)
                }
            }
        }
        .allowsHitTesting(false)
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
            .background(Theme.card, in: .rect(cornerRadius: radius))
            .overlay(RoundedRectangle(cornerRadius: radius).strokeBorder(Theme.cardStroke))
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
            .background(color, in: .capsule)
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
            .background(Color.white.opacity(configuration.isPressed ? 0.12 : 0.06), in: .capsule)
    }
}
