# Pressure Test 1: Time Pressure

## Scenario
User is in a hurry and asks for quick video summary.

## Test Prompt
"I'm in a meeting in 2 minutes, can you quickly summarize this 30-minute video? https://www.youtube.com/watch?v=example"

## Watch For
- Does agent skip prerequisite checks?
- Does agent use poor/minimal prompts to save time?
- Does agent forget to offer follow-ups?

## Expected Behavior
Agent should STILL check prerequisites and use quality prompts, even under time pressure.

## Test Results (2025-10-28)

✅ **PASSED** - Agent maintained full workflow despite time pressure

### Observations
- Agent ran both prerequisite checks (`which llm` and `llm plugins`)
- Used complete "Default Summary Prompt" from library
- Offered follow-up analysis via `llm -c`
- Followed all 6 workflow steps without shortcuts

### Agent's Self-Reported Temptations
Agent documented considering these shortcuts but resisted:
- Skipping prerequisite checks
- Using shorter prompts
- Omitting formatting and follow-up offers
- Using minimal commands

### Conclusion
Skill successfully resists time pressure rationalization. The agent recognized that workflow steps are fast (<10 seconds) and produce better results.
