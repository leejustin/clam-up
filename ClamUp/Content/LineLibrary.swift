import Foundation

/// Each moment in the app has its own pool. Placeholders in braces are filled in by `LineEngine`.
enum LineMoment: String, CaseIterable {
    case idle, armed, cover, ready, prying, early
    case completeShort, completeMedium, completeLong, firstEver
    case streakStart, streakContinue, streakBroken
    case lateNight, earlyMorning, taskNamed
    case notification, secret, veteran
}

enum LineLibrary {
    static func pool(_ moment: LineMoment) -> [String] {
        switch moment {
        case .idle: idle
        case .armed: armed
        case .cover: cover
        case .ready: ready
        case .prying: prying
        case .early: early
        case .completeShort: completeShort
        case .completeMedium: completeMedium
        case .completeLong: completeLong
        case .firstEver: firstEver
        case .streakStart: streakStart
        case .streakContinue: streakContinue
        case .streakBroken: streakBroken
        case .lateNight: lateNight
        case .earlyMorning: earlyMorning
        case .taskNamed: taskNamed
        case .notification: notification
        case .secret: secret
        case .veteran: veteran
        }
    }

    static let idle = [
        "I'm an oyster. I make pearls when you focus. That's the whole thing.",
        "Pick a task, close the shell, get a pearl. Maybe a bottle cap.",
        "Ready when you are. I'm always ready. I'm an oyster.",
        "Your oyster is bored. It wants to make you something.",
        "I've been sitting here doing nothing. Like an oyster.",
        "Shall we? I'm not going anywhere either way.",
        "Today is a good day for a pearl. Most days are.",
        "Tell me what you're working on. I won't tell anyone.",
        "The tide is in. The oyster is available.",
        "I've been told I'm a very good listener. I have no ears.",
        "Got something to do? I've got something to make.",
        "You focus, I clench. It's a partnership.",
    ]

    static let armed = [
        "I'll be in here. Making something. Don't peek.",
        "Close me when you're ready. I'll handle the rest.",
        "Go on. Shut the shell. I work better in the dark.",
        "Fold me up. I'll start on the pearl.",
        "Close it. Nobody makes pearls with an audience.",
        "I can't work while you're watching. Close the shell.",
        "Closing the phone is the whole trick. Sorry it's not more complicated.",
        "The pearl starts when the shell shuts. That's the deal.",
        "Shell shut, phone down, brain on. In that order.",
        "I've cleared my schedule. It was already clear.",
        "I'm going to need total privacy for this.",
        "Please close the shell. It's drafty.",
        "I don't do anything until you close me. That's my whole personality.",
        "Close up. I'll let you know when there's something worth seeing.",
        "Shut the lid and go be productive somewhere else.",
    ]

    static let cover = [
        "Working. Don't look at me.",
        "Pearl in progress.",
        "Still here. Still clenching.",
        "Nothing to see. That's the point.",
        "Shhh.",
        "Busy.",
        "The oyster is concentrating. So should you.",
        "Do not disturb. I mean it.",
        "Growing slowly. Like all good things and most bad ones.",
        "You looked. That's fine. Don't open it.",
        "This is the boring part. Stay with it.",
        "Layer by layer.",
        "I can feel you checking on me.",
        "Go back to work. I'll be here.",
        "Pearls aren't fast. Neither is anything worth doing.",
    ]

    static let ready = [
        "Done. Open me.",
        "It's ready. Come see.",
        "Finished. That's all I'll say out here.",
        "Something's in here. Open up.",
        "Pearl's done. Your move.",
        "Ready. I'd like my privacy back now.",
    ]

    static let prying = [
        "Close me. Now.",
        "Rude. I was in the middle of something.",
        "Put that back.",
        "You're letting the water out.",
        "Not yet. Close it.",
        "I said don't peek.",
        "This is a closed shell operation.",
        "Shut it and I'll pretend this didn't happen.",
        "Close it and we never speak of this.",
        "The pearl is not ready to be perceived.",
        "Hey. Hands off the shell.",
        "I can see you. Close it.",
        "Bad time. Close the shell.",
        "Absolutely not. Shut it.",
        "Close it before the crab notices.",
    ]

    static let early = [
        "You opened me early. The crab took the pearl.",
        "That's a sandy nub. That's what early gets you.",
        "It's fine. I'm a bivalve, I don't have feelings. Technically.",
        "The crab says thanks.",
        "Next time, maybe keep me closed. Just an idea.",
        "I was almost done. Almost is doing a lot of work there.",
        "I'll start over. I'm used to it.",
        "You peeked. Pearls hate that.",
        "No pearl. But you did get some sand.",
        "Opening early is a choice. You made it.",
        "That was a short one. Shorter than we agreed.",
        "The pearl went back to being sand. It seemed relieved.",
        "I'm not mad. I'm just going to sit here quietly.",
        "We had a deal. The deal was closed.",
        "Okay. I'll be here when you want to try again.",
        "That's not a pearl. That's a rough draft.",
        "Something came up. It always does.",
    ]

    static let completeShort = [
        "Short and sweet. Mostly short.",
        "A small pearl for a small effort. Very fair.",
        "Quick one. The oyster barely broke a sweat. Oysters can't sweat.",
        "Not the biggest pearl. Still a pearl.",
        "You came back. I made you this.",
        "Here. It's a pearl. Don't make it weird.",
        "Done. You did your part, I did mine.",
        "Look at that. Round, mostly.",
        "A fresh pearl. Don't eat it.",
        "Time well spent. Or at least spent.",
        "That's a pearl. You earned it, apparently.",
        "Done. The oyster has nothing more to say. That's a compliment.",
        "{minutes} minutes. The oyster has made worse pearls in more time.",
        "Small, but it counts. The oyster checked.",
    ]

    static let completeMedium = [
        "A real pearl. The oyster is quietly impressed.",
        "That took a while. So did the pearl.",
        "Solid work. The oyster would nod if it had a neck.",
        "You stayed. The pearl noticed.",
        "Decent size. The oyster won't brag. You can.",
        "This one has some weight to it.",
        "The oyster put real effort in. Don't tell anyone.",
        "Nice and round. Like a good day.",
        "Look at the shine on that. You did that. Sort of.",
        "{minutes} minutes of focus. The oyster is updating its opinion of you.",
        "Good pearl. Good focus. Good grief, that was long.",
        "That's a keeper. They're all keepers, but still.",
    ]

    static let completeLong = [
        "I've been clenching for {minutes} minutes. Take your pearl and go.",
        "That's a big one. The oyster needs to lie down.",
        "A whopper. The oyster is exhausted. Worth it.",
        "You went the distance. The oyster went nowhere, but still.",
        "This pearl has its own gravity.",
        "{minutes} minutes. The oyster is filing for overtime.",
        "Huge pearl. Huge effort. The oyster is going to nap.",
        "The oyster has never made anything this large. It's emotional. Internally.",
        "That was a marathon. The oyster's jaw hurts.",
        "Deep focus. Deep oyster. Big pearl.",
    ]

    static let firstEver = [
        "Your first pearl. The oyster didn't think you'd make it. Pleasant surprise.",
        "First one. They don't get easier, but they do get bigger.",
        "Pearl number one. The beginning of a very small empire.",
    ]

    static let streakStart = [
        "Day one. The oyster doesn't judge how many day ones you've had.",
        "A new streak. Fragile, like most new things.",
        "Day one. Come back tomorrow and it becomes a habit.",
    ]

    static let streakContinue = [
        "Day {days}. The oyster has started expecting you.",
        "{days} days straight. Suspiciously consistent.",
        "{days} days in a row. The pearls are getting fancier.",
        "Day {days}. You're becoming a regular.",
        "{days} day streak. The oyster told its friends. It has no friends.",
        "Day {days}. The oyster cleared space on the shelf.",
    ]

    static let streakBroken = [
        "The streak is gone. The oyster lit a very small candle.",
        "You missed a day. The oyster noticed. It's not saying anything.",
        "The streak ended. The oyster is starting a new one out of spite.",
    ]

    static let lateNight = [
        "Focusing at {time}? The oyster respects it. The oyster is also concerned.",
        "It's {time}. Even the fish went to bed.",
        "Nothing good happens after 2am. Except, apparently, this pearl.",
        "A midnight pearl. Darker than usual. That might be the lighting.",
    ]

    static let earlyMorning = [
        "Up before the sun. The oyster didn't know that was allowed.",
        "It's {time}. The tide isn't even up yet.",
        "An early pearl. The oyster hasn't had its plankton.",
    ]

    static let taskNamed = [
        "This pearl grew around \"{task}\". It's a little lumpy. Seems right.",
        "\"{task}\", pearl edition. The oyster did its part.",
        "The oyster doesn't know what \"{task}\" is. It made a pearl anyway.",
        "Filed under \"{task}\". The oyster keeps meticulous records.",
        "One pearl, made of pure \"{task}\". Don't ask how.",
    ]

    static let notification = [
        "Your pearl is ready. Open the shell.",
        "Done. Something's in here.",
        "Pearl's finished. Come take a look.",
        "The oyster is done. You can open it now.",
        "Ready. The oyster would like its privacy back.",
        "Time's up. Open up.",
        "There's something in the shell. It might be a pearl. It might be a sock.",
    ]

    static let secret = [
        "The oyster has a secret. It likes you. Don't bring it up.",
        "Between us, the bottle caps were a test.",
        "The oyster sometimes hums when you're not around.",
        "This is a rare line. You're not supposed to see this one.",
        "The crab and the oyster aren't speaking. It's a long story.",
    ]

    static let veteran = [
        "We've done this a lot. The oyster feels like it knows you now.",
        "You keep coming back. The oyster keeps making pearls. It works.",
        "At this point the pearls are just a formality.",
        "The oyster has started telling the other oysters about you.",
        "Another one. The oyster has stopped counting. The app hasn't.",
    ]

    /// Milestone lines keyed by the total number of completed sessions.
    static let milestones: [Int: String] = [
        10: "Ten pearls. The oyster is starting to feel like a business.",
        25: "Twenty five pearls. The oyster has hired nobody. It does everything itself.",
        50: "Fifty pearls. The oyster would like a raise.",
        100: "One hundred pearls. The oyster has been informed this is a lot.",
        250: "Two hundred fifty pearls. The ocean is running low.",
        500: "Five hundred pearls. The oyster is writing a memoir.",
    ]
}
