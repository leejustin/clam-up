import SwiftUI

struct PearlView: View {
    var spec: PearlSpec
    var diameter: CGFloat

    private var palette: (highlight: Color, base: Color, shadow: Color) {
        switch spec.color {
        case .white: (Color(white: 1), Color(red: 0.93, green: 0.93, blue: 0.95), Color(red: 0.66, green: 0.68, blue: 0.78))
        case .cream: (Color(red: 1, green: 0.99, blue: 0.94), Color(red: 0.96, green: 0.90, blue: 0.78), Color(red: 0.74, green: 0.65, blue: 0.52))
        case .rose: (Color(red: 1, green: 0.95, blue: 0.96), Color(red: 0.96, green: 0.80, blue: 0.84), Color(red: 0.76, green: 0.55, blue: 0.64))
        case .silver: (Color(white: 1), Color(red: 0.80, green: 0.84, blue: 0.90), Color(red: 0.48, green: 0.52, blue: 0.62))
        case .gold: (Color(red: 1, green: 0.97, blue: 0.82), Color(red: 0.93, green: 0.77, blue: 0.40), Color(red: 0.60, green: 0.43, blue: 0.14))
        case .black: (Color(red: 0.72, green: 0.76, blue: 0.84), Color(red: 0.22, green: 0.25, blue: 0.31), Color(red: 0.05, green: 0.05, blue: 0.09))
        }
    }

    var body: some View {
        let p = palette
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [p.highlight, p.base, p.shadow], center: UnitPoint(x: 0.36, y: 0.3),
                                     startRadius: 0, endRadius: diameter * 0.78))
            Circle()
                .fill(AngularGradient(colors: [.pink, .mint, .purple, .cyan, .pink], center: .center))
                .opacity(spec.color == .black ? 0.32 : 0.16)
                .blendMode(.overlay)
            Ellipse()
                .fill(.white.opacity(0.85))
                .frame(width: diameter * 0.26, height: diameter * 0.17)
                .rotationEffect(.degrees(-30))
                .offset(x: -diameter * 0.17, y: -diameter * 0.2)
                .blur(radius: diameter * 0.02)
            Circle().stroke(p.shadow.opacity(0.35), lineWidth: max(0.5, diameter * 0.015))
        }
        .frame(width: diameter, height: diameter)
        .hueRotation(.degrees(spec.hueJitter * 10))
        .shadow(color: .black.opacity(0.35), radius: diameter * 0.08, y: diameter * 0.06)
        .accessibilityLabel(spec.title)
    }
}

/// Draws any catalog item. `silhouette` hides undiscovered items.
struct ItemArtView: View {
    var item: Item
    var size: CGFloat
    var silhouette = false

    var body: some View {
        art
            .frame(width: size, height: size)
            .modifier(SilhouetteModifier(on: silhouette))
            .accessibilityLabel(silhouette ? "Undiscovered" : item.name)
    }

    @ViewBuilder
    private var art: some View {
        switch item.art {
        case .emoji(let e):
            Text(e).font(.system(size: size * 0.7))
        case .bottleCap:
            BottleCapArt(size: size * 0.82)
        case .seaGlass:
            SeaGlassArt(size: size * 0.8)
        case .sandyNub:
            SandyNubArt(size: size * 0.7)
        case .halfPearl:
            PearlView(spec: PearlSpec(size: 0.5, color: .white, hueJitter: 0.1, grade: .seed), diameter: size * 0.7)
                .mask(alignment: .leading) { JaggedHalf().frame(width: size * 0.7, height: size * 0.7) }
        case .facePearl:
            ZStack {
                PearlView(spec: PearlSpec(size: 0.6, color: .rose, hueJitter: 0, grade: .round), diameter: size * 0.72)
                HStack(spacing: size * 0.12) {
                    Circle().frame(width: size * 0.06)
                    Circle().frame(width: size * 0.06)
                }
                .foregroundStyle(Color(red: 0.25, green: 0.15, blue: 0.2))
                .offset(y: -size * 0.02)
                SmileArc().stroke(Color(red: 0.25, green: 0.15, blue: 0.2), style: .init(lineWidth: size * 0.025, lineCap: .round))
                    .frame(width: size * 0.14, height: size * 0.05)
                    .offset(y: size * 0.09)
            }
        case .discoPearl:
            DiscoPearlArt(size: size * 0.74)
        }
    }
}

private struct SilhouetteModifier: ViewModifier {
    var on: Bool
    func body(content: Content) -> some View {
        if on {
            content.saturation(0).brightness(-1).opacity(0.45)
        } else {
            content
        }
    }
}

struct BottleCapArt: View {
    var size: CGFloat

    var body: some View {
        ZStack {
            StarPolygon(points: 21, innerRatio: 0.88)
                .fill(LinearGradient(colors: [Color(red: 0.95, green: 0.32, blue: 0.28), Color(red: 0.62, green: 0.1, blue: 0.12)], startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .fill(RadialGradient(colors: [Color(red: 0.92, green: 0.28, blue: 0.25), Color(red: 0.7, green: 0.12, blue: 0.14)], center: .center, startRadius: 0, endRadius: size * 0.4))
                .padding(size * 0.12)
            Text("FIZZ")
                .font(.system(size: size * 0.2, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.92))
                .rotationEffect(.degrees(-12))
        }
        .frame(width: size, height: size)
        .shadow(color: .black.opacity(0.3), radius: 2, y: 2)
    }
}

struct SeaGlassArt: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            Blob(seed: 3)
                .fill(Color(red: 0.45, green: 0.85, blue: 0.75).opacity(0.75))
            Blob(seed: 3)
                .stroke(.white.opacity(0.4), lineWidth: 1.5)
            Ellipse().fill(.white.opacity(0.45)).frame(width: size * 0.28, height: size * 0.12)
                .rotationEffect(.degrees(-25)).offset(x: -size * 0.12, y: -size * 0.14).blur(radius: 2)
        }
        .frame(width: size, height: size * 0.8)
    }
}

struct SandyNubArt: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            Blob(seed: 11)
                .fill(RadialGradient(colors: [Color(red: 0.78, green: 0.72, blue: 0.62), Color(red: 0.48, green: 0.43, blue: 0.38)], center: UnitPoint(x: 0.4, y: 0.35), startRadius: 0, endRadius: size * 0.6))
            Canvas { context, s in
                var g = SeededGenerator(seed: 42)
                for _ in 0..<26 {
                    let x = Double.random(in: 0.2...0.8, using: &g) * s.width
                    let y = Double.random(in: 0.25...0.75, using: &g) * s.height
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)), with: .color(.black.opacity(0.25)))
                }
            }
        }
        .frame(width: size, height: size * 0.85)
    }
}

struct DiscoPearlArt: View {
    var size: CGFloat
    var body: some View {
        ZStack {
            Canvas { context, s in
                let tile = s.width / 9
                var g = SeededGenerator(seed: 7)
                context.clip(to: Path(ellipseIn: CGRect(origin: .zero, size: s)))
                for row in 0..<10 {
                    for col in 0..<10 {
                        let rect = CGRect(x: CGFloat(col) * tile, y: CGFloat(row) * tile, width: tile - 1, height: tile - 1)
                        let shade = Double.random(in: 0.45...1, using: &g)
                        context.fill(Path(rect), with: .color(Color(white: shade)))
                    }
                }
            }
            Circle().fill(RadialGradient(colors: [.clear, .black.opacity(0.45)], center: UnitPoint(x: 0.38, y: 0.32), startRadius: size * 0.1, endRadius: size * 0.6))
            Circle().fill(AngularGradient(colors: [.pink, .yellow, .cyan, .purple, .pink], center: .center)).opacity(0.25).blendMode(.overlay)
            Text("✨").font(.system(size: size * 0.3)).offset(x: size * 0.36, y: -size * 0.36)
        }
        .frame(width: size, height: size)
    }
}

struct StarPolygon: Shape {
    var points: Int
    var innerRatio: CGFloat

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * innerRatio
        var p = Path()
        for i in 0..<(points * 2) {
            let angle = CGFloat(i) * .pi / CGFloat(points) - .pi / 2
            let r = i.isMultiple(of: 2) ? outer : inner
            let pt = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// A lumpy rounded shape, stable for a given seed.
struct Blob: Shape {
    var seed: UInt64
    func path(in rect: CGRect) -> Path {
        var g = SeededGenerator(seed: seed)
        let n = 7
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let pts: [CGPoint] = (0..<n).map { i in
            let a = CGFloat(i) / CGFloat(n) * 2 * .pi
            let r = CGFloat(Double.random(in: 0.78...1, using: &g))
            return CGPoint(x: center.x + cos(a) * rect.width / 2 * r, y: center.y + sin(a) * rect.height / 2 * r)
        }
        var p = Path()
        let mid = { (a: CGPoint, b: CGPoint) in CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2) }
        p.move(to: mid(pts[n - 1], pts[0]))
        for i in 0..<n {
            p.addQuadCurve(to: mid(pts[i], pts[(i + 1) % n]), control: pts[i])
        }
        p.closeSubpath()
        return p
    }
}

private struct JaggedHalf: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + r.width * 0.04, y: r.minY))
        let steps = 8
        for i in 1...steps {
            let y = r.minY + r.height * CGFloat(i) / CGFloat(steps)
            let x = r.midX + (i.isMultiple(of: 2) ? r.width * 0.05 : -r.width * 0.05)
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct SmileArc: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 1.6))
        return p
    }
}

#Preview("Items") {
    ZStack {
        OceanBackground()
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
            ForEach(Catalog.all) { item in
                ItemArtView(item: item, size: 60)
            }
        }
        .padding()
    }
}
