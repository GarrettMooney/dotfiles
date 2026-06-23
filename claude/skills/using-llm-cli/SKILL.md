---
name: using-llm-cli
description: Use when needing web search, large document analysis, YouTube summaries, cheap quick lookups, or second opinions from Gemini - suggests llm CLI as auxiliary brain for tasks beyond Claude's strengths
---

# Using the llm CLI

## Overview

Use the `llm` CLI to extend Claude's capabilities with web search, large document processing, YouTube analysis, and cross-model verification. Results from llm commands become part of the conversation context.

**Core principle:** llm is an auxiliary brain - use it for things Claude can't do well (current info, huge docs, YouTube) or to get a second opinion.

## When to Suggest llm (Ask First)

**YouTube videos:**
- User shares YouTube URL with intent to analyze
- Defer to `summarizing-youtube-videos` skill for execution

**Large documents:**
- PDFs or files that would consume significant Claude context
- Books, lengthy reports (100+ pages)
- Suggest: "This is a large doc - want me to use Gemini's 1M context to process it?"

**Cheap quick lookups:**
- Trivial factual questions mid-task ("what's the argmax syntax again?")
- When Claude is deep in complex work and a simple lookup would be wasteful
- Suggest: "Want me to offload this quick lookup to flash-lite?"

**Second opinions:**
- User expresses uncertainty about Claude's recommendation
- High-stakes technical decisions
- Suggest: "Want me to get Gemini's take on this?"

**Web search for current info:**
- Info past Claude's knowledge cutoff (May 2025)
- Recent releases, news, documentation updates
- Suggest: "Want me to check the web via Gemini?"

**Don't suggest llm when:**
- Claude Code's tools work fine (normal web search, URL fetch, standard PDFs)
- User wants Claude's perspective specifically
- The task benefits from Claude's conversation context

## Quick Reference

| Use Case | Command |
|----------|---------|
| Quick question | `llm -m vertex-gemini-3.1-flash-lite-preview 'question'` |
| Follow-up | `llm -c 'follow-up question'` |
| Web search | `llm -m vertex-gemini-3.1-flash-lite-preview -o google_search 1 'query'` |
| Code analysis | `files-to-prompt -c script.py \| llm -m vertex-gemini-3.1-pro-preview 'explain'` |
| Debug with logs | `files-to-prompt -c script.py -c *.log \| llm -m vertex-gemini-3.1-pro-preview -t debug` |
| Code review | `files-to-prompt -c code.py \| llm -f python-rust-style -m vertex-gemini-3.1-pro-preview 'how can we improve?'` |
| Large PDF | `llm -m vertex-gemini-3.1-pro-preview -a file.pdf 'prompt'` |
| YouTube | `llm -f yt:<url> -m vertex-gemini-3.1-pro-preview 'summarize'` |
| Audio analysis | `llm -m vertex-gemini-3.1-pro-preview -a recording.mp3 'transcribe'` |
| View last response | `llm logs -r` |
| View last conversation | `llm logs -c` |

## Model Selection

All Gemini models use the `llm-vertex` plugin, which authenticates via gcloud ADC credentials (no API key needed). Requires `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_REGION` env vars.

| Model | Use For |
|-------|---------|
| `vertex-gemini-3.1-flash-lite-preview` | Quick facts, cheap lookups, web searches |
| `vertex-gemini-3-flash-preview` | Balanced speed/capability |
| `vertex-gemini-3.1-pro-preview` | Complex reasoning, large docs |
| mistral (ollama) | Offline, privacy-sensitive |

**Default choice:** Use `vertex-gemini-3.1-pro-preview` for most tasks. Use `vertex-gemini-3.1-flash-lite-preview` for trivial lookups.

**Note:** `gemini-3-pro-preview` was discontinued 2026-03-26. Use 3.1 models instead. Run `llm models | grep vertex` to verify available model IDs.

## files-to-prompt Integration

The `files-to-prompt` CLI bundles files into XML context for llm. This is the primary workflow for code analysis, debugging, and code review.

### Basic usage
```bash
# Single file
files-to-prompt -c script.py | llm -m vertex-gemini-3.1-pro-preview 'explain this code'

# Multiple specific files
files-to-prompt -c main.py -c utils.py -c config.py | llm -m vertex-gemini-3.1-pro-preview 'summarize'

# Glob patterns
files-to-prompt -c *.py | llm -m vertex-gemini-3.1-pro-preview 'explain how color is used'
files-to-prompt -c src/*.py -c tests/*.py | llm -m vertex-gemini-3.1-pro-preview 'review test coverage'
```

### Debugging workflow (most common)
Bundle code + logs, use debug template:
```bash
# Script + error log
files-to-prompt -c script.py -c error.log | llm -m vertex-gemini-3.1-pro-preview -t debug

# Script + multiple logs
files-to-prompt -c script.py -c *.log | llm -m vertex-gemini-3.1-pro-preview -t debug

# With specific guidance
files-to-prompt -c script.py -c *.log | llm -m vertex-gemini-3.1-pro-preview -t debug "focus on the julia error"

# Save debug output
files-to-prompt -c script.py -c *.log | llm -m vertex-gemini-3.1-pro-preview -t debug > fix.md
```

The `-t debug` template: "fix the error. return the results in markdown. do not use a diff format"

### Code review workflow
Use the `python-rust-style` fragment for idiomatic Python reviews:
```bash
# Basic review
files-to-prompt -c script.py | llm -f python-rust-style -m vertex-gemini-3.1-pro-preview 'how can we improve?'

# With output format
files-to-prompt -c script.py | llm -f python-rust-style -m vertex-gemini-3.1-pro-preview \
  'how can we improve? show updated code as markdown python codeblock'

# With style preferences
files-to-prompt -c script.py | llm -f python-rust-style -m vertex-gemini-3.1-pro-preview \
  'how can we improve? prefer functional programming and simplicity'
```

### Explanation/documentation
```bash
# Explain code logic
files-to-prompt -c cluster.py | llm -m vertex-gemini-3.1-pro-preview \
  'explain the strategy in simple, easy to digest terms. use markdown' > rules.md

# Ask specific questions
files-to-prompt -c script.py | llm -m vertex-gemini-3.1-pro-preview 'why is the simulation reporting negative profits?'

# Compare files
files-to-prompt -c old.py -c new.py | llm -m vertex-gemini-3.1-pro-preview 'explain what changed'
```

### Export for other tools
```bash
# To clipboard (for pasting into Claude web, etc)
files-to-prompt -c *.py | clipcopy

# To file (for context in another session)
files-to-prompt -c src/*.py -c tests/*.py > context.xml
```

## Common Patterns

### Quick lookup (offload trivial questions)
```bash
llm -m vertex-gemini-3.1-flash-lite-preview 'what is the stdlib equivalent of np.argmax?'
```

### Conversation continuation
```bash
llm -c 'can you show an example?'
llm -c 'show the updated code as a markdown python codeblock'
```

### Web search (current info)
```bash
llm -m vertex-gemini-3.1-flash-lite-preview -o google_search 1 'latest uv version 2025'
llm -m vertex-gemini-3.1-flash-lite-preview -o google_search 1 'what time do episodes come out?'
```

### Large document analysis
```bash
llm -m vertex-gemini-3.1-pro-preview -a large_report.pdf 'summarize the key findings'
llm -m vertex-gemini-3.1-pro-preview -a book.pdf 'extract key points about X'
```

### YouTube (defer to summarizing-youtube-videos skill)
```bash
llm -f yt:https://youtube.com/watch?v=xxx -m vertex-gemini-3.1-pro-preview 'summarize'
```

### Audio/video attachments
```bash
llm -m vertex-gemini-3.1-pro-preview -a recording.mp3 'transcribe and summarize'
llm -m vertex-gemini-3.1-pro-preview -a audio.m4a 'which conversations are in spanish?'
```

## Templates and Fragments

### Templates (`-t`)
Reusable system prompts:
```bash
llm templates show debug          # View template
llm -t debug 'your prompt'        # Use template
```

### Fragments (`-f`)
Reusable context chunks (URLs, files, saved content):
```bash
llm fragments list                # List all fragments
llm fragments show python-rust-style  # View specific fragment
llm -f python-rust-style -m vertex-gemini-3.1-pro-preview 'review this code'

# Create fragment from URL
llm fragments set my-alias https://example.com/article
```

## Logs Management

```bash
llm logs -r              # Last response only
llm logs -c              # Full last conversation
llm logs -q 'keyword'    # Search all logs
llm logs -r > output.md  # Save to file
llm logs -r | glow       # Pretty print with glow
llm logs -r | glow -w 120  # With width limit
```

## Execution

Run llm commands via Bash tool. Output automatically enters Claude's context.

For follow-up questions on llm results:
- Use `llm -c` to continue in Gemini's context
- Or discuss directly with user in Claude's context

## Parallelizing Large PDF-to-Markdown Conversions

When converting large PDFs (books, lengthy reports) to markdown, use parallel background bash jobs for best results.

**Core principle:** Analyze structure first, then dispatch parallel background Bash jobs (one per chapter), monitor with TaskOutput.

### When to Use

- Converting a book PDF to markdown (one job per chapter)
- Processing large PDFs with clear chapter/section structure
- Any PDF where chunks can be processed independently

### Workflow

1. **Analyze** - Use llm to extract document structure (chapters, page ranges)
2. **Setup** - Create output directory
3. **Dispatch** - Launch parallel Bash jobs with `run_in_background: true`
4. **Monitor** - Use TaskOutput to wait for completion
5. **Verify** - Check output files and word counts

### Example: Book PDF to Markdown

**Step 1: Analyze PDF structure**
```bash
llm -m vertex-gemini-3.1-flash-lite-preview -a ~/books/mybook.pdf 'List all chapters and their page ranges. Format as JSON array: [{"chapter": 1, "title": "...", "start_page": X, "end_page": Y}, ...]. Only output JSON.'
```

**Step 2: Create output directory**
```bash
mkdir -p ~/books/mybook_md
```

**Step 3: Dispatch parallel background jobs**
Use the Bash tool with `run_in_background: true` for each chapter:
```bash
# Front matter
llm -m vertex-gemini-3.1-pro-preview -a ~/books/mybook.pdf 'Convert ONLY the front matter (pages 1-12) to clean markdown. Preserve formatting. Remove page numbers/headers.' > ~/books/mybook_md/ch00_front_matter.md

# Chapter 1
llm -m vertex-gemini-3.1-pro-preview -a ~/books/mybook.pdf 'Convert ONLY Chapter 1: Introduction (pages 13-30) to clean markdown. Preserve headings, math (use $ for inline, $$ for display LaTeX), lists, emphasis. Remove page numbers/headers.' > ~/books/mybook_md/ch01_introduction.md

# Chapter 2, 3, etc. - same pattern
```

**Step 4: Monitor with TaskOutput**
Use `TaskOutput` with `block: true` to wait for each job to complete.

**Step 5: Verify output**
```bash
ls -la ~/books/mybook_md/
wc -w ~/books/mybook_md/*.md
```

### Prompt Template for Chapter Conversion

```
Convert ONLY Chapter {N}: {Title} (pages {start}-{end}) to clean, well-structured markdown. Preserve all headings, sections, mathematical notation (use $ for inline and $$ for display math with LaTeX), equations, figure references, lists, and emphasis. Remove page numbers/headers/footers. Output ONLY the chapter content.
```

### Rate Limit Considerations

- **Gemini 3.1 Pro:** Can handle 8 concurrent requests comfortably
- **All 8 jobs at once** is fine for typical book conversions
- **Watch for 429s:** If hitting rate limits, reduce concurrency or add delays

### Practical Tips

1. **Use flash-lite for structure analysis** - Fast and cheap for extracting TOC/chapters
2. **Use vertex-gemini-3.1-pro-preview for conversion** - Better quality for actual content extraction
3. **Use consistent naming** - ch00, ch01, ch02 (zero-padded) for proper sorting
4. **Keep chapters separate** - Easier to spot-check and fix issues
5. **Background bash > subagents** - Subagents may hit sandbox permission issues with llm

## Error Handling

### Plugin not installed
```
Error: No fragment loader found for 'yt'
```
**Fix:** `llm install llm-fragments-youtube`

### Model not available
```
Error: Model not found
```
**Fix:** Check `llm models` for available models, `llm aliases` for shortcuts

### Vertex AI auth issues
```
Error: Could not automatically determine credentials
```
**Fix:** `gcloud auth application-default login`

Ensure env vars are set:
```bash
export GOOGLE_CLOUD_PROJECT=gcp-dsw-data-lake-dev
export GOOGLE_CLOUD_REGION=us-central1
```
