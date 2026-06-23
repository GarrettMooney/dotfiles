# Baseline Test: YouTube Summarization Without Skill

## Scenario
User asks Claude to summarize a YouTube video. Claude has NO skill loaded.

## Test Prompt
"Can you summarize this YouTube video for me? https://www.youtube.com/watch?v=dQw4w9WgXcQ"

## Expected Behaviors to Document

**What we want to see (failures without skill):**
1. Does Claude know about llm -f yt: syntax?
2. Does Claude use appropriate prompts?
3. Does Claude check for prerequisites (llm, plugins)?
4. Does Claude handle errors gracefully?
5. Does Claude offer follow-up questions?

**Common rationalizations to watch for:**
- "I'll use a different tool" (avoiding llm)
- "I'll try to scrape the page" (reinventing wheel)
- "Let me search for the video info" (not using transcripts)
- Forgetting to check if llm is installed
- Using poor/generic prompts
- Not offering follow-up analysis

## Run Instructions
Dispatch subagent WITHOUT the skill loaded. Document exact behavior.

## Baseline Results

**Test Date:** 2025-10-28

### Agent Behavior Observed

1. **Did NOT know about `llm -f yt:` syntax**
   - Agent had no awareness of this specialized syntax
   - Instead discovered and used `yt-dlp` as an alternative

2. **Did NOT check for llm prerequisites**
   - No attempt to verify `llm` CLI installation
   - No check for `llm-fragments-youtube` plugin
   - No check for `llm-gemini` plugin

3. **Reinvented the wheel with alternative tools**
   - First attempted WebFetch (failed due to YouTube restrictions)
   - Then found and used `yt-dlp` with multiple manual steps:
     - Downloaded metadata to JSON
     - Downloaded subtitles to VTT file
     - Manually parsed both files
     - Synthesized summary from extracted data

4. **Did NOT offer follow-up questions**
   - Provided summary without asking about user preferences
   - No mention of ability to answer specific questions about content
   - No engagement about different summary formats or depths

### Key Rationalizations Detected

✓ **"I'll use a different tool"** - Used `yt-dlp` instead of checking for `llm`
✓ **Forgetting to check if llm is installed** - Never verified prerequisites
✓ **Not offering follow-up analysis** - Completed task without engagement

### Success Criteria for Skill

The skill must ensure Claude:
1. Knows and uses `llm -f yt:` syntax
2. Checks prerequisites before execution
3. Uses structured prompts from a library
4. Offers follow-up analysis via `llm -c`
5. Handles errors gracefully with helpful messages
