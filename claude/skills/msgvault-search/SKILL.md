---
name: msgvault-search
description: Use when searching the user's local email/message archive — finding emails or messages by keyword, sender, subject, or date. Queries the msgvault SQLite database at ~/.msgvault/msgvault.db via sqlite3, using the messages_fts full-text index joined to messages and message_bodies.
---

# MsgVault Search Skill

This skill provides instructions for querying the `msgvault` database. 
`msgvault` is a local SQLite database that stores emails and messages.

## Location
The database is located at: `/Users/garrettmooney/.msgvault/msgvault.db`

## Schema Overview
- `messages`: Core metadata (`id`, `sent_at`, `subject`, `message_type`, `sender_id`).
- `message_bodies`: Contains `body_text` and `body_html` joined on `message_id`.
- `participants`: Contains sender/recipient details (`id`, `display_name`).
- `messages_fts`: FTS5 virtual table for full-text search (`message_id`, `subject`, `body`, `from_addr`, `to_addr`).

## Searching Messages
Use the `bash` tool to execute `sqlite3` queries. The best way to search is using the `messages_fts` table, joined with `messages` and `message_bodies` for context.

Example query to find emails matching a keyword:
```bash
sqlite3 -header -box /Users/garrettmooney/.msgvault/msgvault.db "
SELECT 
  m.id, 
  m.sent_at,
  m.subject, 
  p.display_name as sender,
  fts.from_addr,
  substr(mb.body_text, 1, 500) as body_snippet
FROM messages_fts fts
JOIN messages m ON fts.message_id = m.id
JOIN message_bodies mb ON m.id = mb.message_id
LEFT JOIN participants p ON m.sender_id = p.id
WHERE messages_fts MATCH 'your_search_keyword'
ORDER BY m.sent_at DESC
LIMIT 5;
"
```

## Guidelines
- Always use `messages_fts` with `MATCH` for efficient text searching.
- Always `ORDER BY m.sent_at DESC` to get the most recent messages first.
- Use `substr()` on `body_text` if you only need a snippet, as full email bodies can be very large.
