import SwiftUI

// The phone is the clam. On the Duo the inner screen folds across its middle, so the top half is the
// underside of the lid and the bottom half is the bowl, with the real hinge between them. The cover
// display is the outside of the shell. On phones without a hinge the same split still reads as an open clam.

enum Nacre {
    /// Dark "black-lip" mother of pearl, so text stays readable.
    static let base = Color(red: 0.06, green: 0.08, blue: 0.11)
    static let lip = Color(red: 0.02, green: 0.02, blue: 0.04)
    static let sheens: [Color] = [
        Color(red: 0.22, green: 0.58, blue: 0.62),
        Color(red: 0.46, green: 0.36, blue: 0.74),
        Color(red: 0.78, green: 0.46, blue: 0.62),
        Color(red: 0.56, green: 0.68, blue: 0.46),
        Color(red: 0.26, green: 0.42, blue: 0.80),
    ]
    static let flush = Color(red: 0.70, green: 0.12, blue: 0.16)
}

/// One half of the inside of the shell: iridescent bands and fine growth lines, all centered on the hinge.
struct NacreSurface: View {
    enum Half { case lid, bowl }

    var half: Half
    /// Shifts the iridescence. Driven by the hinge angle and slow drift.
    var sheen: Double = 0
    /// 0...1. Reddens the inside, for when the shell is pried open early.
    var flush: Double = 0

    var body: some View {
        Canvas { context, size in
            let hinge = CGPoint(x: size.width / 2, y: half == .lid ? size.height : 0)
            let reach = hypot(size.width / 2, size.height) * 1.05
            let ellipse = { (r: CGFloat) -> CGRect in
                CGRect(x: hinge.x - r * 1.3, y: hinge.y - r, width: r * 2.6, height: r * 2)
            }

            // Lighter nacre near the hinge, darkening to the black lip at the outer edge.
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                Gradient(colors: [Color(red: 0.13, green: 0.17, blue: 0.21), Nacre.base, Nacre.lip]),
                center: hinge, startRadius: 0, endRadius: reach))

            // Patches of iridescence drifting over the surface, like light on mother of pearl.
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: min(size.width, size.height) * 0.12))
                var g = SeededGenerator(seed: half == .lid ? 11 : 29)
                for i in 0..<7 {
                    let angle = Double.random(in: 0...(2 * .pi), using: &g) + sheen * 0.6 * (i.isMultiple(of: 2) ? 1 : -1)
                    let dist = Double.random(in: 0.15...0.75, using: &g)
                    let c = CGPoint(x: size.width * (0.5 + cos(angle) * dist * 0.55),
                                    y: half == .lid ? size.height * (1 - abs(sin(angle)) * dist) : size.height * abs(sin(angle)) * dist)
                    let r = min(size.width, size.height) * .random(in: 0.25...0.45, using: &g)
                    let color = Nacre.sheens[(i + Int(floor(sheen))) % Nacre.sheens.count]
                    layer.fill(Path(ellipseIn: CGRect(x: c.x - r * 1.3, y: c.y - r, width: r * 2.6, height: r * 2)), with: .color(color.opacity(0.3)))
                }
                // A soft band of sheen following the hinge.
                for i in 0..<4 {
                    let r = reach * (0.18 + 0.2 * CGFloat(i))
                    let color = Nacre.sheens[(i * 2 + Int(floor(sheen * 2))) % Nacre.sheens.count]
                    layer.stroke(Path(ellipseIn: ellipse(r)), with: .color(color.opacity(0.18)), lineWidth: reach * 0.08)
                }
            }

            // Faint growth lines, slightly uneven.
            for i in 1..<14 {
                let r = reach * CGFloat(i) / 14 + CGFloat(sin(Double(i) * 2.3)) * reach * 0.012
                context.stroke(Path(ellipseIn: ellipse(r)), with: .color(.white.opacity(0.03)), lineWidth: 1)
            }

            if flush > 0 {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                    Gradient(colors: [Nacre.flush.opacity(0.55 * flush), Nacre.flush.opacity(0.2 * flush)]),
                    center: hinge, startRadius: 0, endRadius: reach))
            }
        }
        .overlay {
            // The dark lip along the outer edges, the ones away from the hinge.
            LipShadow(half: half)
        }
        .drawingGroup()
    }
}

/// A soft dark band along the three outer edges of a half, leaving the hinge edge clear.
private struct LipShadow: View {
    var half: NacreSurface.Half

    var body: some View {
        GeometryReader { geo in
            let band = min(geo.size.width, geo.size.height) * 0.12
            Rectangle()
                .stroke(Nacre.lip.opacity(0.85), lineWidth: band)
                .blur(radius: band * 0.6)
                // Push the hinge edge out of view so only the lip edges darken.
                .frame(width: geo.size.width, height: geo.size.height + band * 3)
                .offset(y: half == .lid ? 0 : -band * 3)
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

/// The inside of the clam, split at the screen's middle where the Duo folds.
/// `lid` is laid out in the top half and `bowl` in the bottom half, both inside the safe area.
struct ClamInterior<Lid: View, Bowl: View>: View {
    /// Hinge angle in degrees, 0 shut to 180 flat. Light spills in from the lip as it opens.
    var openDegrees: Double = 180
    var flush: Double = 0
    var gutter: CGFloat = 14
    @ViewBuilder var lid: Lid
    @ViewBuilder var bowl: Bowl

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets
            let full = geo.size.height + insets.top + insets.bottom
            // Where the crease falls, measured from the top of the safe area.
            let crease = full / 2 - insets.top
            ZStack(alignment: .top) {
                TimelineView(.animation(minimumInterval: 1 / 15, paused: reduceMotion)) { timeline in
                    let drift = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * 0.02
                    let sheen = drift + openDegrees / 60
                    VStack(spacing: 0) {
                        NacreSurface(half: .lid, sheen: sheen, flush: flush)
                        NacreSurface(half: .bowl, sheen: sheen + 0.5, flush: flush)
                    }
                }
                .overlay { HingeSeam() }
                .overlay { Dimming(openDegrees: openDegrees) }
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    lid
                        .frame(maxWidth: .infinity)
                        .frame(height: max(0, crease - gutter))
                    Color.clear.frame(height: gutter * 2)
                    bowl
                        .frame(maxWidth: .infinity)
                        .frame(height: max(0, geo.size.height - crease - gutter))
                }
            }
        }
    }
}

/// The ligament along the fold: a thin dark seam with a little shading either side.
private struct HingeSeam: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            LinearGradient(colors: [.clear, .black.opacity(0.45)], startPoint: .top, endPoint: .bottom).frame(height: 26)
            Rectangle().fill(Color(red: 0.12, green: 0.08, blue: 0.10)).frame(height: 2)
            LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .bottom).frame(height: 22)
            Spacer(minLength: 0)
        }
        .allowsHitTesting(false)
    }
}

/// While the shell is only part open, the inside is dark near the hinge and lit at the lip.
private struct Dimming: View {
    var openDegrees: Double

    var body: some View {
        let dark = max(0, min(1, 1 - (openDegrees - 20) / 110)) * 0.8
        RadialGradient(colors: [.black.opacity(dark), .black.opacity(dark * 0.35)], center: .center, startRadius: 0, endRadius: 600)
            .allowsHitTesting(false)
            .animation(.easeOut(duration: 0.25), value: dark)
    }
}

/// The outside of the shell, filling the cover display.
struct ShellExterior: View {
    var body: some View {
        Canvas { context, size in
            let hinge = CGPoint(x: size.width / 2, y: size.height * 1.02)
            let reach = hypot(size.width / 2, size.height) * 1.05
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                Gradient(colors: [Color(red: 0.36, green: 0.31, blue: 0.29), Color(red: 0.22, green: 0.19, blue: 0.19), Color(red: 0.10, green: 0.09, blue: 0.10)]),
                center: CGPoint(x: size.width * 0.4, y: size.height * 0.3), startRadius: 0, endRadius: reach))

            // Broad ribs fanning out from the hinge: alternating light and shadow, softened.
            context.drawLayer { layer in
                layer.addFilter(.blur(radius: 5))
                let ribs = 13
                let span = size.width * 1.5
                for i in 0..<ribs {
                    let a0 = CGFloat(i) / CGFloat(ribs), a1 = (CGFloat(i) + 0.5) / CGFloat(ribs)
                    let x0 = -size.width * 0.25 + span * a0, x1 = -size.width * 0.25 + span * a1
                    var p = Path()
                    p.move(to: hinge)
                    p.addQuadCurve(to: CGPoint(x: x0, y: -30), control: CGPoint(x: (hinge.x + x0) / 2 + (a0 - 0.5) * size.width * 0.25, y: size.height * 0.5))
                    p.addLine(to: CGPoint(x: x1, y: -30))
                    p.addQuadCurve(to: hinge, control: CGPoint(x: (hinge.x + x1) / 2 + (a1 - 0.5) * size.width * 0.25, y: size.height * 0.5))
                    layer.fill(p, with: .color(.white.opacity(0.07)))
                }
            }

            // Growth rings, uneven like the real thing.
            for i in 1..<8 {
                let r = reach * (CGFloat(i) / 8 + 0.02 * sin(CGFloat(i) * 3))
                var p = Path()
                for step in 0...80 {
                    let a = Double.pi + Double.pi * Double(step) / 80
                    let wobble = 1 + 0.012 * sin(a * 23 + Double(i)) + 0.02 * sin(a * 5 + Double(i) * 2)
                    let pt = CGPoint(x: hinge.x + cos(a) * r * 1.25 * wobble, y: hinge.y + sin(a) * r * wobble)
                    if step == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
                }
                context.stroke(p, with: .color(.black.opacity(0.22)), lineWidth: 2.5)
                context.stroke(p.offsetBy(dx: 0, dy: 2.5), with: .color(.white.opacity(0.05)), lineWidth: 1.2)
            }
        }
        .overlay(RadialGradient(colors: [.clear, .black.opacity(0.55)], center: .center, startRadius: 120, endRadius: 700))
        .ignoresSafeArea()
    }
}

/// The grain of sand a pearl starts from. Glints now and then.
struct SandGrain: View {
    var size: CGFloat = 14
    var glow: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.sand.opacity(0.35 * glow))
                .frame(width: size * 5, height: size * 5)
                .blur(radius: size * 1.2)
            Blob(seed: 21)
                .fill(RadialGradient(colors: [Color(red: 0.98, green: 0.92, blue: 0.78), Color(red: 0.72, green: 0.62, blue: 0.48)], center: UnitPoint(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.7))
                .frame(width: size, height: size * 0.85)
                .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
        }
        .frame(width: size * 3, height: size * 3)
        .accessibilityHidden(true)
    }
}

#Preview("Clam") {
    ClamInterior {
        Text("Hello").foregroundStyle(.white)
    } bowl: {
        VStack { SandGrain(glow: 0.6); Spacer() }
    }
}
