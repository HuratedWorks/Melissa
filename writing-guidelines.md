# Writing Guidelines for the Melissa Cycle

This is a practical guide for drafting, expanding, and revising the Melissa stories. It adapts beginner novel-writing advice to this specific project, so it is less a theory document and more a working checklist.

External beginner-writing references used:
- National Centre for Writing: "How to write a novel: a step-by-step guide"
- Reedsy: "How to Write a Novel"
- The Write Practice: "How To Write a Novel: Complete 20-Step Guide"
- Savannah Gilbo: first-draft / novel roadmap materials

## Core Promise

The cycle is historical survival science fiction.

Every chapter should deliver three things:
- a concrete historical or future environment;
- a specific survival problem that only Melissa would have in that environment;
- a change in Melissa's methods, memory, routes, or rules.

The book is not about Melissa watching famous history from the front row. It is about a person below the official level of history surviving the way ordinary systems count children, bodies, property, labor, money, names, and adulthood.

## Before Drafting a Chapter

Write a short answer to each question before expanding prose:

1. **Where and when is Melissa?**
   Name the place, year, political world, language environment, and class position.

2. **What does she want right now?**
   Keep this concrete: passage, shelter, access to ingredients, a legal adult, a cache, a record change, a way out.

3. **What makes this era dangerous in a new way?**
   Do not repeat "people notice she does not age" by itself. Attach it to the local system: neighbors, ship crew, parish books, workhouse forms, schools, banks, cameras, biometrics.

4. **What tool does she use?**
   Examples: Greek cipher, disguise, money, adult proxy, false kinship, work skill, medical knowledge, technical access, telepresence.

5. **Why does the tool fail or become costly?**
   If a tool solves the whole problem, the chapter loses tension. Money, disguise, documents, and technology should help, then reveal a new limit.

6. **What changes by the end?**
   Melissa should leave with one new rule, scar, route, fear, habit, ally, or lost possibility.

## Chapter Shape

A useful default structure:

1. **Opening pressure**
   Start close to the problem. Avoid long historical explanation before Melissa needs something.

2. **Local normal**
   Show the place through practical details: food, work, weather, roads, rooms, smells, documents, tools, local speech, social rules.

3. **Melissa's plan**
   She should rarely drift. She observes, compares, prepares, tests, and keeps backups.

4. **Complication**
   A person or system sees more than expected. The complication should fit the era.

5. **Choice**
   Melissa chooses between bad options. The best chapters force her to lose something to stay alive.

6. **Exit or new rule**
   End with a route, a recorded note, a changed identity, a broken attachment, or a rule she will carry forward.

This structure is flexible. The important part is that each chapter moves from pressure to consequence.

## Scene Checklist

For each scene, make sure at least four of these are true:
- Melissa wants something specific in this scene.
- Someone or something blocks her.
- The scene contains era-specific material detail.
- Melissa makes a choice, not just an observation.
- The choice changes her risk.
- The scene reveals a method she uses to survive.
- The scene shows a limit of her body, paper age, or social role.
- The scene leaves a trace that matters later: memory, document, rumor, injury, debt, route, cache, witness.

If a scene only explains background, either cut it or put the explanation under immediate pressure.

## Melissa's Character Rules

Melissa is internally ancient, but she does not get to perform adulthood freely. Her body, face, height, voice, and social placement keep forcing her into childhood.

Use this contrast carefully:
- she is strategic, patient, and historically experienced;
- she can still be physically trapped, dismissed, carried, inspected, or spoken over;
- she often understands adults better than they understand themselves;
- she must not become omniscient or invulnerable;
- her dry humor should come from precision, not from jokes inserted over the scene.

Her best moments are practical. She notices which door is unlatched, which clerk is lazy, which sailor is ashamed, which child is afraid, which system has a maintenance account, which adult signature is worth more than gold.

## Continuity Guardrails

Use `ideas.md` as canon support, but keep these rules visible:

- Melissa usually carries papers near fourteen, but physically reads younger, closer to twelve or thirteen.
- Her condition is maintained by a concrete, fragile, photo-reactive practice, not abstract immortality.
- Greek writing and private cipher are recurring tools.
- She leaves before curiosity turns into fear.
- A fixed two-year stay is a modern tactic, not a universal law.
- Money helps logistics but cannot buy an adult body.
- Marriage, guardianship, adoption, workhouses, schools, and remote accounts are all counting systems; each can help briefly and then become a trap.
- Makeup, masks, video, and telepresence help at a distance but fail under close scrutiny.
- Do not give past Melissa future metaphors or future technical understanding.
- Do not overuse famous historical events. Famous events are background unless Melissa has a survival reason to touch their edges.

## Historical And Technical Checks

Before finalizing a chapter, verify:

- age, paper status, and apparent body age;
- plausible travel routes and travel time;
- local names, money, documents, offices, and institutions;
- what records existed in that place and era;
- what an adult could legally or socially do that Melissa could not;
- whether a child without kin would be ignored, exploited, helped, institutionalized, or married off;
- whether the chapter accidentally gives Melissa future knowledge;
- whether the chapter contradicts `movements.md` or the route implied by nearby chapters.

When unsure, prefer a narrower claim in the prose. Melissa can think "this is probably enough" more safely than the narration declaring a broad historical rule.

## Revision Pass

After drafting, revise in this order:

1. **Continuity pass**
   Check age, route, names, documents, formula, cipher, money, and relation to adjacent chapters.

2. **Stakes pass**
   Make the danger specific. "They may notice" is weaker than "the parish clerk will copy her age beside the same face next Easter."

3. **Agency pass**
   Make sure Melissa acts, tests, chooses, or prepares in every major movement of the chapter.

4. **Compression pass**
   Remove repeated explanations, especially about not aging, unless the new context changes the meaning.

5. **Texture pass**
   Add concrete objects and small social behaviors. Avoid generic "historical" atmosphere.

6. **Language pass**
   Keep sentences clear, cut accidental modern idioms from old settings, and make humor dry rather than loud.

7. **Merged-manuscript pass**
   Run `./merge.sh all -y` after chapter edits and check that `melissa-all.md` has the expected chapter count.

## What Makes A Good Melissa Chapter

A strong chapter usually has:
- a local system that seems ordinary to everyone else;
- a reason that system is uniquely dangerous to Melissa;
- a survival tactic that partly works;
- a human relationship that complicates the tactic;
- a moment where being treated as a child helps;
- a moment where being treated as a child traps her;
- a final decision that is rational but emotionally costly.

The best ending is rarely "she escapes." The best ending is "she escapes and now understands one more form of captivity."

## Common Failure Modes

Avoid these patterns:
- Melissa watches history but does not affect her own situation.
- The chapter becomes a lecture about the era.
- A clever trick solves too much.
- Money removes the problem instead of moving it.
- An adult helper is only a tool and not a person.
- A villain is evil in a generic way instead of being produced by the local system.
- Melissa sounds like a modern narrator in a premodern chapter.
- The same explanation of her body appears in the same words again.
- The chapter ends without changing her route, rule, risk, or memory.

## Practical Workflow

For each new chapter:

1. Add the idea to `ideas.md` if it changes canon.
2. Add or adjust the route in `movements.md` if it changes chronology.
3. Draft the chapter in its own `melissa-??.md` file.
4. Update `melissa-index.md` and `README.md`.
5. Run `./merge.sh all -y`.
6. Search for contradictions in nearby chapters.
7. Commit the chapter and support files together.
