import SwiftUI

enum OysterMood {
    case sleepy, content, annoyed, alarmed, smug
}

/// The oyster. `openAmount` runs from 0 (shut) to 1 (wide open).
struct OysterView: View {
    var openAmount: Double = 0
    var mood: OysterMood = .content
    var skin: OysterSkin = .classic
    var pearl: PearlSpec? = nil
    var breathing = true

    /// How far the lid rises at fully open, as a fraction of the oyster's height.
    static let lift: CGFloat = 0.32

    @State private var breathe = false
    @State private var blink = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, geo.size.height / 0.78)
            let h = w * 0.78
            ZStack(alignment: .top) {
                // Shadow on the sea floor
                Ellipse()
                    .fill(.black.opacity(0.35))
                    .frame(width: w * 0.9, height: h * 0.12)
                    .blur(radius: 8)
                    .offset(y: h * 0.9)

                // The dark inside of the shell, so an open lid reads as hinged rather than floating
                if openAmount > 0.02 {
                    let lidEdge = -openAmount * h * Self.lift + h * 0.533 * (1 - openAmount * 0.25)
                    RoundedRectangle(cornerRadius: w * 0.16)
                        .fill(LinearGradient(colors: [ShellPalette.cavityTop, ShellPalette.cavityBottom], startPoint: .top, endPoint: .bottom))
                        .frame(width: w * 0.8, height: max(0, h * 0.6 - lidEdge + h * 0.04))
                        .offset(y: lidEdge - h * 0.04)
                }

                // Bottom shell
                BaseShell()
                    .fill(LinearGradient(colors: [ShellPalette.baseTop, ShellPalette.baseBottom], startPoint: .top, endPoint: .bottom))
                    .overlay(ShellTexture(ribs: BaseRibs(), rings: false).clipShape(BaseShell()))
                    .overlay(BaseShell().stroke(ShellPalette.outline, lineWidth: max(1.5, w * 0.009)))
                    .frame(width: w, height: h * 0.5)
                    .offset(y: h * 0.48)

                // Inside of the shell, revealed as the lid lifts
                Ellipse()
                    .fill(RadialGradient(colors: [Theme.nacre, Color(red: 0.78, green: 0.62, blue: 0.74), Color(red: 0.40, green: 0.26, blue: 0.38)], center: UnitPoint(x: 0.5, y: 0.4), startRadius: 0, endRadius: w * 0.45))
                    .overlay(Ellipse().fill(AngularGradient(colors: [.pink, .mint, .cyan, .purple, .pink], center: .center)).opacity(0.18).blendMode(.overlay))
                    .frame(width: w * 0.84, height: h * 0.36 * max(0.05, openAmount))
                    .offset(y: h * 0.53 - h * 0.18 * max(0.05, openAmount))
                    .opacity(openAmount > 0.02 ? 1 : 0)

                if let pearl, openAmount > 0.1 {
                    PearlView(spec: pearl, diameter: w * (0.12 + 0.18 * pearl.size))
                        .offset(y: h * 0.53 - w * (0.12 + 0.18 * pearl.size) * 0.85 * openAmount)
                        .scaleEffect(min(1, openAmount * 1.4))
                }

                // Lid, with the face on it
                lid(w: w, h: h)
                    .frame(width: w, height: h * 0.62)
                    .scaleEffect(x: 1, y: 1 - openAmount * 0.25, anchor: .top)
                    .offset(y: -openAmount * h * Self.lift)
                    .rotationEffect(.degrees(-openAmount * 6), anchor: .bottomLeading)
            }
            .frame(width: w, height: h, alignment: .top)
            .scaleEffect(breathing && breathe && !reduceMotion ? 1.018 : 1, anchor: .bottom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .aspectRatio(1 / 0.78, contentMode: .fit)
        .onAppear {
            guard breathing, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { breathe = true }
        }
        .task {
            guard !reduceMotion else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Double.random(in: 2.5...6)))
                withAnimation(.easeIn(duration: 0.07)) { blink = true }
                try? await Task.sleep(for: .seconds(0.13))
                withAnimation(.easeOut(duration: 0.1)) { blink = false }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(openAmount > 0.5 ? "An open oyster" : "A closed oyster")
    }

    @ViewBuilder
    private func lid(w: CGFloat, h: CGFloat) -> some View {
        ZStack {
            // Pearly underside, peeking out below the scallops once the lid lifts
            Ellipse()
                .fill(LinearGradient(colors: [Color(red: 0.55, green: 0.40, blue: 0.52), Theme.nacre], startPoint: .top, endPoint: .bottom))
                .frame(width: w * 0.86, height: h * 0.14 * openAmount)
                .offset(y: h * 0.62 * (0.86 - 0.5))
                .opacity(openAmount > 0.05 ? 1 : 0)

            LidShell()
                .fill(LinearGradient(colors: [ShellPalette.lidTop, ShellPalette.lidMid, ShellPalette.lidEdge], startPoint: .top, endPoint: .bottom))
                .overlay(ShellTexture(ribs: LidRibs(), rings: true).clipShape(LidShell()))
                .overlay(
                    // Soft sheen, like a wet shell under water
                    Ellipse()
                        .fill(.white.opacity(0.32))
                        .frame(width: w * 0.34, height: h * 0.12)
                        .rotationEffect(.degrees(-14))
                        .offset(x: -w * 0.16, y: -h * 0.14)
                        .blur(radius: w * 0.03)
                        .clipShape(LidShell())
                )
                .overlay(LidShell().stroke(ShellPalette.outline, lineWidth: max(1.5, w * 0.009)))

            eyes(w: w)
                .offset(y: h * 0.1)

            accessory(w: w, h: h)
        }
    }

    private var effectiveMood: OysterMood { skin == .grumpy && mood == .content ? .annoyed : mood }

    private var lidCover: CGFloat {
        if blink { return 1 }
        switch effectiveMood {
        case .sleepy: return 0.58
        case .content: return 0.42
        case .annoyed: return 0.5
        case .alarmed: return 0.0
        case .smug: return 0.5
        }
    }

    @ViewBuilder
    private func eyes(w: CGFloat) -> some View {
        let eyeW = w * 0.12, eyeH = w * 0.1
        HStack(spacing: w * 0.13) {
            ForEach(0..<2, id: \.self) { side in
                ZStack(alignment: .top) {
                    Ellipse().fill(.white)
                    Circle()
                        .fill(Color(red: 0.10, green: 0.08, blue: 0.12))
                        .overlay(alignment: .topTrailing) {
                            Circle().fill(.white.opacity(0.9)).frame(width: eyeW * 0.14).offset(x: -eyeW * 0.06, y: eyeW * 0.06)
                        }
                        .frame(width: eyeW * 0.5)
                        .offset(x: effectiveMood == .smug ? -eyeW * 0.15 : 0, y: eyeH * 0.34)
                    // Eyelid
                    Rectangle()
                        .fill(ShellPalette.eyelid)
                        .frame(height: eyeH * lidCover)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(ShellPalette.outline).frame(height: max(1.5, w * 0.008))
                        }
                }
                .frame(width: eyeW, height: eyeH)
                .clipShape(Ellipse())
                .overlay(Ellipse().stroke(ShellPalette.outline, lineWidth: max(1.5, w * 0.008)))
                .background(alignment: .bottom) {
                    // Cheeks
                    Ellipse()
                        .fill(Color(red: 0.96, green: 0.56, blue: 0.56).opacity(effectiveMood == .alarmed ? 0.5 : 0.32))
                        .frame(width: eyeW * 0.9, height: eyeH * 0.42)
                        .blur(radius: eyeW * 0.08)
                        .offset(x: side == 0 ? -eyeW * 0.3 : eyeW * 0.3, y: eyeH * 0.62)
                }
                .overlay(alignment: .top) {
                    if effectiveMood == .annoyed || skin == .grumpy {
                        Capsule()
                            .fill(ShellPalette.outline)
                            .frame(width: eyeW * 1.1, height: max(3, w * 0.016))
                            .rotationEffect(.degrees(side == 0 ? 14 : -14))
                            .offset(y: -eyeH * 0.35)
                    }
                }
                .overlay {
                    if skin == .pirate, side == 0 {
                        Ellipse().fill(Color(red: 0.08, green: 0.07, blue: 0.08)).frame(width: eyeW * 1.15, height: eyeH * 1.15)
                    }
                }
            }
        }
        .overlay {
            if skin == .pirate {
                Capsule().fill(Color(red: 0.08, green: 0.07, blue: 0.08))
                    .frame(width: w * 0.62, height: 3)
                    .rotationEffect(.degrees(-16))
                    .offset(x: -w * 0.02, y: -eyeH * 0.2)
            }
            if skin == .disco {
                Text("🕶️").font(.system(size: w * 0.26)).offset(y: -eyeH * 0.05)
            }
        }
    }

    @ViewBuilder
    private func accessory(w: CGFloat, h: CGFloat) -> some View {
        switch skin {
        case .junk:
            BottleCapArt(size: w * 0.2).rotationEffect(.degrees(14)).offset(x: w * 0.05, y: -h * 0.27)
        case .cozy:
            Text("🧦").font(.system(size: w * 0.2)).rotationEffect(.degrees(-35)).offset(x: -w * 0.08, y: -h * 0.27)
        case .bath:
            Text("🦆").font(.system(size: w * 0.18)).offset(x: w * 0.18, y: -h * 0.24)
        case .disco:
            Text("✨").font(.system(size: w * 0.12)).offset(x: w * 0.32, y: -h * 0.14)
        default:
            EmptyView()
        }
    }
}

// MARK: Shell shapes

/// Domed top, scalloped bottom edge.
struct LidShell: Shape {
    var scallops = 7

    func path(in r: CGRect) -> Path {
        var p = Path()
        let edgeY = r.minY + r.height * 0.86
        p.move(to: CGPoint(x: r.minX + r.width * 0.02, y: edgeY))
        p.addCurve(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.04),
                   control1: CGPoint(x: r.minX - r.width * 0.02, y: r.minY + r.height * 0.35),
                   control2: CGPoint(x: r.minX + r.width * 0.22, y: r.minY))
        p.addCurve(to: CGPoint(x: r.maxX - r.width * 0.02, y: edgeY),
                   control1: CGPoint(x: r.maxX - r.width * 0.22, y: r.minY),
                   control2: CGPoint(x: r.maxX + r.width * 0.02, y: r.minY + r.height * 0.35))
        let step = (r.width * 0.96) / CGFloat(scallops)
        for i in 0..<scallops {
            let x0 = r.maxX - r.width * 0.02 - step * CGFloat(i)
            let x1 = x0 - step
            p.addQuadCurve(to: CGPoint(x: x1, y: edgeY), control: CGPoint(x: (x0 + x1) / 2, y: r.maxY + r.height * 0.02))
        }
        p.closeSubpath()
        return p
    }
}

/// Fan ribs radiating from the top of the lid, bowed outward like a real shell.
struct LidRibs: Shape {
    var count = 11

    func path(in r: CGRect) -> Path {
        var p = Path()
        let umbo = CGPoint(x: r.midX, y: r.minY + r.height * 0.05)
        for i in 1..<count {
            let t = CGFloat(i) / CGFloat(count)
            let end = CGPoint(x: r.minX + r.width * (0.02 + 0.96 * t), y: r.minY + r.height * 0.9)
            let bow = (t - 0.5) * r.width * 0.22
            p.move(to: umbo)
            p.addQuadCurve(to: end, control: CGPoint(x: (umbo.x + end.x) / 2 + bow, y: r.minY + r.height * 0.42))
        }
        return p
    }
}

/// Growth rings: shrinking copies of the lid outline, all meeting near the top.
struct LidRings: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        for i in 1...3 {
            let k = 1 - CGFloat(i) * 0.2
            let rect = CGRect(x: r.midX - r.width * k / 2, y: r.minY + r.height * 0.04 * CGFloat(i), width: r.width * k, height: r.height * k)
            p.addPath(LidShell().path(in: rect))
        }
        return p
    }
}

struct BaseRibs: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let hinge = CGPoint(x: r.midX, y: r.maxY)
        for i in 1..<11 {
            let t = CGFloat(i) / 11
            let end = CGPoint(x: r.minX + r.width * (0.02 + 0.96 * t), y: r.minY)
            let bow = (t - 0.5) * r.width * 0.2
            p.move(to: hinge)
            p.addQuadCurve(to: end, control: CGPoint(x: (hinge.x + end.x) / 2 + bow, y: r.midY))
        }
        return p
    }
}

/// Embossed ribs: a dark groove with a light edge beside it.
private struct ShellTexture<Ribs: Shape>: View {
    var ribs: Ribs
    var rings: Bool

    var body: some View {
        GeometryReader { geo in
            let lw = max(1, geo.size.width * 0.006)
            ZStack {
                ribs.stroke(.black.opacity(0.13), lineWidth: lw * 1.4)
                ribs.stroke(.white.opacity(0.16), lineWidth: lw).offset(x: lw * 1.4)
                if rings {
                    LidRings().stroke(.black.opacity(0.08), lineWidth: lw)
                    LidRings().stroke(.white.opacity(0.10), lineWidth: lw).offset(y: lw * 1.2)
                }
            }
        }
    }
}

enum ShellPalette {
    static let lidTop = Color(red: 0.93, green: 0.88, blue: 0.80)
    static let lidMid = Color(red: 0.80, green: 0.72, blue: 0.64)
    static let lidEdge = Color(red: 0.62, green: 0.53, blue: 0.48)
    static let baseTop = Color(red: 0.66, green: 0.57, blue: 0.52)
    static let baseBottom = Color(red: 0.42, green: 0.35, blue: 0.34)
    static let eyelid = Color(red: 0.75, green: 0.66, blue: 0.59)
    static let outline = Color(red: 0.30, green: 0.23, blue: 0.23)
    static let cavityTop = Color(red: 0.10, green: 0.06, blue: 0.11)
    static let cavityBottom = Color(red: 0.30, green: 0.19, blue: 0.28)
}

/// Scalloped top edge, rounded bowl underneath.
struct BaseShell: Shape {
    var scallops = 7

    func path(in r: CGRect) -> Path {
        var p = Path()
        let edgeY = r.minY + r.height * 0.12
        let left = CGPoint(x: r.minX + r.width * 0.02, y: edgeY)
        p.move(to: left)
        let step = (r.width * 0.96) / CGFloat(scallops)
        for i in 0..<scallops {
            let x0 = left.x + step * CGFloat(i)
            let x1 = x0 + step
            p.addQuadCurve(to: CGPoint(x: x1, y: edgeY), control: CGPoint(x: (x0 + x1) / 2, y: r.minY - r.height * 0.04))
        }
        p.addCurve(to: CGPoint(x: r.midX, y: r.maxY),
                   control1: CGPoint(x: r.maxX + r.width * 0.02, y: r.minY + r.height * 0.7),
                   control2: CGPoint(x: r.maxX - r.width * 0.25, y: r.maxY))
        p.addCurve(to: left,
                   control1: CGPoint(x: r.minX + r.width * 0.25, y: r.maxY),
                   control2: CGPoint(x: r.minX - r.width * 0.02, y: r.minY + r.height * 0.7))
        p.closeSubpath()
        return p
    }
}

#Preview("Oyster") {
    ZStack {
        OceanBackground()
        VStack(spacing: 40) {
            OysterView(openAmount: 0, mood: .sleepy, skin: .pirate).frame(width: 220)
            OysterView(openAmount: 0.8, mood: .alarmed, pearl: PearlSpec(size: 0.7, color: .gold, hueJitter: 0.2, grade: .round)).frame(width: 220)
        }
    }
}
