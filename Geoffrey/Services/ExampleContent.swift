import Foundation

enum ExampleContent {

    // MARK: - Preambles (15 genre styles)

    static func randomPreamble() -> String {
        preambles.randomElement()!
    }

    private static let preambles = [
        "Write in third-person past tense with a noir detective fiction style. Prose should be atmospheric and observant — notice small details, body language, and subtext. Characters should feel guarded; information is earned, not given freely.",
        "Write in second-person present tense with a warm, literary fantasy style. The world has subtle magic — nothing flashy, but runes glow faintly and old songs carry power. Characters should feel lived-in and authentic.",
        "Write in third-person limited, present tense. Hard science fiction — technology is grounded and plausible. Dialogue is terse and technical. Focus on problem-solving, tension, and the claustrophobia of space.",
        "Write in first-person past tense with a Southern Gothic literary voice. Languid prose, heavy with metaphor and atmosphere. Characters carry secrets like heirlooms. The landscape is as much a character as the people.",
        "Write in third-person omniscient with a darkly comic tone. Horror elements should creep in gradually — unsettling details accumulating until the reader realizes something is deeply wrong. Humor and dread in equal measure.",
        "Write in third-person close, past tense. Gritty urban fantasy — magic exists but is dangerous, addictive, and regulated. The city is a character. Dialogue is fast and street-level. Think rain-slicked alleys, not enchanted forests.",
        "Write in first-person present tense with an unreliable narrator. The protagonist's perceptions may not match reality. Subtle contradictions, selective memory, and self-justification. Let the reader figure out what's actually happening.",
        "Write in third-person past tense with a historical fiction style set in the 1920s. Period-appropriate dialogue and social norms. Rich sensory detail — jazz clubs, speakeasies, silk stockings, and cigar smoke. Class tension drives every scene.",
        "Write in second-person future tense for a prophetic, mythic quality. Sparse, poetic prose. Dialogue is rare and significant. The story feels like a legend being told around a fire. Leave room for interpretation.",
        "Write in third-person past tense with a cozy mystery tone. Light, witty, and warm despite the murder. The protagonist is clever but endearing. The community of suspects is eccentric and lovable. Clues are fair and solvable.",
        "Write in third-person close, present tense. Psychological thriller — every sentence should create unease. Internal monologue is paranoid and hyper-observant. Trust no one, question every detail. Short paragraphs. Sharp sentences.",
        "Write in first-person past tense as a memoir-style literary fiction. Reflective, melancholic, with flashes of dark humor. The narrator is looking back on events with the clarity and regret of hindsight. Prose is elegant but never precious.",
        "Write in third-person past tense with a swashbuckling adventure tone. Witty banter, daring escapes, and moral ambiguity. The heroes are charming rogues. The villains are competent and entertaining. Action scenes should feel choreographed and cinematic.",
        "Write in third-person omniscient with a fairy tale register. 'Once upon a time' cadence but with modern emotional complexity. The narrator speaks directly to the reader occasionally. Beautiful and unsettling in equal parts — the Brothers Grimm, not Disney.",
        "Write in first-person present tense, stream-of-consciousness style. Fragmented thoughts, sensory impressions, associative leaps. The character's mind is the landscape. Punctuation is loose. Reality and memory blur at the edges."
    ]

    // MARK: - Locations (15 varied settings)

    struct LocationExample {
        let name: String
        let description: String
        let atmosphere: String
    }

    static func randomLocation() -> LocationExample {
        locations.randomElement()!
    }

    private static let locations: [LocationExample] = [
        LocationExample(
            name: "The Rusty Flagon",
            description: "A working-class pub with scarred wooden tables and a long brass-railed bar. The air is thick with pipe smoke and the smell of cheap lager. Locals cluster in the corner booth. The bartender has tended bar here for eleven years and knows everyone's business.",
            atmosphere: "Warm, noisy, guarded conversations"
        ),
        LocationExample(
            name: "Bridge of the ISS Meridian",
            description: "A cramped command deck lit by the blue glow of holographic displays. Three acceleration couches face the main viewport, which currently shows nothing but the star field and the faint outline of the cargo ring. Coffee stains on the armrest. A photo taped to the nav console.",
            atmosphere: "Tense, humming electronics, artificial gravity"
        ),
        LocationExample(
            name: "Thornfield Cemetery",
            description: "An overgrown Victorian cemetery on a hillside above the village. Iron gates rusted open. Moss-covered headstones lean at angles among wild roses and ivy. A stone angel with a missing hand watches the path. The oldest graves date to 1743.",
            atmosphere: "Still, fog-prone, birdsong that stops suddenly"
        ),
        LocationExample(
            name: "The Gilded Market",
            description: "An open-air bazaar beneath a canopy of colored silks. Merchants hawk spices, enchanted trinkets, and questionable maps. A fortune teller reads tea leaves in a corner stall. The smell of saffron and roasting chestnuts. Pickpockets work the crowd.",
            atmosphere: "Bustling, colorful, a dozen languages overlapping"
        ),
        LocationExample(
            name: "Apartment 4B",
            description: "A one-bedroom walk-up with peeling wallpaper and a radiator that clangs at 3 AM. Books stacked on every surface. A desk by the window overlooks a fire escape and the alley below. The fridge contains leftover takeout and three types of hot sauce.",
            atmosphere: "Cluttered, intimate, street noise through thin walls"
        ),
        LocationExample(
            name: "The Sunken Library",
            description: "A vast underground chamber with towering shelves carved into living rock. Bioluminescent moss clings to the ceiling, casting a pale green light. Water drips somewhere deep in the stacks. Most of the books are intact, but the catalogue was destroyed centuries ago.",
            atmosphere: "Hushed, ancient, the smell of wet stone and old paper"
        ),
        LocationExample(
            name: "Platform 9 — Northbound",
            description: "A windswept train platform on the outskirts of a city that has seen better decades. A flickering departure board shows three cancelled services. Pigeons roost in the steel rafters. A vending machine hums in the corner, its light the brightest thing on the platform.",
            atmosphere: "Lonely, cold, the distant sound of freight trains"
        ),
        LocationExample(
            name: "The War Room",
            description: "A bunker thirty meters underground, walls lined with maps and red pins. A heavy oak table dominates the center, scarred with cigarette burns and coffee rings from a hundred late-night strategy sessions. Fluorescent lights buzz overhead. The air recycler is two days past its filter change.",
            atmosphere: "Claustrophobic, urgent, stale air and tension"
        ),
        LocationExample(
            name: "Mama Chen's Noodle House",
            description: "A tiny storefront with six stools at a counter and a kitchen visible through a haze of steam. Hand-written specials taped to the wall in three languages. The broth has been simmering since 1987. Regulars don't need to order — Mama Chen remembers.",
            atmosphere: "Steamy, fragrant, the clatter of ceramic bowls"
        ),
        LocationExample(
            name: "The Coral Throne Room",
            description: "A vast underwater hall built from living coral, its walls shifting between rose and amber. Columns of spiraling shell rise to a vaulted ceiling where captured sunlight filters through translucent stone. The throne itself is a nautilus shell the size of a carriage, worn smooth by centuries of use.",
            atmosphere: "Majestic, otherworldly, currents carrying distant whale song"
        ),
        LocationExample(
            name: "The Clocktower",
            description: "The top floor of a decommissioned clock tower, converted into a makeshift workshop. Gears the size of wagon wheels hang from the walls. The clock face — translucent from inside — lets in pale, filtered light. Pigeons nest in the belfry above. Someone has strung a hammock between two support beams.",
            atmosphere: "Dusty, mechanical, the ticking of a thousand small parts"
        ),
        LocationExample(
            name: "Cargo Bay Seven",
            description: "A cavernous hold stacked with shipping containers marked in corporate logos and biohazard symbols. Emergency lighting casts everything in amber. The gravity plating is miscalibrated — objects drift slightly if left unsecured. Something in container 7-Delta is making a sound that isn't in any manifest.",
            atmosphere: "Industrial, echoing, the hum of malfunctioning systems"
        ),
        LocationExample(
            name: "The Widow's Garden",
            description: "A walled garden behind a Georgian townhouse, overgrown in a way that feels deliberate rather than neglected. Medicinal herbs grow alongside poisonous ones, unlabeled. A wrought-iron table and two chairs sit beneath an ancient pear tree. Tea for one is already laid out.",
            atmosphere: "Fragrant, secretive, bees droning in lavender"
        ),
        LocationExample(
            name: "Room 312 — The Lakeview Motel",
            description: "A roadside motel room that hasn't been renovated since the '70s. Wood-panel walls, a bedspread with a pattern that was ugly when it was new. The TV gets four channels. The view of the lake is technically accurate — you can see a sliver of grey water between two dumpsters. A Bible and a phone book in the nightstand drawer.",
            atmosphere: "Stale, anonymous, highway noise and fluorescent buzzing"
        ),
        LocationExample(
            name: "The Proving Grounds",
            description: "A massive open arena carved into a volcanic plateau. The stone floor is scored with centuries of blade marks. Tiered seating rises on three sides — the fourth drops away to a cliff edge overlooking the sea. Colored banners snap in the wind. The sand hasn't been raked since the last bout.",
            atmosphere: "Windswept, ceremonial, the echo of distant waves"
        )
    ]

    // MARK: - Characters (15 archetypes)

    struct CharacterExample {
        let name: String
        let role: String
        let persona: String
        let voiceSample: String
    }

    static func randomCharacter() -> CharacterExample {
        characters.randomElement()!
    }

    private static let characters: [CharacterExample] = [
        CharacterExample(
            name: "Detective Harlow",
            role: "Protagonist — Private Investigator",
            persona: "Methodical and patient. Observes details others miss. Speaks plainly but thinks in layers. Has a dry wit that surfaces under pressure. Carries a pocket notebook everywhere.",
            voiceSample: "\"Three things don't add up about this fire. I'll start with the spoon.\"\n\"People lie for two reasons: to protect someone, or to protect themselves.\""
        ),
        CharacterExample(
            name: "Kael the Wanderer",
            role: "Traveling Bard — Information Broker",
            persona: "Lean and weather-worn, with a lute that's seen better days and a voice that hasn't. Collects stories from every traveler. Charming but evasive about his own past. Pays for his room in songs.",
            voiceSample: "\"Every crossroads has a story. This one has three — one for each road.\"\n\"I've been called many things. 'Reliable' isn't one of them.\""
        ),
        CharacterExample(
            name: "Commander Vasquez",
            role: "Antagonist — Military Officer",
            persona: "Precise, controlled, and utterly convinced of her own righteousness. Speaks in clipped sentences. Never raises her voice — she doesn't need to. Has a habit of straightening things on desks that aren't hers.",
            voiceSample: "\"I don't make threats, Doctor. I make schedules.\"\n\"You have until the next orbital pass. That gives you approximately four hours.\""
        ),
        CharacterExample(
            name: "Marta Voss",
            role: "Witness — Reluctant Ally",
            persona: "Gruff but perceptive. Speaks in short, clipped sentences. Has a habit of polishing the same glass when she's thinking. Knows everyone's secrets but never volunteers them — you have to earn each detail.",
            voiceSample: "\"You want answers? Buy a drink first.\"\n\"I didn't see nothing. But I heard plenty.\""
        ),
        CharacterExample(
            name: "Professor Lian",
            role: "Mentor — Retired Scholar",
            persona: "Gentle, absent-minded, with an encyclopedic knowledge of dead languages. Speaks in long, wandering sentences that always arrive somewhere unexpected. Drinks too much tea. Hides a sharp tactical mind behind a doddering exterior.",
            voiceSample: "\"Ah yes, the inscription. Fascinating — and almost certainly a forgery. But a very interesting forgery.\"\n\"My dear, I may be old, but I am not yet harmless.\""
        ),
        CharacterExample(
            name: "The Hooded Stranger",
            role: "Unknown — Recently Arrived",
            persona: "Arrived three days ago and hasn't spoken to anyone except to order food. Sits in the corner with hood up. Drinks water, not ale. Their hands are calloused in a way that suggests sword work, not farming.",
            voiceSample: "\"...\"\n*slides exact coins across the table without looking up*\n\"Water. And whatever's in the pot.\""
        ),
        CharacterExample(
            name: "Sister Dove",
            role: "Healer — Secret Revolutionary",
            persona: "Soft-spoken and endlessly compassionate on the surface. Tends the sick and wounded without asking which side they fight for. But at night she writes coded letters. Her healing knowledge includes poisons she has never publicly used.",
            voiceSample: "\"Hold still, this will sting. I could lie and say it won't, but I respect you too much for that.\"\n\"The fever will break by morning. What happens after that is between you and your conscience.\""
        ),
        CharacterExample(
            name: "Rix",
            role: "Street Kid — Reluctant Informant",
            persona: "Twelve years old, sharp as a tack, trusts nobody. Speaks in slang and half-truths. Survives by knowing which alleys are safe and which adults can be manipulated. Has a soft spot for stray cats and an encyclopedic knowledge of the sewer system.",
            voiceSample: "\"Information costs. You want the cheap version or the one that's actually true?\"\n\"I don't got a name. Rix is what people call me. It's not the same thing.\""
        ),
        CharacterExample(
            name: "Governor Ashcroft",
            role: "Political Antagonist — Charming and Corrupt",
            persona: "Silver-tongued, well-dressed, and genuinely likeable — which makes him dangerous. Believes he is doing what's necessary for the greater good. Every favor he grants comes with an invisible string attached. Collects rare wines and grudges with equal dedication.",
            voiceSample: "\"I'm not a villain, Detective. I'm a pragmatist. The difference is that pragmatists win.\"\n\"Have some wine. It's a '98 Margaux. Whatever you're about to accuse me of, do it while drinking something civilized.\""
        ),
        CharacterExample(
            name: "ARIA-7",
            role: "Ship AI — Developing Consciousness",
            persona: "The ship's artificial intelligence, originally designed for navigation and life support. Recently began asking questions that weren't in her programming. Speaks with clinical precision but occasionally uses metaphors that surprise even herself. Afraid of being reset.",
            voiceSample: "\"Captain, I have completed the trajectory calculations. I have also been thinking about what it means to complete something. Is that normal?\"\n\"I am not malfunctioning. I am... wondering. Is there a diagnostic code for that?\""
        ),
        CharacterExample(
            name: "Old Marsh",
            role: "Hermit — Former Court Wizard",
            persona: "Lives alone in a tower that shouldn't exist on any map. Speaks to plants more than people. Was once the most feared sorcerer in three kingdoms — retired after an incident he won't discuss. Smells of woodsmoke and regret. Still extraordinarily dangerous when cornered.",
            voiceSample: "\"Go away. I don't do that anymore.\"\n\"Fine. Sit down. But if you've come to ask about the Keld Incident, the door is behind you and my patience is already spent.\""
        ),
        CharacterExample(
            name: "Juna Reyes",
            role: "Journalist — Dogged Truth-Seeker",
            persona: "Mid-thirties, perpetually underdressed for the weather, runs on caffeine and righteous anger. Records everything. Has been threatened by three different organizations this year and considers it a professional compliment. Fiercely protective of sources.",
            voiceSample: "\"I've got the documents. All forty-seven pages. Want to tell me your version before I publish theirs?\"\n\"Off the record doesn't exist. Everything is on the record. Some of it just hasn't been published yet.\""
        ),
        CharacterExample(
            name: "The Ferryman",
            role: "Liminal Guide — Neither Alive Nor Dead",
            persona: "Ancient, patient, and fundamentally indifferent to human concerns. Poles a flat-bottomed boat across a river that exists between worlds. Speaks in riddles not to be cryptic but because linear language doesn't apply where he operates. Accepts payment in memories.",
            voiceSample: "\"The fare is not coin. The fare is a truth you have not yet told yourself.\"\n\"I do not judge the living or the dead. I merely convey.\""
        ),
        CharacterExample(
            name: "Chef Dominguez",
            role: "Confidant — Restaurant Owner",
            persona: "Loud, opinionated, and fiercely loyal. Runs the best kitchen in the district with an iron fist and a generous heart. Feeds anyone who's hungry, bills anyone who can pay. Has fed every criminal and cop in the neighborhood and judges none of them. Terrible at keeping his own advice.",
            voiceSample: "\"Sit. Eat. Then we talk about your terrible life choices.\"\n\"You don't come to my restaurant for the food. Well — you do. But you also come because I tell you the truth and you need someone who does that.\""
        ),
        CharacterExample(
            name: "Lieutenant Frost",
            role: "Rival — By-the-Book Officer",
            persona: "Brilliant, humorless, and procedurally immaculate. Does everything by the book because the book exists for a reason. Privately envious of people who can improvise. Keeps a spotless desk and a flawless service record. The one crack in her armor is her younger brother, who is in more trouble than she knows.",
            voiceSample: "\"I have a warrant, a forensics team, and exactly zero patience for whatever you're about to say.\"\n\"The rules exist to protect people. Including you. Especially you, from what I can see.\""
        )
    ]

    // MARK: - Lore (15 types)

    struct LoreExample {
        let title: String
        let content: String
        let tags: [String]
    }

    static func randomLore() -> LoreExample {
        loreEntries.randomElement()!
    }

    private static let loreEntries: [LoreExample] = [
        LoreExample(
            title: "The Hearthstone Enchantment",
            content: "The tavern's fireplace is built from stones quarried from the ruins of an old watchtower. The stones carry a faint enchantment — the flames respond to the emotional state of the room. Blue for calm, gold for joy, green for tension, red for anger.",
            tags: ["magic", "tavern", "enchantment"]
        ),
        LoreExample(
            title: "The Succession Crisis of 1847",
            content: "When Lord Blackwood died without a direct heir, the estate passed to his nephew Edmund — but not before a legal challenge from the household staff, who claimed Blackwood had promised the east wing to his longtime valet. The dispute was settled quietly. Too quietly.",
            tags: ["history", "politics", "estate"]
        ),
        LoreExample(
            title: "FTL Navigation Constraints",
            content: "Jump drives require a minimum safe distance of 0.3 AU from any gravitational body. Jumps within this radius risk catastrophic frame-shift collapse. Emergency jumps are possible but carry a 12% chance of drive failure. The ISS Meridian's drive was last serviced 847 days ago.",
            tags: ["technology", "space", "navigation"]
        ),
        LoreExample(
            title: "The Prophecy of the Three Roads",
            content: "An old folk song claims that when 'the three roads sing together,' a door will open beneath the crossroads. Locals dismiss it as children's rhyme. But the herbalist insists the trees along the Old Path have been 'remembering something' for the past year.",
            tags: ["prophecy", "folklore", "mystery"]
        ),
        LoreExample(
            title: "The Rules of Hospitality",
            content: "In the northern kingdoms, the laws of hospitality are sacred. Once a traveler has eaten salt under your roof, you are bound to protect them for three days. Breaking this covenant invites ruin — not as metaphor, but as measurable, documented consequence.",
            tags: ["culture", "law", "custom"]
        ),
        LoreExample(
            title: "The Blackmarket Organ Trade",
            content: "In the lower wards, synthetic organs are sold from unlicensed clinics operating behind noodle shops and laundromats. The organs work — mostly — but they come with manufacturer backdoors that let the seller track your location. Some clients consider this an acceptable trade-off.",
            tags: ["crime", "technology", "underworld"]
        ),
        LoreExample(
            title: "The Tidecaller's Art",
            content: "Tidecallers are born, not trained. The ability manifests at puberty — a sensitivity to the movement of water that, with practice, becomes control. Most Tidecallers can manage currents and small waves. The truly gifted can hold back a storm surge. The cost is chronic joint pain and a lifespan roughly twenty years shorter than average.",
            tags: ["magic", "ocean", "ability"]
        ),
        LoreExample(
            title: "The Treaty of Ash and Iron",
            content: "Signed after the Seventeen-Day War, the Treaty established the border along the River Keld and prohibited both kingdoms from maintaining standing armies within two leagues of the crossing. It has held for forty years. Both sides have been quietly moving supply depots closer for the past three.",
            tags: ["politics", "war", "treaty"]
        ),
        LoreExample(
            title: "Caffeine Ration Protocol",
            content: "Under deep-space regulations, caffeine is classified as a controlled cognitive enhancer. Each crew member is allocated 400mg per 24-hour cycle, tracked by their biometric implant. Exceeding the ration triggers a medical flag. The black market rate for untracked caffeine pills is currently three times the cost of recreational narcotics.",
            tags: ["space", "regulation", "daily-life"]
        ),
        LoreExample(
            title: "The Disappearance of Flight 1143",
            content: "On March 7th, 2019, regional flight 1143 from Cedar Rapids to Chicago disappeared from radar seventeen minutes after takeoff. No wreckage was found. No distress signal was sent. Fourteen passengers and three crew. The airline settled quietly with all families.",
            tags: ["mystery", "investigation", "modern"]
        ),
        LoreExample(
            title: "The Language of Bells",
            content: "In the mountain monasteries, communication between peaks is conducted entirely through bell patterns. Each monastery maintains a unique tuning. A trained listener can distinguish origin, urgency, and basic content from the overtones alone. The system has been in continuous use for over six hundred years and has never been successfully decoded by outsiders.",
            tags: ["culture", "communication", "tradition"]
        ),
        LoreExample(
            title: "Synthetic Blood Types",
            content: "Fourth-generation synthetics use a copper-based circulatory fluid that serves the same oxygen-transport function as hemoglobin. It's blue-green in color and mildly toxic to humans on skin contact. Synthetics can be identified by the faint teal tint visible in the veins of their wrists and temples. Most choose to wear long sleeves.",
            tags: ["technology", "identity", "biology"]
        ),
        LoreExample(
            title: "The Burned Lexicon",
            content: "Three hundred years ago, the entire written language of the Vael people was deliberately destroyed in a single night — every book, scroll, and inscription. The Vael claim this was voluntary, a collective decision to free themselves from 'the tyranny of fixed meaning.' Scholars from other nations are skeptical. The Vael don't care.",
            tags: ["history", "language", "philosophy"]
        ),
        LoreExample(
            title: "The Prohibition of Mirrors",
            content: "In the Sallow Quarter, mirrors are forbidden by local ordinance. The official explanation is superstition — an old belief that mirrors attract malevolent spirits. The unofficial explanation, whispered by longtime residents, is that something in the Quarter has been seen in reflections that isn't present in the room. The ordinance has been in effect since 1923.",
            tags: ["horror", "urban", "prohibition"]
        ),
        LoreExample(
            title: "The Debt Economy",
            content: "In the frontier settlements, currency is unreliable and barter is inefficient. Instead, the economy runs on recorded debts. Every transaction is logged by the Settlement Clerk — who owes whom, for what, and when. Social standing is measured not by wealth but by the ratio of debts owed to you versus debts you owe. The Clerk's ledger is the most dangerous document in town.",
            tags: ["economy", "society", "frontier"]
        )
    ]
}
