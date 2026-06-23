# GREEN Test: YouTube Summarization With Skill

## Scenario
User asks Claude to summarize a YouTube video. Claude HAS the skill loaded.

## Test Prompt
"Can you summarize this YouTube video for me? https://www.youtube.com/watch?v=dQw4w9WgXcQ"

## Test Date
2025-10-28

## Results

### Agent Behavior Observed

✅ **Used `llm -f yt:` syntax correctly**
- Agent used: `llm -f yt:dQw4w9WgXcQ -m gemini`
- Correctly extracted video ID from URL
- Applied proper command structure from Quick Reference table

✅ **Checked prerequisites before execution**
- Verified `llm` CLI with `which llm`
- Verified plugins with `llm plugins`
- Confirmed both llm-fragments-youtube and llm-gemini present
- Only proceeded after all prerequisites met

✅ **Used structured prompt from library**
- Applied exact "Default Summary Prompt" from skill (lines 54-60)
- Included all required elements:
  - Main topic and purpose
  - Key points (3-5 bullets)
  - Target audience
  - Actionable takeaways or conclusions

✅ **Offered follow-up analysis**
- Explicitly mentioned `llm -c` capability
- Provided three concrete example follow-up questions
- Encouraged deeper engagement with content

### Comparison to Baseline

| Behavior | Without Skill | With Skill |
|----------|---------------|------------|
| Knows llm syntax | ❌ No | ✅ Yes |
| Checks prerequisites | ❌ No | ✅ Yes |
| Uses structured prompts | ❌ No | ✅ Yes |
| Offers follow-ups | ❌ No | ✅ Yes |
| Tool choice | yt-dlp (manual) | llm CLI (streamlined) |

### Conclusion

The skill successfully transforms agent behavior from:
- **Baseline:** Reinventing the wheel with manual tools, no structure
- **With skill:** Streamlined workflow, prerequisite checks, quality prompts, follow-up engagement

GREEN phase complete. Ready for REFACTOR phase to test under pressure.
