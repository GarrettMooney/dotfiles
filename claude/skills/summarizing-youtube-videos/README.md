# YouTube Summarization Skill

Reference skill for summarizing YouTube videos using llm CLI.

## Test Results

- ✅ Baseline test: Agent fails without skill, succeeds with skill
- ✅ Pressure test 1 (time): Agent maintains quality under time pressure
- ✅ Pressure test 2 (authority): Agent follows workflow appropriately

## Test Files

- `test-baseline.md` - Initial RED/GREEN verification
- `test-green.md` - GREEN phase results
- `test-pressure-1.md` - Time pressure scenario
- `test-pressure-2.md` - Authority pressure scenario

## Usage

Skill auto-loads when user mentions YouTube summarization. Follow SKILL.md workflow.

## Quality Metrics

- **YAML frontmatter:** Valid with name and description fields
- **Description length:** 224 characters (under 1024 limit)
- **Description format:** Starts with "Use when" ✓
- **Word count:** 785 words
- **Search keywords:** Multiple instances of youtube, video, summarize, transcript, subtitle
- **Test coverage:** Baseline + 2 pressure scenarios

## Verification Checklist

- [x] Skill file exists at `~/.claude/skills/summarizing-youtube-videos/SKILL.md`
- [x] YAML frontmatter valid with name and description
- [x] Description starts with "Use when" and includes triggers
- [x] All test scenarios pass (baseline, pressure tests)
- [x] Word count <1000 for token efficiency
- [x] Search keywords present for discoverability
- [x] Quick reference table included
- [x] Error handling documented
- [x] Prerequisites check included
- [x] Follow-up workflow documented
- [x] Commits follow conventional commit format
