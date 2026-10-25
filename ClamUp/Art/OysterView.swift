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

                // Bottom shell
                BaseShell()
                    .fill(LinearGradient(colors: [Color(red: 0.62, green: 0.57, blue: 0.53), Color(red: 0.36, green: 0.32, blue: 0.31)], startPoint: .top, endPoint: .bottom))
                    .overlay(BaseRidges().stroke(.black.opacity(0.18), lineWidth: 1.5).clipShape(BaseShell()))
                    .overlay(BaseShell().stroke(Color(red: 0.2, green: 0.17, blue: 0.17), lineWidth: 2.5))
                    .frame(width: w, height: h * 0.5)
                    .offset(y: h * 0.48)

                // Inside of the shell, revealed as the lid lifts
                Ellipse()
                    .fill(RadialGradient(colors: [Theme.nacre, Color(red: 0.70, green: 0.52, blue: 0.64), Color(red: 0.32, green: 0.20, blue: 0.30)], center: .center, startRadius: 0, endRadius: w * 0.45))
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
                    .offset(y: -openAmount * h * 0.42)
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
            LidShell()
                .fill(LinearGradient(colors: [Color(red: 0.84, green: 0.79, blue: 0.72), Color(red: 0.58, green: 0.53, blue: 0.49)], startPoint: .top, endPoint: .bottom))
                .overlay(LidRidges().stroke(.black.opacity(0.16), lineWidth: 1.5).clipShape(LidShell()))
                .overlay(LidShell().stroke(Color(red: 0.2, green: 0.17, blue: 0.17), lineWidth: 2.5))

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
                        .fill(Color(red: 0.08, green: 0.07, blue: 0.1))
                        .frame(width: eyeW * 0.46)
                        .offset(x: effectiveMood == .smug ? (side == 0 ? -eyeW * 0.15 : -eyeW * 0.15) : 0, y: eyeH * 0.38)
                    // Eyelid
                    Rectangle()
                        .fill(Color(red: 0.70, green: 0.65, blue: 0.60))
                        .frame(height: eyeH * lidCover)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Color(red: 0.2, green: 0.17, blue: 0.17)).frame(height: 2)
                        }
                }
                .frame(width: eyeW, height: eyeH)
                .clipShape(Ellipse())
                .overlay(Ellipse().stroke(Color(red: 0.2, green: 0.17, blue: 0.17), lineWidth: 2))
                .overlay(alignment: .top) {
                    if effectiveMood == .annoyed || skin == .grumpy {
                        Capsule()
                            .fill(Color(red: 0.2, green: 0.17, blue: 0.17))
                            .frame(width: eyeW * 1.1, height: 4)
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

struct LidRidges: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let umbo = CGPoint(x: r.midX, y: r.minY + r.height * 0.06)
        for i in 0...12 {
            let t = CGFloat(i) / 12
            p.move(to: umbo)
            p.addLine(to: CGPoint(x: r.minX + r.width * t, y: r.maxY))
        }
        for i in 1...3 {
            let inset = CGFloat(i) * r.height * 0.2
            p.addPath(LidShell().path(in: r.insetBy(dx: inset * 0.9, dy: 0).offsetBy(dx: 0, dy: inset * 0.5)))
        }
        return p
    }
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

struct BaseRidges: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let hinge = CGPoint(x: r.midX, y: r.maxY)
        for i in 0...12 {
            let t = CGFloat(i) / 12
            p.move(to: hinge)
            p.addLine(to: CGPoint(x: r.minX + r.width * t, y: r.minY))
        }
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
