---
name: summarizing-youtube-videos
description: Use when user asks to summarize YouTube videos or analyze video content - provides llm command patterns, effective prompts, language handling, and follow-up question workflows using llm-fragments-youtube plugin
---

# Summarizing YouTube Videos

## Overview

Use the llm CLI with llm-fragments-youtube plugin to extract and summarize YouTube video transcripts via Gemini.

**Core principle:** YouTube videos with subtitles can be analyzed via their transcripts using `llm -f yt:<url>` syntax.

## When to Use

**Use this skill when:**
- User asks to "summarize this YouTube video"
- User provides YouTube URL with intent to analyze content
- User asks questions about video content
- User mentions analyzing video transcripts

**Don't use when:**
- User wants to download videos (not summarization)
- User wants to process audio directly (we use transcripts)
- Video is private/restricted (no public subtitles)

## Prerequisites Check

Before executing any llm commands, verify:

1. **llm CLI installed:** `which llm`
2. **llm-fragments-youtube plugin:** `llm plugins` (check output for llm-fragments-youtube)
3. **llm-vertex plugin:** `llm plugins` (check output for llm-vertex)

If missing, guide user:
- llm: `pip install llm`
- youtube plugin: `llm install llm-fragments-youtube`
- vertex plugin: `llm install llm-vertex`
- auth: `gcloud auth application-default login`

## Quick Reference

| Use Case | Command |
|----------|---------|
| Basic summary | `llm -f yt:<url> -m vertex-gemini-2.5-flash "Summarize this video with main points"` |
| Video ID only | `llm -f yt:dQw4w9WgXcQ -m vertex-gemini-2.5-flash "<prompt>"` |
| Full URL | `llm -f yt:https://www.youtube.com/watch?v=dQw4w9WgXcQ -m vertex-gemini-2.5-flash "<prompt>"` |
| Spanish subtitles | `llm -f yt:es:<url> -m vertex-gemini-2.5-flash "Resume el video"` |
| Follow-up question | `llm -c "What were the main technical points?"` |

## Prompts Library

### Default Summary Prompt
```
Provide a concise summary of this video including:
- Main topic and purpose
- Key points (3-5 bullets)
- Target audience
- Any actionable takeaways or conclusions
```

### Detailed Analysis Prompt
```
Provide a detailed analysis of this video:
1. Main thesis or argument
2. Supporting evidence and examples
3. Structure and flow
4. Strengths and weaknesses
5. Practical applications
```

### Technical Content Prompt
```
Summarize this technical video focusing on:
- Technologies/tools discussed
- Code examples or implementations shown
- Best practices mentioned
- Common pitfalls warned about
```

### Key Points Extraction
```
Extract the key points from this video as a bulleted list, organized by topic.
```

## Workflow

1. **Extract URL:** Get video URL or ID from user message
2. **Check prerequisites:** Verify llm and plugins installed
3. **Determine prompt:** Choose appropriate prompt based on user intent
4. **Execute command:** `llm -f yt:<url> -m vertex-gemini-2.5-flash '<prompt>'` via Bash tool
5. **Present results:** Show summary to user
6. **Offer follow-up:** Suggest `llm -c` for deeper questions if relevant

## Language Support

For non-English videos, use language code:

```bash
llm -f yt:es:<url> -m vertex-gemini-2.5-flash "Resume el video"  # Spanish
llm -f yt:fr:<url> -m vertex-gemini-2.5-flash "Résumez la vidéo"  # French
llm -f yt:de:<url> -m vertex-gemini-2.5-flash "Fassen Sie das Video zusammen"  # German
```

## Error Handling

### No Subtitles Available
```
Error from yt-dlp: No subtitles available
```
**Response:** "This video doesn't have subtitles available. Try specifying a language: `yt:<lang>:<url>`"

### Invalid URL
```
Error: Unable to extract video
```
**Response:** "The video URL appears invalid. Please provide a valid YouTube URL or video ID."

### Plugin Not Installed
```
Error: No fragment loader found for 'yt'
```
**Response:** "The llm-fragments-youtube plugin isn't installed. Install with: `llm install llm-fragments-youtube`"

### Private/Restricted Video
```
Error: This video is private/unavailable
```
**Response:** "This video is private or restricted. I can only summarize publicly accessible videos with subtitles."

## Follow-Up Analysis

After providing initial summary, offer follow-up:

"I can answer specific questions about this video using `llm -c`. For example:
- What were the specific code examples shown?
- Can you elaborate on the section about X?
- What were the main criticisms mentioned?"

Execute follow-ups with: `llm -c '<user-question>'`

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `-m vertex-gemini-2.5-flash` | Always specify vertex model explicitly |
| Not checking prerequisites | Run `which llm` and `llm plugins` first |
| Using generic prompts | Use specific prompts from library above |
| Not offering follow-ups | Always mention `llm -c` capability |
| Attempting without subtitles | Explain limitation gracefully |

## Example Usage

**User:** "Can you summarize this video? https://www.youtube.com/watch?v=dQw4w9WgXcQ"

**Claude:**
1. Checks: `which llm` → installed ✓
2. Checks: `llm plugins` → llm-fragments-youtube present ✓
3. Executes: `llm -f yt:dQw4w9WgXcQ -m vertex-gemini-2.5-flash "Provide a concise summary of this video including: main topic, key points (3-5 bullets), target audience, and actionable takeaways"`
4. Presents results
5. Offers: "I can answer follow-up questions about specific parts using `llm -c`"
