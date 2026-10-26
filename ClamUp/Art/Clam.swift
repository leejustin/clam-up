import SwiftUI

// The phone is the clam. On the Duo the inner screen folds across its middle, so the top half is the
// underside of the lid and the bottom half is the bowl, with the real hinge between them. The cover
// display is the outside of the shell. On phones without a hinge the same split still reads as an open clam.

enum Nacre {
    /// Reddens the inside when the shell is pried open early.
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

    @Environment(\.shellFinish) private var finish

    var body: some View {
        Canvas { context, size in
            let hinge = CGPoint(x: size.width / 2, y: half == .lid ? size.height : 0)
            let reach = hypot(size.width / 2, size.height) * 1.05
            let ellipse = { (r: CGFloat) -> CGRect in
                CGRect(x: hinge.x - r * 1.3, y: hinge.y - r, width: r * 2.6, height: r * 2)
            }

            // Lighter nacre near the hinge, darkening to the black lip at the outer edge.
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .radialGradient(
                Gradient(colors: [finish.glow, finish.base, finish.lip]),
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
                    let color = finish.sheens[(i + Int(floor(sheen))) % finish.sheens.count]
                    layer.fill(Path(ellipseIn: CGRect(x: c.x - r * 1.3, y: c.y - r, width: r * 2.6, height: r * 2)), with: .color(color.opacity(0.3)))
                }
                // A soft band of sheen following the hinge.
                for i in 0..<4 {
                    let r = reach * (0.18 + 0.2 * CGFloat(i))
                    let color = finish.sheens[(i * 2 + Int(floor(sheen * 2))) % finish.sheens.count]
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
            LipShadow(half: half, color: finish.lip)
        }
        .drawingGroup()
    }
}

/// A soft dark band along the three outer edges of a half, leaving the hinge edge clear.
private struct LipShadow: View {
    var half: NacreSurface.Half
    var color: Color

    var body: some View {
        GeometryReader { geo in
            let band = min(geo.size.width, geo.size.height) * 0.12
            Rectangle()
                .stroke(color.opacity(0.85), lineWidth: band)
                .blur(radius: band * 0.6)
                // Push the hinge edge out of view so only the lip edges darken.
                .frame(width: geo.size.width, height: geo.size.height + band * 3)
                .offset(y: half == .lid ? 0 : -band * 3)
        }
        .clipped()
        .allowsHitTesting(false)
    }
}

/// The outline of one oyster valve: round and broad at the lip, tapering to the hinge, with a ragged edge.
/// The hinge sits at the bottom of the rect for the lid and at the top for the bowl, so two halves meet there.
struct OysterOutline: Shape {
    var hingeAtTop: Bool
    var seed: UInt64
    /// Pulls the outline in evenly, for the nacre inside the rim and the flaky layers of the lip.
    var inset: CGFloat = 0
    /// How ragged the edge is. Oysters grow in thin plates, so the lip is the roughest part.
    var frill: Double = 1

    func path(in rect: CGRect) -> Path {
        var g = SeededGenerator(seed: seed)
        let waves: [(k: Double, amp: Double, phase: Double)] = [(2, 0.03), (3, 0.025), (5, 0.018), (8, 0.012), (13, 0.009), (21, 0.006), (34, 0.004)]
            .map { ($0.0, $0.1, Double.random(in: 0...(2 * .pi), using: &g)) }
        let a = rect.width / 2 - inset, b = rect.height / 2 - inset
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var p = Path()
        let steps = 260
        for i in 0..<steps {
            let t = 2 * Double.pi * Double(i) / Double(steps)
            // A squarish ellipse, so the shell uses the screen.
            var x = copysign(pow(abs(cos(t)), 2 / 3.2), cos(t))
            let y = copysign(pow(abs(sin(t)), 2 / 3.2), sin(t))
            let towardHinge = max(0, hingeAtTop ? -y : y)
            x *= 1 - 0.5 * pow(towardHinge, 2.2)
            let lip = 1 - towardHinge
            let wobble = waves.reduce(0) { $0 + $1.amp * sin($1.k * t + $1.phase) }
            let r = 1 + frill * (0.25 + 0.75 * lip) * wobble
            let pt = CGPoint(x: c.x + x * a * r, y: c.y + y * b * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// One open valve: the rough outer lip, then nacre inside it.
struct ShellValve: View {
    var half: NacreSurface.Half
    var sheen: Double
    var flush: Double

    @Environment(\.shellFinish) private var finish

    var body: some View {
        GeometryReader { geo in
            let rim = min(28, max(4, min(geo.size.width, geo.size.height) * 0.055))
            let hingeAtTop = half == .bowl
            let seed: UInt64 = half == .lid ? 7 : 19
            let outer = OysterOutline(hingeAtTop: hingeAtTop, seed: seed)
            let inner = OysterOutline(hingeAtTop: hingeAtTop, seed: seed, inset: rim, frill: 0.35)
            ZStack {
                outer
                    .fill(finish.dark)
                    .shadow(color: .black.opacity(0.6), radius: rim * 0.6, y: rim * 0.25)
                // Flaky growth plates stepping in from the lip, each a little paler and casting a little shadow.
                ForEach(0..<4) { k in
                    let shade = Double(k) / 3
                    OysterOutline(hingeAtTop: hingeAtTop, seed: seed &+ UInt64(k), inset: rim * CGFloat(k) / 4.5, frill: 1 - 0.2 * Double(k))
                        .fill(LinearGradient(colors: [finish.mid.mix(with: finish.light, by: shade), finish.dark.mix(with: finish.mid, by: shade)],
                                             startPoint: hingeAtTop ? .bottom : .top, endPoint: hingeAtTop ? .top : .bottom))
                        .shadow(color: .black.opacity(0.45), radius: 2, y: hingeAtTop ? -1 : 1)
                }
                NacreSurface(half: half, sheen: sheen, flush: flush)
                    .clipShape(inner)
                inner.stroke(finish.lip.opacity(0.7), lineWidth: min(2, rim * 0.15))
                inner.stroke(Color.white.opacity(0.12), lineWidth: 1).padding(min(2.5, rim * 0.2))
            }
        }
    }
}

enum Shell {
    /// What the oyster is lying on.
    static let seabed = Color(red: 0.03, green: 0.07, blue: 0.10)
}

/// The inside of the clam, split at the screen's middle where the Duo folds.
/// `lid` is laid out in the top half and `bowl` in the bottom half, both inside the safe area,
/// and both pulled in from the sides so they sit inside the shell rather than on its lip.
struct ClamInterior<Lid: View, Bowl: View>: View {
    /// Hinge angle in degrees, 0 shut to 180 flat. Light spills in from the lip as it opens.
    var openDegrees: Double = 180
    var flush: Double = 0
    var gutter: CGFloat = 28
    @ViewBuilder var lid: Lid
    @ViewBuilder var bowl: Bowl

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let insets = geo.safeAreaInsets
            let full = geo.size.height + insets.top + insets.bottom
            // Where the crease falls, measured from the top of the safe area.
            let crease = full / 2 - insets.top
            let side = Self.sideInset(width: geo.size.width + insets.leading + insets.trailing)
            ZStack(alignment: .top) {
                ZStack {
                    RadialGradient(colors: [Color(red: 0.06, green: 0.13, blue: 0.17), Shell.seabed], center: .center, startRadius: 0, endRadius: full * 0.6)
                    TimelineView(.animation(minimumInterval: 1 / 15, paused: reduceMotion)) { timeline in
                        let drift = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate * 0.02
                        let sheen = drift + openDegrees / 60
                        VStack(spacing: 0) {
                            ShellValve(half: .lid, sheen: sheen, flush: flush)
                                .padding([.top, .horizontal], 6)
                            ShellValve(half: .bowl, sheen: sheen + 0.5, flush: flush)
                                .padding([.bottom, .horizontal], 6)
                        }
                    }
                    Ligament()
                    Dimming(openDegrees: openDegrees)
                }
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
                .padding(.horizontal, side)
            }
        }
    }

    /// How far content keeps in from the screen edge to stay off the shell's lip.
    static func sideInset(width: CGFloat) -> CGFloat {
        min(64, max(26, width * 0.07))
    }
}

/// The dark band of ligament holding the two valves together at the fold.
private struct Ligament: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width * 0.3
            Capsule()
                .fill(LinearGradient(colors: [Color(red: 0.22, green: 0.16, blue: 0.14), Color(red: 0.09, green: 0.07, blue: 0.07)], startPoint: .top, endPoint: .bottom))
                .frame(width: w, height: 10)
                .shadow(color: .black.opacity(0.6), radius: 4)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
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

/// The outside of a shut oyster, lying on the seabed. Fills the cover display.
struct ShellExterior: View {
    @Environment(\.shellFinish) private var finish

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                RadialGradient(colors: [Color(red: 0.06, green: 0.13, blue: 0.17), Shell.seabed], center: .center, startRadius: 0, endRadius: max(size.width, size.height) * 0.7)
                ZStack {
                    OysterOutline(hingeAtTop: false, seed: 41, frill: 1.4)
                        .fill(finish.dark)
                        .shadow(color: .black.opacity(0.7), radius: 20, y: 10)
                    ShellPlates()
                        .clipShape(OysterOutline(hingeAtTop: false, seed: 41, frill: 1.4))
                }
                .padding(.horizontal, size.width * 0.05)
                .padding(.vertical, size.height * 0.04)
            }
        }
        .ignoresSafeArea()
    }
}

/// Growth plates on the outside of the shell: ragged layers stacked from the lip in toward the hinge,
/// each one paler and lifted a little off the one below.
private struct ShellPlates: View {
    @Environment(\.shellFinish) private var finish

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                ForEach(1..<7) { k in
                    let d = min(size.width, size.height) * CGFloat(k) * 0.065
                    let shade = Double(k) / 7
                    OysterOutline(hingeAtTop: false, seed: 41 &+ UInt64(k * 3), frill: 1.3 - 0.08 * Double(k))
                        .fill(LinearGradient(colors: [finish.mid.mix(with: finish.light, by: shade), finish.dark.mix(with: finish.mid, by: shade)],
                                             startPoint: .top, endPoint: .bottom))
                        .shadow(color: .black.opacity(0.4), radius: 3, y: 2)
                        // Plates crowd toward the hinge at the bottom.
                        .frame(width: size.width - d * 2, height: size.height - d * 2.2)
                        .position(x: size.width / 2, y: size.height / 2 + d * 1.1)
                }
                // Fine radial texture, barely there.
                Canvas { context, size in
                    let hinge = CGPoint(x: size.width / 2, y: size.height)
                    var g = SeededGenerator(seed: 5)
                    for _ in 0..<70 {
                        let angle = Double.random(in: (Double.pi * 1.05)...(Double.pi * 1.95), using: &g)
                        let len = size.height * .random(in: 0.5...1.1, using: &g)
                        var p = Path()
                        p.move(to: CGPoint(x: hinge.x + cos(angle) * len * 0.1, y: hinge.y + sin(angle) * len * 0.12))
                        p.addLine(to: CGPoint(x: hinge.x + cos(angle) * len * 0.8, y: hinge.y + sin(angle) * len))
                        context.stroke(p, with: .color(.black.opacity(.random(in: 0.04...0.1, using: &g))), lineWidth: .random(in: 1...3, using: &g))
                    }
                }
                .blur(radius: 1.5)
            }
        }
        .overlay(RadialGradient(colors: [.clear, .black.opacity(0.45)], center: UnitPoint(x: 0.45, y: 0.4), startRadius: 60, endRadius: 520))
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
