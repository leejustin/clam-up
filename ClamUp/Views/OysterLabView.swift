#if DEBUG
import SwiftUI

/// Generates a batch of improvised lines for one situation, so you can read them all at once and tune the rules.
struct OysterLabView: View {
    enum Scenario: String, CaseIterable, Identifiable {
        case short = "25 min, named task"
        case long = "2 hours, bottle cap #12"
        case early = "Opened early at 6 min"
        case lateNight = "3am, 45 min, streak 5"
        var id: String { rawValue }

        var context: LineContext {
            let cap = Catalog.item("bottlecap")!
            switch self {
            case .short:
                return LineContext(minutes: 25, taskName: "Tax return", totalCompleted: 8)
            case .long:
                return LineContext(minutes: 120, taskName: "Thesis chapter 3", totalCompleted: 40, itemsFound: [cap], itemCounts: ["bottlecap": 12])
            case .early:
                return LineContext(minutes: 6, taskName: "Emails", totalCompleted: 12, completed: false)
            case .lateNight:
                var c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
                c.hour = 3
                return LineContext(minutes: 45, taskName: "", streakDays: 5, totalCompleted: 30, date: Calendar.current.date(from: c) ?? .now)
            }
        }
    }

    struct Attempt: Identifiable {
        let id = UUID()
        let raw: String
        let verdict: Result<String, LineFilter.Rejection>
    }

    @State private var scenario: Scenario = .short
    @State private var attempts: [Attempt] = []
    @State private var running = false
    @State private var handwrittenFailures: [String] = []

    var body: some View {
        List {
            Section {
                Picker("Situation", selection: $scenario) {
                    ForEach(Scenario.allCases) { Text($0.rawValue).tag($0) }
                }
                Button(running ? "Writing…" : "Write 20 lines") { Task { await run() } }
                    .disabled(running || OysterImproviser.status != .available)
                if case .unavailable(let reason) = OysterImproviser.status {
                    Text(reason).foregroundStyle(.secondary)
                }
            } footer: {
                let passed = attempts.filter { if case .success = $0.verdict { true } else { false } }.count
                if !attempts.isEmpty { Text("\(passed) of \(attempts.count) passed the filter.") }
            }

            Section("Results") {
                ForEach(attempts) { attempt in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(attempt.raw).font(Theme.voice(16))
                        switch attempt.verdict {
                        case .success: Text("Passed").font(.caption).foregroundStyle(.green)
                        case .failure(let why): Text("Rejected: \(why.description)").font(.caption).foregroundStyle(.orange)
                        }
                    }
                }
            }

            Section {
                Button("Check handwritten lines") { checkHandwritten() }
                ForEach(handwrittenFailures, id: \.self) { Text($0).font(.caption) }
            } footer: {
                Text("Runs the same filter over every handwritten line, so the pools and the rules agree.")
            }
        }
        .navigationTitle("Oyster lab")
    }

    private func run() async {
        running = true
        attempts = []
        let engine = LineEngine.shared
        for _ in 0..<20 {
            let raw = await OysterImproviser.rawAttempt(scenario.context, examples: engine.voiceExamples()) ?? "(no response)"
            let recent = attempts.compactMap { if case .success(let s) = $0.verdict { s } else { nil } }
            attempts.append(Attempt(raw: raw, verdict: LineFilter.evaluate(raw, recent: recent)))
        }
        running = false
    }

    private func checkHandwritten() {
        let all = LineMoment.allCases.flatMap { LineLibrary.pool($0) } + Catalog.all.flatMap(\.lines)
        handwrittenFailures = all.compactMap { line in
            if case .failure(let why) = LineFilter.evaluate(line.replacingOccurrences(of: "{", with: "").replacingOccurrences(of: "}", with: "")) {
                return "\(why): \(line)"
            }
            return nil
        }
        if handwrittenFailures.isEmpty { handwrittenFailures = ["All handwritten lines pass."] }
    }
}
#endif
