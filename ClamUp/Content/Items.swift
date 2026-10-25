import Foundation

enum Rarity: String, Codable, CaseIterable, Comparable {
    case common, uncommon, rare, legendary, regret

    var label: String {
        switch self {
        case .common: "Common"
        case .uncommon: "Uncommon"
        case .rare: "Rare"
        case .legendary: "Legendary"
        case .regret: "Regret"
        }
    }

    private var order: Int {
        switch self {
        case .common: 0
        case .uncommon: 1
        case .rare: 2
        case .legendary: 3
        case .regret: 4
        }
    }

    static func < (a: Rarity, b: Rarity) -> Bool { a.order < b.order }
}

enum ItemArt: Equatable {
    case emoji(String)
    case bottleCap
    case seaGlass
    case sandyNub
    case halfPearl
    case facePearl
    case discoPearl
}

enum CollectionSet: String, CaseIterable, Codable {
    case junkDrawer, laundry, bathTime, pirate, party, regrets

    var name: String {
        switch self {
        case .junkDrawer: "Junk drawer"
        case .laundry: "Laundry day"
        case .bathTime: "Bath time"
        case .pirate: "Pirate kit"
        case .party: "Afterparty"
        case .regrets: "Every regret"
        }
    }

    var blurb: String {
        switch self {
        case .junkDrawer: "Everything you can't throw away, in one oyster."
        case .laundry: "The dryer and the ocean are connected. Nobody knows how."
        case .bathTime: "Somebody's bathtub drained into the sea."
        case .pirate: "A complete pirate, minus the pirate."
        case .party: "The party ended. The evidence didn't."
        case .regrets: "Collected by opening early. Impressive, in a way."
        }
    }

    var items: [Item] { Catalog.all.filter { $0.set == self } }

    var skin: OysterSkin {
        switch self {
        case .junkDrawer: .junk
        case .laundry: .cozy
        case .bathTime: .bath
        case .pirate: .pirate
        case .party: .disco
        case .regrets: .grumpy
        }
    }
}

enum OysterSkin: String, CaseIterable, Codable, Identifiable {
    case classic, junk, cozy, bath, pirate, disco, grumpy

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: "Classic"
        case .junk: "Bottle cap hat"
        case .cozy: "Sock beanie"
        case .bath: "Duck companion"
        case .pirate: "Eye patch"
        case .disco: "Disco shades"
        case .grumpy: "Permanent frown"
        }
    }

    var unlockedBy: CollectionSet? { CollectionSet.allCases.first { $0.skin == self } }
}

struct Item: Identifiable, Equatable {
    let id: String
    let name: String
    /// Lowercase name used inside sentences, like "bottle cap number 12".
    let countName: String
    let rarity: Rarity
    let art: ItemArt
    let set: CollectionSet?
    let lines: [String]

    static func == (a: Item, b: Item) -> Bool { a.id == b.id }
}

enum Catalog {
    static func item(_ id: String) -> Item? { byID[id] }

    static let byID: [String: Item] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func items(of rarity: Rarity) -> [Item] { all.filter { $0.rarity == rarity } }

    static let all: [Item] = [
        // MARK: Common
        Item(id: "bottlecap", name: "Bottle cap", countName: "bottle cap", rarity: .common, art: .bottleCap, set: .junkDrawer, lines: [
            "Someone in 1987 really enjoyed this soda.",
            "Not a pearl. Technically round, though.",
            "The oyster would like you to know it did not drink the soda.",
            "Twist-off. The oyster respects convenience.",
            "The fizz is long gone. The cap remains. That's life.",
            "Another one for the pile.",
        ]),
        Item(id: "sock", name: "One sock", countName: "sock", rarity: .common, art: .emoji("🧦"), set: .laundry, lines: [
            "The other one is still out there. Searching.",
            "Washed by the ocean. Still smells.",
            "There is no matching one. There never was.",
            "Left foot, probably.",
        ]),
        Item(id: "duck", name: "Rubber duck", countName: "rubber duck", rarity: .common, art: .emoji("🦆"), set: .bathTime, lines: [
            "Lost at sea, found in a mollusk. A survivor.",
            "It squeaks. The oyster has asked it to stop.",
            "Floated here from someone's bathtub. Long commute.",
            "It has seen things. It won't say what.",
        ]),
        Item(id: "puzzle", name: "Puzzle piece", countName: "puzzle piece", rarity: .common, art: .emoji("🧩"), set: nil, lines: [
            "One piece of a 1,000 piece sky.",
            "Someone's puzzle will never be finished. That's on you now.",
            "Edge piece. Somebody needed this.",
        ]),
        Item(id: "ticket", name: "Parking ticket", countName: "parking ticket", rarity: .common, art: .emoji("🎫"), set: nil, lines: [
            "Somehow this is your problem now.",
            "Expired in 2009. Still technically owed.",
            "The oyster doesn't drive. Make of that what you will.",
        ]),
        Item(id: "dentures", name: "Dentures", countName: "set of dentures", rarity: .common, art: .emoji("🦷"), set: nil, lines: [
            "We don't ask questions down here.",
            "Someone is eating soup tonight.",
            "Upper set only. The rest is a mystery.",
        ]),
        Item(id: "fortune", name: "Soggy fortune", countName: "soggy fortune", rarity: .common, art: .emoji("🥠"), set: .party, lines: [
            "It says \"You will\". The rest dissolved.",
            "Lucky numbers: 4, 8, damp.",
            "It's blank. That's probably a fortune too.",
            "It says \"Help, I'm trapped in an oyster.\" Classic.",
        ]),
        Item(id: "battery", name: "AA battery", countName: "battery", rarity: .common, art: .emoji("🔋"), set: .junkDrawer, lines: [
            "Half charged. About the same as the oyster.",
            "Do not lick. The oyster learned this the hard way.",
            "Nobody knows if it works. Nobody ever will.",
        ]),
        Item(id: "paperclip", name: "Paperclip", countName: "paperclip", rarity: .common, art: .emoji("📎"), set: .junkDrawer, lines: [
            "It wants to help. It always wants to help.",
            "Bent into a shape no one can explain.",
            "Holding nothing together. Very relatable.",
        ]),
        Item(id: "key", name: "Mystery key", countName: "mystery key", rarity: .common, art: .emoji("🔑"), set: .junkDrawer, lines: [
            "A key to something. Not this.",
            "Someone is locked out right now. Possibly you.",
            "It opens a door somewhere. The oyster doesn't want to know.",
        ]),
        Item(id: "spoon", name: "Spoon", countName: "spoon", rarity: .common, art: .emoji("🥄"), set: .junkDrawer, lines: [
            "A spoon. It's not clear why.",
            "Silverware goes missing. Now you know where.",
        ]),
        Item(id: "lint", name: "Ball of lint", countName: "ball of lint", rarity: .common, art: .emoji("🧶"), set: .laundry, lines: [
            "From a dryer, somehow. The ocean is very confusing.",
            "Mostly blue fibers. One mystery hair.",
            "Soft. Useless. Weirdly comforting.",
        ]),
        Item(id: "balloon", name: "Tired balloon", countName: "tired balloon", rarity: .common, art: .emoji("🎈"), set: .party, lines: [
            "The party ended somewhere above water.",
            "It still has a little air. It's trying its best.",
        ]),

        // MARK: Uncommon
        Item(id: "bottle", name: "Message in a bottle", countName: "message in a bottle", rarity: .uncommon, art: .emoji("🍾"), set: nil, lines: [
            "It says \"help\". Then, in different handwriting, \"never mind\".",
            "The message is a grocery list. Milk, eggs, a boat.",
            "It's addressed to \"whoever\". That's you.",
        ]),
        Item(id: "seaglass", name: "Sea glass", countName: "piece of sea glass", rarity: .uncommon, art: .seaGlass, set: nil, lines: [
            "It was a bottle once. It got better.",
            "Smoothed by the sea for forty years. You put in a session.",
            "Nice and frosty. The oyster has good taste.",
        ]),
        Item(id: "fish", name: "Startled fish", countName: "startled fish", rarity: .uncommon, art: .emoji("🐟"), set: .bathTime, lines: [
            "This fish was hiding in there. You both look surprised.",
            "It doesn't want to talk about it.",
            "Rent free. The oyster is reconsidering.",
        ]),
        Item(id: "crab", name: "Squatter crab", countName: "squatter crab", rarity: .uncommon, art: .emoji("🦀"), set: .bathTime, lines: [
            "He was here first, technically.",
            "Squatting. The oyster is considering legal action.",
            "He says he's just visiting. He brought a suitcase.",
        ]),
        Item(id: "ring", name: "Wedding ring", countName: "wedding ring", rarity: .uncommon, art: .emoji("💍"), set: nil, lines: [
            "Someone is having a very bad day.",
            "No, the oyster will not be proposing.",
            "Engraved \"forever\". Forever turned out to be shorter.",
        ]),
        Item(id: "sunglasses", name: "Sunglasses", countName: "pair of sunglasses", rarity: .uncommon, art: .emoji("🕶️"), set: .party, lines: [
            "Too cool for the ocean floor. Barely.",
            "Polarized. The oyster is impressed.",
        ]),
        Item(id: "safetypin", name: "Safety pin", countName: "safety pin", rarity: .uncommon, art: .emoji("🧷"), set: .laundry, lines: [
            "Keeping it together. Barely. Like you.",
            "For emergencies. This counts.",
        ]),

        // MARK: Rare
        Item(id: "doubloon", name: "Gold doubloon", countName: "gold doubloon", rarity: .rare, art: .emoji("🪙"), set: .pirate, lines: [
            "Worth exactly zero dollars in this economy.",
            "Spanish, 1714. The oyster has been holding it for a while.",
            "Shiny. Heavy. Completely unspendable.",
        ]),
        Item(id: "map", name: "Treasure map", countName: "treasure map", rarity: .rare, art: .emoji("🗺️"), set: .pirate, lines: [
            "X marks a spot. The spot is this oyster.",
            "Wet, but legible. Mostly.",
        ]),
        Item(id: "compass", name: "Compass", countName: "compass", rarity: .rare, art: .emoji("🧭"), set: .pirate, lines: [
            "Points north. Mostly. The oyster has no opinion.",
            "It spins when you open the shell. Suspicious.",
        ]),
        Item(id: "spyglass", name: "Spyglass", countName: "spyglass", rarity: .rare, art: .emoji("🔭"), set: .pirate, lines: [
            "For looking at things far away. Like your deadlines.",
            "Through it you can see another oyster. It's judging you.",
        ]),
        Item(id: "hook", name: "Pirate hook", countName: "pirate hook", rarity: .rare, art: .emoji("🪝"), set: .pirate, lines: [
            "Belonged to a pirate. He has other problems now.",
            "Someone is having a hard time with zippers today.",
        ]),

        // MARK: Legendary
        Item(id: "discopearl", name: "Disco pearl", countName: "disco pearl", rarity: .legendary, art: .discoPearl, set: .party, lines: [
            "The oyster has been throwing parties without you.",
            "It spins. Nobody knows how.",
        ]),
        Item(id: "facepearl", name: "Pearl with a face", countName: "pearl with a face", rarity: .legendary, art: .facePearl, set: nil, lines: [
            "It's been watching you focus. It approves. Quietly.",
            "Do not name it. You'll get attached.",
        ]),
        Item(id: "trident", name: "Very small trident", countName: "very small trident", rarity: .legendary, art: .emoji("🔱"), set: nil, lines: [
            "Someone important is looking for this.",
            "Poseidon's. He'll want it back. Don't answer the door.",
        ]),
        Item(id: "crown", name: "Tiny crown", countName: "tiny crown", rarity: .legendary, art: .emoji("👑"), set: nil, lines: [
            "Too small for you. Exactly right for the oyster.",
            "Royalty lived here once. The oyster won't elaborate.",
        ]),
        Item(id: "ufo", name: "UFO", countName: "UFO", rarity: .legendary, art: .emoji("🛸"), set: nil, lines: [
            "We don't talk about this one.",
            "The oyster has signed an agreement. It cannot comment.",
        ]),

        // MARK: Regrets (opening early)
        Item(id: "sandynub", name: "Sandy nub", countName: "sandy nub", rarity: .regret, art: .sandyNub, set: .regrets, lines: [
            "This was going to be a pearl. Now it's a regret.",
            "Feel that texture. That's what early feels like.",
        ]),
        Item(id: "iou", name: "Hermit crab IOU", countName: "hermit crab IOU", rarity: .regret, art: .emoji("📝"), set: .regrets, lines: [
            "One pearl, payable never. Signed, the crab.",
            "The crab took your pearl and left this. Legally binding.",
        ]),
        Item(id: "halfpearl", name: "Half a pearl", countName: "half a pearl", rarity: .regret, art: .halfPearl, set: .regrets, lines: [
            "The oyster got halfway. So did you.",
            "It's the thought that counts. The thought was \"I'll just check\".",
        ]),
        Item(id: "receipt", name: "Damp receipt", countName: "damp receipt", rarity: .regret, art: .emoji("🧾"), set: .regrets, lines: [
            "For one pearl. Returned unused.",
            "No refunds. The oyster was very clear about that.",
        ]),
    ]
}
