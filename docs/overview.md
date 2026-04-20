# Canon Workspace — Overview

*A plain-language companion to `spec.md`. For the technical reader, read the spec.*

---

## What is this?

Canon Workspace is a tool for people who have spent weeks or months thinking through a topic across many long conversations — with an AI, with collaborators, in their own notes — and want the thinking to *converge* into something durable.

That durable thing is called a **canon**: a single, well-organized document that captures what you actually believe, what you're still unsure about, and what's still in dispute. Not a transcript. Not a pile of notes. A maintained, inspectable artifact you can point at and say, "this is what I think, and here's why."

You use it as the foundation for whatever comes next — a proposal, a thesis, a product spec, an onboarding doc, a book chapter.

## Why does this exist?

If you've ever tried to turn a long exploratory journey into a coherent document, you know the problem:

- You have too many conversations to re-read.
- Each conversation has some gold and a lot of noise.
- Your thinking has evolved — early ideas got refined, contradicted, or abandoned — but there's no clean record of *where it landed*.
- Summarizing doesn't help. Summaries flatten the interesting structure: the open questions, the things you're tentative about, the places where two sources disagree.

Most people either give up and start writing from memory (losing a lot), or they paste everything into one giant doc and hope for the best (losing clarity).

This tool is built around a different idea: **treat the corpus of conversations as one thing, and the canon as a separate thing.** The conversations are raw material, frozen in place. The canon is the living artifact you build *from* them, piece by piece.

## How it works, in plain terms

You create a workspace — a folder on your computer, tracked by git. When you start, you have a conversation with the assistant about **what kind of structure** your canon should have. Are you building a framework? Doing research synthesis? Arguing a thesis? Designing a product? The shape of your canon depends on what you're trying to produce, and the tool helps you pick or build one that fits.

Then you work in a loop:

**1. Add a source.** You drop in a new conversation transcript. The assistant reads it, pulls out the distinct ideas inside (claims, questions, assumptions, whatever your chosen structure calls for), and decides for each one: does this *agree* with something already in my canon? Does it *add* something new? Does it *conflict* with what's there?

New ideas get added to the canon, marked as *tentative* — meaning "candidate, not yet corroborated." Conflicts get flagged as *in flight* — meaning "two sources disagree, a human needs to decide." Agreements get logged without changing anything visible.

**2. Review.** The assistant generates a visual rendering of your canon — a web page you open in your browser. Tentative claims look different from stable ones. Conflicts are loud. Every item is clickable back to the source it came from, so you can always verify. This is where you do the actual thinking: reading, forming judgments, deciding what's ready to promote from tentative to stable, deciding how to resolve conflicts.

**3. Refine.** Based on what you saw, you tell the assistant what to change — promote this, resolve that, merge these two questions, retire that one. You can also evolve the structure itself: if you realize your canon needs a new kind of section, you say so, and the schema adapts.

**4. Commit.** You save your progress in git when you're ready. Nothing auto-saves.

You repeat this loop for each new source. Over time, the canon sharpens.

## The key ideas

A few principles shape how this feels to use:

- **The sources are frozen.** Once a conversation is captured into the workspace, it cannot be edited. It's the immutable record. The canon is the mutable, maintained artifact.

- **Provenance is always available.** Every single statement in your canon can be clicked back to the exact sentences in the exact source that produced it. You never have to wonder "where did I get this idea from?"

- **The machine doesn't decide what you believe.** The assistant extracts, classifies, and flags — mechanical work. Decisions about what's true, what's stable, and how to resolve disagreements are yours. The tool is deliberately designed so it can't quietly drift your canon in a direction you didn't agree to.

- **The structure evolves with the work.** Your initial choice of schema isn't a cage. As you learn more about what you're actually building, you revise the structure and the tool follows.

- **The canon is for building from, not just reading.** When you're ready to write the proposal or the thesis, you have a clean, inspectable foundation — organized the way *this effort* needed it, not the way some generic template imagined.

## What you do vs. what the tool does

**You:** decide what questions you're exploring, bring in the source conversations, judge which claims are stable, resolve conflicts between sources, evolve the structure as your thinking matures, write the final downstream artifact.

**The tool:** preserves your sources verbatim, breaks each new source into its component ideas, classifies each one against the existing canon, flags what needs your attention, keeps the canon organized according to your chosen structure, makes every claim traceable back to its origin, renders the canon for review.

The division is deliberate. Editorial judgment is the scarce resource; the tool exists to protect your attention for it.

## When this is useful

- You've had dozens of long AI conversations about a topic and want to harvest the thinking.
- You're writing a thesis or book and need to organize your working ideas across many exploratory sessions.
- You're scoping a product and have accumulated research, interviews, and internal discussions that need synthesis.
- You're developing a framework or mental model and want a clean record of how it evolved.
- Anytime the *material* for a document is scattered across a corpus and you need a structured, inspectable middle layer between the corpus and the final product.

## When this is not the right fit

- You just want a summary. This tool is for building something more structured than a summary.
- You want the AI to make editorial decisions for you. It won't.
- You want a collaborative multi-user system. This is single-user, git-backed.
- You want it to ingest PDFs, audio, video, or arbitrary formats. Sources are markdown files you capture.

---

*For the technical specification — commands, file formats, component architecture — see `spec.md`.*
