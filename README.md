# Clam Up

A focus timer for iPhone Duo. Close the phone and the oyster starts making a pearl. Keep it shut for the whole session and you get the pearl, plus a chance at something else: a bottle cap, a sock, sometimes a tiny crown. Open it early and the crab takes the pearl.

One payment. No subscription.

## Run it

1. Open `ClamUp.xcodeproj` in Xcode 27.1 or later.
2. Pick the **iPhone Duo** simulator, or a real iPhone Duo.
3. Run. To install on a device, set your team under Signing & Capabilities and change the bundle ID from `com.clamup.ClamUp`.

Run the tests with Product › Test, or:

```bash
xcodebuild -project ClamUp.xcodeproj -scheme ClamUp -destination 'platform=iOS Simulator,name=iPhone Duo' test
```

## Testing the fold

- **Real hinge in the simulator.** Drag the hinge slider in Xcode's Device Hub. The app reads it through `UIHingeInteraction`.
- **Debug buttons.** Debug builds show orange "Debug: close/open the shell" buttons so you can test without a hinge.
- **Phones without a hinge.** The app falls back to on-screen "Clam up" and "Open the shell" buttons with the same rules.
- **Launch arguments**, debug builds only:
  - `-demo armed|cover|prying|early` jumps to that screen.
  - `-demo reveal 2700` runs a finished 45 minute session.
  - `-demo lab` prints 15 improvised lines and the filter's verdict on each.
  - `-seedDemo` fills the tide pool with sample sessions. `-resetAll` wipes everything.
  - `-tab 1` opens the tide pool, and `-poolSection Sets` (or `Pearls`) picks its section. `-notifications NO` and `-improvise NO` turn those settings off.

## How it works

| Area | File |
|---|---|
| Session state machine | `ClamUp/Engine/SessionController.swift` |
| Hinge reading | `ClamUp/Engine/Hinge.swift` |
| Pearls, loot table, streak luck | `ClamUp/Engine/RewardEngine.swift`, `Pearl.swift`, `Streak.swift` |
| Items, sets, unlockable looks | `ClamUp/Content/Items.swift` |
| Every handwritten line | `ClamUp/Content/LineLibrary.swift` |
| Line rotation | `ClamUp/Engine/ShuffleBag.swift`, `LineEngine.swift` |
| On-device AI lines | `ClamUp/Engine/OysterImproviser.swift` |
| The AI-ism filter | `ClamUp/Engine/LineFilter.swift` |

**The phone is the shell.** The Duo's inner screen folds across its middle, so the app draws the inside of a clam there: the lid's mother of pearl on the top half and the bowl on the bottom half, with the real hinge between them. The pearl grows just below the crease. Light spills in from the lip as the hinge opens (`ClamInterior` in `ClamUp/Art/Clam.swift`). Shut, the cover display shows the ribbed outside of the shell. Phones without a hinge get the same split. In debug builds, `-hingeAngle 60` fakes a part-open shell.

**Session rules.** Closing the shell starts the clock. Opening early starts a 6 second countdown, and closing again resumes the session. If the countdown runs out, the session ends with a "regret" item. Losing the hinge signal never counts as opening.

**Rewards.** A finished session always gives a pearl. Longer sessions grow bigger pearls and get more rolls for extras. Streaks change the pearl's color and improve the odds of rare finds. Your first pearl always comes with a bottle cap. Opening early gives one of four regrets, which form their own set.

**Lines.** Each moment has its own pool, dealt like a shuffled deck so nothing repeats until the pool runs out. Some lines react to the task name, the time of day, milestones, or how many bottle caps you own. A few are rare or unlock after 50 sessions.

**Improvised lines.** About one reveal in four asks Apple's on-device model for a line. Every result goes through the same filter as a unit test that checks all handwritten lines. Anything slow, unavailable, or off-voice falls back to a handwritten line. Use **Settings › Debug › Oyster lab** to generate 20 lines at once and see what gets rejected. When a new crutch phrase shows up, add it to the filter.

## Known gaps

- **Background behavior is unconfirmed.** Apple hasn't documented what happens to a running app when the Duo closes. In the simulator, the app moves to the cover display and keeps getting hinge updates. If iOS suspends it on a real device, the session still works: it is saved with its start time and a notification fires when the pearl is ready. One gap remains: if someone opens the phone and uses other apps without returning, the app can't tell when they opened it.
- **Not tested on a physical iPhone Duo.**
- **No Live Activity yet.** A Live Activity on the cover display would keep the timer visible without the app running.
- **Pricing is set in App Store Connect.** A paid-up-front app needs no StoreKit code. Paid oyster looks would need in-app purchases.
