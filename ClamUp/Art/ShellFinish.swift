import SwiftUI

/// The colors of one oyster: its nacre inside and its rough shell outside.
/// Finishing a set unlocks a new finish. The insides all stay dark so text reads on them.
struct ShellFinish: Equatable {
    /// Nacre near the hinge, where it's palest.
    var glow: Color
    var base: Color
    /// The dark band at the edge of the nacre.
    var lip: Color
    /// Colors that drift across the nacre.
    var sheens: [Color]
    /// The outside of the shell, lit to shadowed.
    var light: Color
    var mid: Color
    var dark: Color
}

private func rgb(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r, green: g, blue: b) }

extension OysterSkin {
    var finish: ShellFinish {
        switch self {
        case .classic:
            ShellFinish(glow: rgb(0.13, 0.17, 0.21), base: rgb(0.06, 0.08, 0.11), lip: rgb(0.02, 0.02, 0.04),
                        sheens: [rgb(0.22, 0.58, 0.62), rgb(0.46, 0.36, 0.74), rgb(0.78, 0.46, 0.62), rgb(0.56, 0.68, 0.46), rgb(0.26, 0.42, 0.80)],
                        light: rgb(0.55, 0.50, 0.47), mid: rgb(0.36, 0.32, 0.33), dark: rgb(0.17, 0.15, 0.17))
        case .junk:
            ShellFinish(glow: rgb(0.21, 0.17, 0.09), base: rgb(0.10, 0.08, 0.05), lip: rgb(0.04, 0.03, 0.02),
                        sheens: [rgb(0.80, 0.62, 0.30), rgb(0.70, 0.48, 0.26), rgb(0.85, 0.72, 0.45), rgb(0.55, 0.50, 0.28), rgb(0.78, 0.55, 0.40)],
                        light: rgb(0.62, 0.55, 0.45), mid: rgb(0.42, 0.36, 0.30), dark: rgb(0.20, 0.17, 0.14))
        case .cozy:
            ShellFinish(glow: rgb(0.18, 0.14, 0.22), base: rgb(0.09, 0.07, 0.12), lip: rgb(0.03, 0.02, 0.05),
                        sheens: [rgb(0.62, 0.50, 0.85), rgb(0.80, 0.55, 0.75), rgb(0.50, 0.55, 0.90), rgb(0.70, 0.62, 0.80), rgb(0.85, 0.62, 0.70)],
                        light: rgb(0.56, 0.50, 0.55), mid: rgb(0.37, 0.32, 0.38), dark: rgb(0.17, 0.14, 0.18))
        case .bath:
            ShellFinish(glow: rgb(0.10, 0.20, 0.18), base: rgb(0.05, 0.11, 0.10), lip: rgb(0.01, 0.04, 0.04),
                        sheens: [rgb(0.35, 0.75, 0.65), rgb(0.30, 0.60, 0.75), rgb(0.55, 0.80, 0.60), rgb(0.40, 0.70, 0.80), rgb(0.60, 0.78, 0.70)],
                        light: rgb(0.52, 0.56, 0.52), mid: rgb(0.33, 0.37, 0.35), dark: rgb(0.15, 0.18, 0.17))
        case .pirate:
            ShellFinish(glow: rgb(0.10, 0.16, 0.18), base: rgb(0.04, 0.08, 0.10), lip: rgb(0.01, 0.03, 0.04),
                        sheens: [rgb(0.15, 0.70, 0.60), rgb(0.20, 0.45, 0.85), rgb(0.55, 0.30, 0.75), rgb(0.30, 0.75, 0.35), rgb(0.80, 0.45, 0.35)],
                        light: rgb(0.55, 0.38, 0.32), mid: rgb(0.38, 0.24, 0.22), dark: rgb(0.18, 0.11, 0.10))
        case .disco:
            ShellFinish(glow: rgb(0.20, 0.21, 0.23), base: rgb(0.10, 0.11, 0.12), lip: rgb(0.03, 0.03, 0.04),
                        sheens: [rgb(0.80, 0.82, 0.86), rgb(0.70, 0.78, 0.88), rgb(0.88, 0.80, 0.85), rgb(0.75, 0.85, 0.80), rgb(0.85, 0.85, 0.75)],
                        light: rgb(0.66, 0.65, 0.63), mid: rgb(0.45, 0.44, 0.43), dark: rgb(0.22, 0.21, 0.21))
        case .grumpy:
            ShellFinish(glow: rgb(0.20, 0.08, 0.10), base: rgb(0.11, 0.04, 0.06), lip: rgb(0.04, 0.01, 0.02),
                        sheens: [rgb(0.75, 0.25, 0.35), rgb(0.55, 0.20, 0.50), rgb(0.80, 0.40, 0.30), rgb(0.45, 0.15, 0.30), rgb(0.70, 0.35, 0.55)],
                        light: rgb(0.40, 0.36, 0.40), mid: rgb(0.26, 0.22, 0.26), dark: rgb(0.12, 0.10, 0.12))
        }
    }
}

extension EnvironmentValues {
    /// The finish the person picked in the tide pool. Set once at the root.
    @Entry var shellFinish: ShellFinish = OysterSkin.classic.finish
}

/// A small open valve showing a finish, for the tide pool and unlock banners.
struct ShellSwatch: View {
    let skin: OysterSkin

    var body: some View {
        ShellValve(half: .bowl, sheen: 0.4, flush: 0)
            .aspectRatio(1.15, contentMode: .fit)
            .environment(\.shellFinish, skin.finish)
            .accessibilityHidden(true)
    }
}

/// A whole open oyster in miniature, lid above bowl, with whatever it made sitting in the bowl. Used on the share card.
struct OpenOyster: View {
    var pearl: PearlSpec?
    var width: CGFloat = 220

    var body: some View {
        let valve = CGSize(width: width, height: width * 0.78)
        VStack(spacing: 2) {
            ShellValve(half: .lid, sheen: 0.2, flush: 0).frame(width: valve.width, height: valve.height)
            ShellValve(half: .bowl, sheen: 0.7, flush: 0).frame(width: valve.width, height: valve.height)
                .overlay {
                    Group {
                        if let pearl {
                            PearlView(spec: pearl, diameter: width * (0.22 + 0.12 * pearl.size))
                        } else {
                            SandGrain(size: width * 0.06)
                        }
                    }
                    .offset(y: -valve.height * 0.08)
                }
        }
        .overlay {
            // The ligament holding the two valves together.
            Capsule()
                .fill(Color(red: 0.15, green: 0.11, blue: 0.10))
                .frame(width: width * 0.3, height: max(3, width * 0.03))
        }
        .accessibilityHidden(true)
    }
}

/// The app icon's artwork. `AppIcon.png` is rendered from this at 1024 points, scale 1, with no alpha.
struct AppIconArt: View {
    var body: some View {
        ZStack {
            RadialGradient(colors: [Color(red: 0.08, green: 0.17, blue: 0.22), Shell.seabed], center: .center, startRadius: 0, endRadius: 720)
            OpenOyster(pearl: PearlSpec(size: 1, color: .white, hueJitter: 0, grade: .round), width: 560)
        }
        .frame(width: 1024, height: 1024)
    }
}
