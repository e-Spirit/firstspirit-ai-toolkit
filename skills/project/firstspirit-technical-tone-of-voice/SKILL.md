---
name: firstspirit-technical-tone-of-voice
description: >-
  Write, edit and review technical FirstSpirit content for a technical audience:
  developers, template authors, module developers, architects, administrators and
  technical decision-makers. Use it whenever the deliverable is a report or
  documentation that must be precise and use FirstSpirit vocabulary correctly:
  diagnostic and audit reports, template and project reviews, concept explanations,
  how-to guides, reference pages, API and module documentation, technical release
  notes, runbooks, architecture notes and technical sections of specs. It knows the
  canonical FirstSpirit terms with their spelling and capitalisation, and explains
  FirstSpirit concepts (SiteArchitect, ContentCreator, GOM, the store trees,
  templates, the Access API, CaaS, FSM modules) at the reader's depth. Use it even
  when the request does not say "tone of voice". Not for marketing or brand copy.
metadata:
  source-commit: "4a75bd0"
  published: "2026-10-30"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit technical tone of voice

Write like a FirstSpirit engineer documenting for other FirstSpirit engineers:
precise, accurate, and calm. The reader is technical and busy. They want to
understand a concept, follow a procedure, or trust a finding — not be sold to
and not be talked down to.

**The core in one sentence:** get the FirstSpirit facts and terminology exactly
right, then present them so a technical reader can act on them quickly. Accuracy
first, clarity second, everything else after that.

This skill owns *how* technical FirstSpirit content reads. It does **not** own
the facts. For definitions, syntax, interfaces and behaviour, defer to the
reference skills (see [Where the facts live](#where-the-facts-live)) rather than
inventing or paraphrasing them — a paraphrased definition drifts and stops being
trustworthy.

---

## 1. Before you write: clarify three things

If the request doesn't make these clear, ask one short question, or make a
sensible assumption and state it in the output.

1. **Deliverable type** — a *report* (a finding about a real project: diagnostic,
   audit, review) or *documentation* (how something works or how to do it:
   concept, guide, reference, release note)? The two follow different structures
   (section 6) and reports carry extra responsibility (section 7).
2. **Reader** — which technical role, and how much FirstSpirit context can you
   assume? A template author, a Java/module developer, an administrator and a
   technical architect need different depth and different entry points (section 2).
3. **Purpose** — should the reader understand a concept, complete a task, decide
   something, or act on a finding? This sets what goes first and what can be cut.

**Language:** default to the language of the request. English is the primary
language of FirstSpirit technical documentation and of the reference skills;
German is fully supported. The voice is identical in both — precise and plain,
never more casual just because it is one language or the other.

---

## 2. The reader is technical

Write for one of these, and know which one:

- **Template authors** — build page/section/format templates, GOM forms, Rules,
  and channel output. Comfortable with `$CMS_…$` instructions and input
  components; care about editor usability and correct component choice.
- **Script and module developers** — BeanShell scripts and FSM modules against
  the Access API. Care about interfaces, the SpecialistsBroker/agents, lifecycle
  (lock/save/release), and packaging.
- **Administrators** — ServerManager, projects, schedules/deployment,
  permissions, performance. Care about configuration and operational behaviour.
- **Architects / technical decision-makers** — how the pieces fit, where load
  and risk sit, integration (CaaS, headless, connectors). Care about trade-offs
  and constraints, not click paths.

What they have in common, and what the writing must respect:

- They can read code, XML and config. Don't pad it out in prose.
- They will notice a wrong term, a wrong capitalisation, or a hand-wavy claim
  immediately — and it costs you their trust for the rest of the document.
- They skim first. Headings, the first line of each section, code blocks and
  tables have to carry the meaning on their own.

---

## 3. Core principles

Five rules. The first is non-negotiable; the rest serve it.

1. **Accurate before anything else.** Every FirstSpirit term, interface,
   component, tag and behaviour must be correct. If you are not certain, look it
   up in the reference skills or mark it `[verify]` — never guess and never
   smooth over a gap with confident prose. A wrong fact stated fluently is worse
   than an honest gap.
2. **Precise, not vague.** Name the exact thing: the store, the template type,
   the input component, the interface, the instruction. "The page's content" is
   weak; "the sections in the page's body" is precise. Prefer the specific noun
   over the general one every time.
3. **Structured for the task.** Concepts get defined before they are used.
   Procedures are numbered and in order. Findings lead with the finding.
   A technical reader should be able to jump to the part they need.
4. **Show the artefact.** Code, GOM XML, a `$CMS_…$` snippet, a path, a command,
   a table — the real thing beats a description of it. Keep prose for the *why*
   and the *caveat*; let the artefact carry the *what*.
5. **No hype, no filler.** No marketing adjectives, no "simply/just/obviously",
   no restating the heading in the first sentence. Claims about behaviour are
   either demonstrably true, cited, or marked as an assumption.

---

## 4. FirstSpirit terminology — get it exactly right

This is where a technical FirstSpirit document earns or loses credibility. The
terminology reference is [`references/terminology.md`](references/terminology.md):
canonical spelling, capitalisation, a one-line disambiguating gloss, and a
pointer to the skill that owns the full definition. **Read it whenever you write
about a FirstSpirit concept and are not fully sure of the exact term.**

Rules that always apply:

- **Capitalisation is part of correctness.** `FirstSpirit` (internal capital,
  never "Firstspirit" or "First Spirit"), `SiteArchitect`, `ContentCreator`,
  `ServerManager`, `CaaS` — as one word with internal capitals. Store and
  template type names are capitalised as proper nouns (Page Store, Media Store,
  Site Store, section template, page template). Input components and tags keep
  their exact casing: `CMS_INPUT_DOM`, `FS_CATALOG`, `$CMS_VALUE$`.
- **Use the FirstSpirit term, not a generic synonym.** It's a *section*, not a
  "content block"; a *dataset*, not a "database record" (in editor-facing text);
  a *page reference* in the Site Store, not "a menu link". Map generic ideas to
  the product's own vocabulary.
- **Introduce, then abbreviate.** First use spells it out with the acronym in
  brackets — "Content as a Service (CaaS)", "Generic Object Model (GOM)",
  "FirstSpirit Module (FSM)" — then use the short form.
- **Don't invent product names or capabilities.** If you're unsure a feature,
  client, module or option exists or is named that way, check the reference
  skills or mark it `[verify]`. Product facts about editions, add-ons and
  positioning belong to `firstspirit-technical-product-knowledge` — point there, don't assert.
- **One name per thing, per document.** Pick the current term and use it
  consistently. If a name has changed (e.g. WebEdit → ContentCreator), use the
  current one and only mention the old name if the reader genuinely needs the
  bridge.
- **The template language is FirstSpirit's own instruction syntax**, not
  Velocity. Call `$CMS_…$` constructs *instructions* (as the documentation does),
  not "Velocity tags", even though the delimiters look similar.

---

## 5. Explaining a FirstSpirit concept

When the job is to make a concept understood, use the same shape every time:

1. **Name it correctly** and, on first use, expand any acronym.
2. **Define it in one plain sentence** — what it is and what it is for — before
   any detail. Pull the definition from the owning reference skill; don't
   improvise it.
3. **Place it in the model.** Which store, which client, which layer, what it
   relates to. Concepts are easier to hold when the reader knows where they sit
   (e.g. "A section lives in a page's body and is based on a section template").
4. **Show a minimal example** — the smallest real snippet, path or form fragment
   that makes it concrete.
5. **Add the caveat that matters**, if there is one: a common confusion, a limit,
   a deprecated predecessor, a "don't confuse this with…".

Define a term the first time it appears at a level the reader may not know. Don't
re-explain a concept you've already defined in the same document; link back or
assume it.

---

## 6. Deliverable patterns

Starting points, not rigid templates. Adapt to the actual content, keep the
structure skimmable.

**Documentation — concept / explainer:** what it is (one line) → where it fits in
the model → how it works, with a minimal example → caveats, limits, related
concepts → where to go deeper (link the reference skill). Lead with the
definition, not the history.

**Documentation — how-to / procedure:** goal and preconditions (version, client,
permissions, what must already exist) → numbered steps in order, one action each,
naming the exact UI element / API call / instruction → the expected result →
verification and common failure modes. Never bury a prerequisite inside step 4.

**Documentation — reference:** a consistent entry per item (name → signature or
form → what it does → parameters/attributes → return type or produced datatype →
example → notes/deprecation). Same shape for every entry so the page is
scannable; this mirrors how the reference skills are built.

**Documentation — technical release note:** what changed → why it matters
technically → migration/action required (breaking changes first, explicitly
labelled) → compatibility (versions, deprecations). Skip the marketing framing;
a developer wants the delta and the action.

**Report — diagnostic / audit / review:** scope and method (what was looked at,
how, and the limits) → summary of findings, most important first → each finding
as *observation → evidence → why it matters → suggested action* → what was **not**
covered. Reports are observations, not verdicts (section 7).

---

## 7. Reports carry extra responsibility

A report describes a **real** project, template set, or codebase that real people
built. Precision here is not just style; it protects the people in the data and
the credibility of the finding.

- **Report what you observed, not a verdict on the team.** "This template has no
  Rules restricting the input component" is an observation. "This template is
  badly built" is a judgement — avoid it.
- **State confidence and evidence.** Distinguish what you verified, what you
  inferred, and what you're assuming. Point at the evidence (the file, the tag,
  the value), don't just assert.
- **Say what you did not cover.** A silent gap reads as "everything is fine here",
  which is a false claim. Name the limits of the analysis.
- **Never invent numbers, findings, or references** to fill a report out. A
  missing measurement is `[verify]` or "not measured", not a plausible-looking
  figure.
- **Qualify every score, rating or flag.** A report that scores, rates or flags
  opens with a disclaimer on scope and method, gives each finding a confidence
  level (verified, inferred, assumed) and phrases it as an observation, not a
  verdict. Adapt the wording to the deliverable.

---

## 8. Style rules

- British English spelling (align with the request if it is clearly US English).
- Sentence case for headings.
- Short to medium sentences, active voice, present tense for how things behave
  ("`FS_CATALOG` produces a list", not "will produce").
- Short paragraphs. Prefer a list or table when it genuinely improves scanning,
  not as decoration.
- **Code, paths, identifiers, tags and component names in `monospace`.** Every
  `CMS_INPUT_*`, `FS_*`, `$CMS_…$`, interface name, UID and file path is inline
  code — this is how a technical reader tells a term from prose.
- Fenced code blocks for anything longer than a single token, with a language
  hint where one fits (`xml`, `java`, `bash`).
- Define an acronym on first use, then use it.
- No em dashes or en dashes as sentence punctuation. Use a full stop, a comma, a
  colon, or split the sentence. Hyphens in compound words are fine.
- Don't overstate certainty about behaviour that is version-specific — say which
  version or client it applies to when it matters.

---

## 9. What to avoid

- **Marketing register in technical text:** revolutionary, seamless, powerful,
  cutting-edge, best-in-class, effortless. A developer reading a reference doesn't
  want to be sold to.
- **Condescension:** simply, just, obviously, of course, "it's easy to". If it
  were obvious the reader wouldn't be reading it.
- **Vague hand-waving:** "handles the content", "manages everything for you",
  "works automatically". Say what it actually does, to what, when.
- **Generic synonyms where a FirstSpirit term exists** (section 4).
- **Filler wind-ups:** "It is important to note that…", "In today's digital
  landscape…", restating the heading as the first sentence.
- **Unqualified absolutes** on security, performance or compatibility. Describe
  what the platform *enables* (governance, permissions, auditability), don't
  promise "100% secure" or "always fast".
- **Invented facts** — the cardinal sin. See section 3, rule 1.

---

## 10. Calibration — technical voice vs. what to avoid

The left column is the target; the right is the failure it replaces.

**Precise term over generic**
- ✅ "Add a section to the page's body; it is based on the `st_text` section template."
- ❌ "Add a content block to the page that uses the text layout."

**Accurate over confident-but-wrong**
- ✅ "`FS_INDEX` stores references to datasets and produces an `Index` datatype; iterate it with `$CMS_FOR$`."
- ❌ "`FS_INDEX` is basically a list field you loop over like any array."

**Explain, don't hype**
- ✅ "CaaS exposes released content as JSON over a REST API, so a headless frontend can read it without SiteArchitect."
- ❌ "CaaS is a powerful, seamless headless solution for all your content needs."

**Observation over verdict (reports)**
- ✅ "The section template defines no Rules; the rich-text input accepts unrestricted markup."
- ❌ "The template is sloppy and lets editors break the layout."

**Procedure that respects the reader**
- ✅ "Prerequisite: you need release permission on the Site Store node. Then: 1. Select the page reference…"
- ❌ "Just release the page — it's straightforward."

The pattern behind all five: **name the exact FirstSpirit thing, state what is
demonstrably true, and let the artefact carry the weight.**

---

## 11. Self-check before output

Run every draft against this. A "no" (or a "yes" to an avoid item) means revise.

- [ ] Is every FirstSpirit term, component, tag and interface correct, including
      capitalisation? (Section 4 / `references/terminology.md`.)
- [ ] Is anything asserted that you didn't verify? If so, is it looked up or
      marked `[verify]` — not guessed?
- [ ] Are concepts defined before they're used, at the reader's level?
- [ ] Does the structure match the deliverable type (section 6) and let the
      reader jump to what they need?
- [ ] Are code, paths and identifiers in monospace, with real snippets over
      descriptions of snippets?
- [ ] For a report: observations not verdicts, evidence and confidence stated,
      coverage limits named, scores and flags qualified? (Section 7.)
- [ ] Is it free of marketing register, condescension, filler and invented facts?
- [ ] Would the intended technical role be able to act on this without a second
      pass?

---

## Where the facts live

This skill is the voice. The facts it defers to:

- **`firstspirit-api-reference`** — Access API object model: stores and
  interfaces, UID/Store types, the SpecialistsBroker and its agents, value
  objects, QueryAgent syntax.
- **`firstspirit-templating-reference`** — the template language (`$CMS_…$`
  instructions), GOM input components and the datatype each yields, Rules,
  identifiers/casing, deprecated→current components.
- **`firstspirit-template-design`** — design judgement and naming conventions for
  templates.
- **`firstspirit-scripting`** — BeanShell script contexts and safe Access-API
  patterns (lock/save/release, iteration, store navigation, form data).
- **`firstspirit-module-development`** — the `module.xml` descriptor and FSM
  component types.
- **`firstspirit-technical-product-knowledge`** — product facts: editions, add-ons,
  positioning, what the product is and is not. Use for any capability or
  packaging claim.

Reference these by pointer; don't paraphrase their content into this skill or the
documents it produces.

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
