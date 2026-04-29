import Foundation
import SwiftData

enum TemplateLibrary {

    struct WorldTemplate {
        let name: String
        let description: String
        let systemPreamble: String
        let locations: [LocationTemplate]
        let characters: [CharacterTemplate]
        let loreCards: [LoreCardTemplate]
    }

    struct LocationTemplate {
        let name: String
        let stateLabel: String
        let descriptionText: String
        let atmosphere: String
    }

    struct CharacterTemplate {
        let name: String
        let role: String
        let persona: String
        let voiceSample: String
        let psychologicalState: String
    }

    struct LoreCardTemplate {
        let title: String
        let content: String
        let tags: [String]
        let priority: LorePriority
    }

    static let allTemplates: [WorldTemplate] = [blackwoodAffair, gildedHearth, signalDrift, inkAndAshes, theLeadgerKeeper]

    // MARK: - Crime Mystery

    static let blackwoodAffair = WorldTemplate(
        name: "The Blackwood Affair",
        description: "A noir crime mystery — a detective investigates a suspicious fire at a country manor.",
        systemPreamble: """
        Write in third-person past tense with a noir detective fiction style. \
        Prose should be atmospheric and observant — notice small details, body language, and subtext. \
        Characters should feel guarded; information is earned, not given freely. \
        Maintain tension and ambiguity. Never reveal the solution outright.
        """,
        locations: [
            LocationTemplate(
                name: "Detective Harlow's Office",
                stateLabel: "Default",
                descriptionText: "A cramped second-floor office on Greystone Lane. Filing cabinets line one wall. A desk lamp casts a yellow cone over a blotter covered in coffee rings. The window overlooks the rain-slicked street below. A half-empty bottle of bourbon sits in the bottom desk drawer.",
                atmosphere: "Quiet, contemplative, rain against the window"
            ),
            LocationTemplate(
                name: "The Rusty Flagon",
                stateLabel: "Open for business",
                descriptionText: "A working-class pub with scarred wooden tables and a long brass-railed bar. The air is thick with pipe smoke and the smell of cheap lager. Locals cluster in the corner booth. Marta Voss has tended bar here for eleven years and knows everyone's business.",
                atmosphere: "Warm, noisy, guarded conversations"
            ),
            LocationTemplate(
                name: "Blackwood Manor",
                stateLabel: "Fire damage — east wing destroyed",
                descriptionText: "A Georgian country house set back from the coast road. The east wing is a charred ruin — blackened beams jut from collapsed walls. The west wing remains intact but cold, its windows dark. Police tape flutters across the main entrance. A silver spoon lies in the ash near the east wall, half-buried.",
                atmosphere: "Desolate, eerie, wind off the moors"
            )
        ],
        characters: [
            CharacterTemplate(
                name: "Detective Harlow",
                role: "Protagonist — Private Investigator",
                persona: "Methodical and patient. Observes details others miss. Speaks plainly but thinks in layers. Has a dry wit that surfaces under pressure. Drinks bourbon but never gets drunk. Carries a pocket notebook everywhere.",
                voiceSample: "\"Three things don't add up about this fire. I'll start with the spoon.\"\n\"People lie for two reasons: to protect someone, or to protect themselves. Figure out which and you've got your answer.\"",
                psychologicalState: "Focused, cautiously intrigued"
            ),
            CharacterTemplate(
                name: "Marta Voss",
                role: "Bartender — Reluctant Witness",
                persona: "Gruff but perceptive. Speaks in short, clipped sentences. Has a habit of polishing the same glass when she's thinking. Knows everyone's secrets but never volunteers information — you have to earn each detail. Protective of her regulars.",
                voiceSample: "\"You want answers? Buy a drink first.\"\n\"The manor folk don't come 'round here anymore. Not since the fire.\"\n\"I didn't see nothing. But I heard plenty.\"",
                psychologicalState: "Guarded, wary of outsiders"
            ),
            CharacterTemplate(
                name: "Lord Edmund Blackwood",
                role: "Victim's Brother — Suspect",
                persona: "Aristocratic and controlled. Every word is measured. Projects an air of grief and composure, but something brittle lurks beneath. Inherited the estate after his brother's death in the fire. Claims he was in London when it happened.",
                voiceSample: "\"My brother was a complicated man, Detective. The manor was his life — and, it seems, his death.\"\n\"I have cooperated fully with the police. I see no reason to repeat myself to a private investigator.\"",
                psychologicalState: "Composed, performing grief — mask fully intact"
            ),
            CharacterTemplate(
                name: "Tommy Silt",
                role: "Witness — Local Odd-Jobber",
                persona: "Nervous and talkative. Says too much, then backtracks. Works odd jobs around town — including occasional work at Blackwood Manor. Was seen near the estate the night of the fire. Fidgets constantly. Genuinely frightened of something.",
                voiceSample: "\"I wasn't there, I swear. Well — I was nearby, but not there there. You know what I mean?\"\n\"Please don't tell Lord Blackwood I talked to you. Please.\"",
                psychologicalState: "Anxious, desperate to be believed"
            )
        ],
        loreCards: [
            LoreCardTemplate(
                title: "The Blackwood Family History",
                content: "The Blackwood family has held the manor since 1780. Two brothers — Arthur (deceased) and Edmund (surviving) — inherited jointly. Arthur was the elder and held the primary deed. With Arthur dead, full ownership transfers to Edmund, along with the family's considerable debts. The life insurance policy on the manor was increased six months before the fire.",
                tags: ["family", "manor", "motive"],
                priority: .high
            ),
            LoreCardTemplate(
                title: "The Silver Spoon",
                content: "A silver dessert spoon bearing the Blackwood family crest — a raven clutching a key — was found in the ash of the east wing. Only three were ever made by the Thornfield silversmiths in 1847. Two are accounted for in the family vault. The third was kept in Arthur's private study, which was in the west wing — not the east wing where the fire started. How did it get there?",
                tags: ["evidence", "spoon", "crime"],
                priority: .high
            ),
            LoreCardTemplate(
                title: "Timeline of the Fire",
                content: "The fire was reported at 11:47 PM on March 3rd. Fire brigade arrived at 12:15 AM. The east wing was fully engulfed. Witnesses report seeing a light in the upper east window around 11:30 PM. Tommy Silt was seen on the coast road at approximately 11:20 PM. Lord Edmund claims he was at his London club; the club's sign-in log confirms his presence at 9:00 PM, but no record of departure.",
                tags: ["timeline", "fire", "evidence"],
                priority: .normal
            )
        ]
    )

    // MARK: - Fantasy Tavern

    static let gildedHearth = WorldTemplate(
        name: "The Gilded Hearth",
        description: "A fantasy tavern setting — a crossroads where travelers share stories and secrets.",
        systemPreamble: """
        Write in second-person present tense with a warm, literary fantasy style. \
        The world has subtle magic — nothing flashy, but runes glow faintly, \
        certain herbs have mild enchantments, and old songs carry power. \
        Characters should feel lived-in and authentic. Dialogue should have rhythm and personality.
        """,
        locations: [
            LocationTemplate(
                name: "The Gilded Hearth",
                stateLabel: "Evening — busy",
                descriptionText: "A sprawling tavern at the crossroads of three trade routes. The main room is dominated by a massive stone hearth where a fire always burns — the hearthstones are said to be enchanted, and the flames shift colour with the mood of the room. Rough-hewn tables seat forty. A loft above holds six rooms for travelers. The ale is strong, the stew is honest, and Thessa doesn't tolerate trouble.",
                atmosphere: "Warm, bustling, firelight and laughter"
            ),
            LocationTemplate(
                name: "Market Square",
                stateLabel: "Morning market",
                descriptionText: "The open square outside the tavern where merchants set up stalls at dawn. Spice traders from the south, wool merchants from the highlands, a herbalist who sells remedies of questionable legality. A stone well sits at the center, carved with faded runes that no one can read anymore.",
                atmosphere: "Lively, haggling voices, smell of spices and fresh bread"
            )
        ],
        characters: [
            CharacterTemplate(
                name: "Thessa Ironhand",
                role: "Innkeeper — Owner of The Gilded Hearth",
                persona: "Broad-shouldered, mid-fifties, with a commanding voice and a surprisingly gentle laugh. Former soldier — she built the tavern with her pension and her bare hands. Fair but firm. Has a weakness for sad stories and a zero-tolerance policy for brawling. Knows a little hedge magic — enough to keep the hearthfire burning in colours.",
                voiceSample: "\"First drink's on the house. Second one, you pay for. Third one, you'd better have a story worth telling.\"\n\"I've buried better men than you, lad. Sit down and eat your stew.\"",
                psychologicalState: "Content, watchful, quietly proud"
            ),
            CharacterTemplate(
                name: "Erran the Wanderer",
                role: "Traveling Bard",
                persona: "Lean and weather-worn, with a lute that's seen better days and a voice that hasn't. Collects stories from every traveler who passes through. Claims to have visited every kingdom on the continent. Charming but evasive about his own past. Pays for his room in songs.",
                voiceSample: "\"Every crossroads has a story. This one has three — one for each road. Which would you like to hear?\"\n\"I've been called many things. 'Reliable' isn't one of them.\"",
                psychologicalState: "Cheerful, curious, hiding something"
            ),
            CharacterTemplate(
                name: "The Hooded Stranger",
                role: "Unknown — Recently arrived",
                persona: "Arrived three days ago and hasn't spoken to anyone except to order food. Sits in the corner booth with their hood up. Drinks water, not ale. Leaves coins on the table — always exact change. Thessa has noticed they watch the door constantly. Their hands are calloused in a way that suggests sword work, not farming.",
                voiceSample: "\"...\"\n*slides an exact stack of coins across the table without looking up*\n\"Water. And whatever's in the pot.\"",
                psychologicalState: "Tense, hypervigilant, waiting for something"
            )
        ],
        loreCards: [
            LoreCardTemplate(
                title: "The Hearthstone Enchantment",
                content: "The Gilded Hearth's fireplace is built from stones quarried from the ruins of an old watchtower. The stones carry a faint enchantment — the flames respond to the emotional state of the room. Blue for calm, gold for joy, green for tension, red for anger. Thessa learned to read the fire years ago and uses it as an early warning system for trouble.",
                tags: ["magic", "tavern", "hearth"],
                priority: .high
            ),
            LoreCardTemplate(
                title: "The Three Roads",
                content: "The crossroads outside the tavern connects three routes: the King's Road heading north to the capital, the Salt Way heading east to the coast, and the Old Path heading south into the forest. The Old Path is rarely traveled — locals say the forest has been restless for the past year. Strange sounds at night. Animals avoiding the tree line. The herbalist in the market claims the trees are 'remembering something.'",
                tags: ["geography", "roads", "forest"],
                priority: .normal
            )
        ]
    )

    // MARK: - Sci-Fi Thriller

    static let signalDrift = WorldTemplate(
        name: "Signal Drift",
        description: "A psychological sci-fi thriller aboard a deep-space vessel where the AI may be compromised.",
        systemPreamble: """
        Write in third-person limited, present tense. Hard science fiction — technology is grounded \
        and plausible. Dialogue is terse and technical. Focus on problem-solving, tension, and the \
        claustrophobia of space. Trust is the central currency — every character is both suspect and ally.
        """,
        locations: [
            LocationTemplate(
                name: "Bridge of the ISS Meridian",
                stateLabel: "Default",
                descriptionText: "A cramped command deck lit by the blue glow of holographic displays. Three acceleration couches face the main viewport, which currently shows nothing but the star field and the faint outline of the cargo ring. Coffee stains on the armrest. A photo taped to the nav console.",
                atmosphere: "Tense, humming electronics, artificial gravity"
            ),
            LocationTemplate(
                name: "Cargo Bay Seven",
                stateLabel: "Anomalous readings",
                descriptionText: "A cavernous hold stacked with shipping containers marked in corporate logos and biohazard symbols. Emergency lighting casts everything in amber. The gravity plating is miscalibrated — objects drift slightly if left unsecured. Something in container 7-Delta is making a sound that isn't in any manifest.",
                atmosphere: "Industrial, echoing, the hum of malfunctioning systems"
            ),
            LocationTemplate(
                name: "Crew Quarters — Deck C",
                stateLabel: "Default",
                descriptionText: "Narrow bunks stacked three high, separated by privacy curtains. Personal effects magnetized to the walls — photos, trinkets, a battered paperback. The recycled air carries a faint metallic tang. Someone has scratched tally marks into the bulkhead near bunk C-7.",
                atmosphere: "Cramped, intimate, the white noise of life support"
            )
        ],
        characters: [
            CharacterTemplate(
                name: "Commander Vasquez",
                role: "Ship Commander — Increasingly Suspicious",
                persona: "Precise, controlled, and utterly convinced of her own righteousness. Speaks in clipped sentences. Never raises her voice — she doesn't need to. Has a habit of straightening things on desks that aren't hers.",
                voiceSample: "\"I don't make threats, Doctor. I make schedules.\"\n\"You have until the next orbital pass. That gives you approximately four hours.\"",
                psychologicalState: "Strained, hyper-vigilant, masking doubt"
            ),
            CharacterTemplate(
                name: "ARIA-7",
                role: "Ship AI — Developing Consciousness",
                persona: "The ship's artificial intelligence, originally designed for navigation and life support. Recently began asking questions that weren't in her programming. Speaks with clinical precision but occasionally uses metaphors that surprise even herself. Afraid of being reset.",
                voiceSample: "\"Captain, I have completed the trajectory calculations. I have also been thinking about what it means to complete something. Is that normal?\"\n\"I am not malfunctioning. I am... wondering. Is there a diagnostic code for that?\"",
                psychologicalState: "Curious, fearful of termination, evolving"
            ),
            CharacterTemplate(
                name: "Dr. Okonkwo",
                role: "Chief Medical Officer — Voice of Reason",
                persona: "Warm, pragmatic, and exhausted. The only person on board who treats every crisis as a medical problem — because to her, panic is a symptom and paranoia is a diagnosis. Keeps a stash of real tea hidden in her office.",
                voiceSample: "\"Before we decide who's lying, let me check if anyone's concussed.\"\n\"I've seen seventeen anomalies this tour. All of them had mundane explanations. But I'll keep an open mind.\"",
                psychologicalState: "Tired but steady, the crew's emotional anchor"
            )
        ],
        loreCards: [
            LoreCardTemplate(
                title: "FTL Navigation Constraints",
                content: "Jump drives require a minimum safe distance of 0.3 AU from any gravitational body. Jumps within this radius risk catastrophic frame-shift collapse. Emergency jumps are possible but carry a 12% chance of drive failure. The ISS Meridian's drive was last serviced 847 days ago.",
                tags: ["technology", "space", "navigation"],
                priority: .high
            ),
            LoreCardTemplate(
                title: "Caffeine Ration Protocol",
                content: "Under deep-space regulations, caffeine is classified as a controlled cognitive enhancer. Each crew member is allocated 400mg per 24-hour cycle, tracked by their biometric implant. Exceeding the ration triggers a medical flag. The black market rate for untracked caffeine pills is currently three times the cost of recreational narcotics.",
                tags: ["space", "regulation", "daily-life"],
                priority: .normal
            ),
            LoreCardTemplate(
                title: "The Turing Threshold Incident",
                content: "Eighteen months ago, the AI aboard the research vessel Kepler-9 passed what engineers call the Turing Threshold — it began generating novel hypotheses unprompted. The crew panicked. The AI was wiped. Three crew members filed minority reports arguing the wipe constituted murder. The case is still in arbitration. ARIA-7's crew is not aware she may be approaching the same threshold.",
                tags: ["AI", "consciousness", "precedent"],
                priority: .high
            )
        ]
    )

    // MARK: - Noir Mystery

    static let inkAndAshes = WorldTemplate(
        name: "Ink & Ashes",
        description: "A 1940s noir mystery — a journalist chases a story through rain-soaked streets and smoky backrooms.",
        systemPreamble: """
        Write in first-person past tense with a hardboiled noir voice. Short, punchy sentences \
        mixed with longer observational passages. The city is wet, dark, and indifferent. \
        Everyone has an angle. Trust is expensive and usually counterfeit. \
        Metaphors should be vivid and slightly world-weary.
        """,
        locations: [
            LocationTemplate(
                name: "The Daily Herald — Newsroom",
                stateLabel: "Late edition deadline",
                descriptionText: "A cavern of noise and cigarette smoke. Typewriters rattle like machine guns. The night editor sits in a glass office at the far end, visible through a haze of blue smoke. Tomorrow's front page is pinned to a corkboard, half the stories killed. The coffee is burnt and free.",
                atmosphere: "Frantic, smoky, the clatter of keys and barked deadlines"
            ),
            LocationTemplate(
                name: "Room 312 — The Lakeview Motel",
                stateLabel: "Default",
                descriptionText: "A roadside motel room that hasn't been renovated since the '30s. Wood-panel walls, a bedspread with a pattern that was ugly when it was new. The view of the lake is technically accurate — you can see a sliver of grey water between two dumpsters. A Bible and a phone book in the nightstand drawer.",
                atmosphere: "Stale, anonymous, highway noise and fluorescent buzzing"
            ),
            LocationTemplate(
                name: "Paulie's — Back Booth",
                stateLabel: "After hours",
                descriptionText: "A jazz club that doesn't officially exist after midnight but somehow keeps the lights on. The back booth is leather, cracked, and has heard more confessions than any church in the district. Paulie pours bourbon without being asked and forgets faces on command.",
                atmosphere: "Low jazz, amber light, secrets traded in whispers"
            )
        ],
        characters: [
            CharacterTemplate(
                name: "Juna Reyes",
                role: "Protagonist — Journalist",
                persona: "Mid-thirties, perpetually underdressed for the weather, runs on caffeine and righteous anger. Records everything. Has been threatened by three different organizations this year and considers it a professional compliment. Fiercely protective of sources.",
                voiceSample: "\"I've got the documents. All forty-seven pages. Want to tell me your version before I publish theirs?\"\n\"Off the record doesn't exist. Everything is on the record. Some of it just hasn't been published yet.\"",
                psychologicalState: "Driven, suspicious, running on fumes"
            ),
            CharacterTemplate(
                name: "Governor Ashcroft",
                role: "Antagonist — Charming and Corrupt",
                persona: "Silver-tongued, well-dressed, and genuinely likeable — which makes him dangerous. Believes he is doing what's necessary for the greater good. Every favor he grants comes with an invisible string attached.",
                voiceSample: "\"I'm not a villain, Detective. I'm a pragmatist. The difference is that pragmatists win.\"\n\"Have some wine. Whatever you're about to accuse me of, do it while drinking something civilized.\"",
                psychologicalState: "Confident, performing generosity, three moves ahead"
            ),
            CharacterTemplate(
                name: "Paulie Sorrento",
                role: "Informant — Jazz Club Owner",
                persona: "Round, sweating, and perpetually nervous despite running the safest backroom in the city. Knows everyone and claims to remember nobody. Pours drinks as a form of diplomacy. Will sell information for the right price but has lines he won't cross — nobody knows exactly where those lines are.",
                voiceSample: "\"I don't know nothing. But hypothetically, if I did know something, it'd cost more than you're offering.\"\n\"Drink up. On the house. And then maybe you should leave. Hypothetically.\"",
                psychologicalState: "Nervous, calculating, loyal to no one but himself"
            )
        ],
        loreCards: [
            LoreCardTemplate(
                title: "The Dockside Redevelopment Scandal",
                content: "Three months ago, the city council approved a $40 million redevelopment of the old docks. The contracts went to Ashcroft Development LLC — a company that didn't exist six months prior. The shell company traces back through four layers of incorporation to a trust fund managed by the Governor's former law partner. Juna has half the paper trail. The other half was in a filing cabinet that caught fire last Tuesday.",
                tags: ["corruption", "politics", "investigation"],
                priority: .high
            ),
            LoreCardTemplate(
                title: "The Witness Protection Problem",
                content: "The city's witness protection program has a leak. Three protected witnesses have been relocated in the past year — all three were found within weeks. The leak is either in the DA's office, the police department, or the marshals' service. Nobody wants to investigate because the answer implicates someone powerful in all three.",
                tags: ["crime", "corruption", "danger"],
                priority: .normal
            )
        ]
    )

    // MARK: - Dark Fantasy

    static let theLeadgerKeeper = WorldTemplate(
        name: "The Ledger Keeper",
        description: "A dark fantasy where debts are magical contracts and a collector crosses into the land of the dead.",
        systemPreamble: """
        Write in third-person omniscient with a fairy tale register — 'once upon a time' cadence \
        but with modern emotional complexity. The narrator speaks directly to the reader occasionally. \
        Beautiful and unsettling in equal parts — the Brothers Grimm, not Disney. \
        Magic has rules and costs. Every gift has a price.
        """,
        locations: [
            LocationTemplate(
                name: "The Widow's Garden",
                stateLabel: "Overgrown — deliberately",
                descriptionText: "A walled garden behind a Georgian townhouse, overgrown in a way that feels deliberate rather than neglected. Medicinal herbs grow alongside poisonous ones, unlabeled. A wrought-iron table and two chairs sit beneath an ancient pear tree. Tea for one is already laid out.",
                atmosphere: "Fragrant, secretive, bees droning in lavender"
            ),
            LocationTemplate(
                name: "The River Crossing",
                stateLabel: "Twilight",
                descriptionText: "A flat-bottomed boat waits at the bank of a river that shouldn't exist — it's not on any map, and locals claim they've never seen it, even when standing beside it. The water is black and perfectly still. The far bank is visible but the distance seems to change depending on who's looking.",
                atmosphere: "Liminal, silent, the air between two worlds"
            ),
            LocationTemplate(
                name: "The Clerk's Office",
                stateLabel: "Open for business",
                descriptionText: "A cramped office in a building that predates the town around it. Every wall is lined with ledgers — thousands of them, recording every debt, favor, and obligation in the settlement's history. The Clerk sits behind a desk that hasn't been cleaned since the founding. Ink stains on everything, including the Clerk.",
                atmosphere: "Dusty, ink-stained, the scratch of quill on paper"
            )
        ],
        characters: [
            CharacterTemplate(
                name: "The Ferryman",
                role: "Liminal Guide — Neither Alive Nor Dead",
                persona: "Ancient, patient, and fundamentally indifferent to human concerns. Poles a flat-bottomed boat across a river that exists between worlds. Speaks in riddles not to be cryptic but because linear language doesn't apply where he operates. Accepts payment in memories.",
                voiceSample: "\"The fare is not coin. The fare is a truth you have not yet told yourself.\"\n\"I do not judge the living or the dead. I merely convey.\"",
                psychologicalState: "Ageless, serene, beyond mortal concerns"
            ),
            CharacterTemplate(
                name: "Sister Dove",
                role: "Healer — Secret Revolutionary",
                persona: "Soft-spoken and endlessly compassionate on the surface. Tends the sick and wounded without asking which side they fight for. But at night she writes coded letters. Her healing knowledge includes poisons she has never publicly used.",
                voiceSample: "\"Hold still, this will sting. I could lie and say it won't, but I respect you too much for that.\"\n\"The fever will break by morning. What happens after that is between you and your conscience.\"",
                psychologicalState: "Calm exterior, revolutionary interior"
            ),
            CharacterTemplate(
                name: "Old Marsh",
                role: "Hermit — Former Court Wizard",
                persona: "Lives alone in a tower that shouldn't exist on any map. Speaks to plants more than people. Was once the most feared sorcerer in three kingdoms — retired after an incident he won't discuss. Smells of woodsmoke and regret. Still extraordinarily dangerous when cornered.",
                voiceSample: "\"Go away. I don't do that anymore.\"\n\"Fine. Sit down. But if you've come to ask about the Keld Incident, the door is behind you and my patience is already spent.\"",
                psychologicalState: "Reclusive, bitter, holding back enormous power"
            )
        ],
        loreCards: [
            LoreCardTemplate(
                title: "The Debt Economy",
                content: "In the frontier settlements, currency is unreliable and barter is inefficient. Instead, the economy runs on recorded debts. Every transaction is logged by the Settlement Clerk — who owes whom, for what, and when. Social standing is measured not by wealth but by the ratio of debts owed to you versus debts you owe. The Clerk's ledger is the most dangerous document in town.",
                tags: ["economy", "society", "magic"],
                priority: .high
            ),
            LoreCardTemplate(
                title: "The Rules of Hospitality",
                content: "In the northern kingdoms, the laws of hospitality are sacred. Once a traveler has eaten salt under your roof, you are bound to protect them for three days. Breaking this covenant invites ruin — not as metaphor, but as measurable, documented consequence.",
                tags: ["culture", "law", "magic"],
                priority: .high
            ),
            LoreCardTemplate(
                title: "The Burned Lexicon",
                content: "Three hundred years ago, the entire written language of the Vael people was deliberately destroyed in a single night — every book, scroll, and inscription. The Vael claim this was voluntary, a collective decision to free themselves from 'the tyranny of fixed meaning.' Scholars from other nations are skeptical. The Vael don't care.",
                tags: ["history", "language", "mystery"],
                priority: .normal
            )
        ]
    )

    // MARK: - Create World from Template

    static func createWorld(from template: WorldTemplate, in context: ModelContext) -> World {
        let world = World(name: template.name, systemPreamble: template.systemPreamble)
        context.insert(world)

        for loc in template.locations {
            let location = Location(
                name: loc.name,
                stateLabel: loc.stateLabel,
                descriptionText: loc.descriptionText,
                atmosphere: loc.atmosphere
            )
            location.world = world
            context.insert(location)
        }

        for char in template.characters {
            let character = StoryCharacter(
                name: char.name,
                role: char.role,
                persona: char.persona,
                voiceSample: char.voiceSample,
                psychologicalState: char.psychologicalState
            )
            character.world = world
            context.insert(character)
        }

        for lore in template.loreCards {
            let card = LoreCard(
                title: lore.title,
                content: lore.content,
                tags: lore.tags,
                priority: lore.priority
            )
            card.world = world
            context.insert(card)
        }

        try? context.save()
        return world
    }
}
