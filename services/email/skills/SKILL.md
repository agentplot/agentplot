---
name: email
description: Manage email via himalaya CLI — inbox triage, folder management, search, compose, reply, and workflow automation. Use when checking emails, organizing inbox, searching messages, composing replies, or managing email folders.
---

# Email Management Skill

Manage email accounts using the `email` CLI (himalaya wrapper).

Account configuration (IMAP/SMTP servers, credentials) is handled outside this skill. This skill covers email operations assuming accounts are already configured.

## Common Operations

### Inbox Management

```bash
# List recent messages in inbox
email list

# List messages with pagination
email list --page-size 20 --page 1

# List unread messages
email list --query "NOT SEEN"

# List messages from a specific folder
email list --folder "Archive"

# List flagged/starred messages
email list --query "FLAGGED"
```

### Reading Messages

```bash
# Read a specific message by ID
email read 42

# Read message in plain text format
email read 42 --text-mime plain

# Read message headers only
email read 42 --headers "From,Subject,Date"
```

### Search

```bash
# Search by subject
email search "quarterly report"

# Search by sender
email search --query "FROM admin@example.com"

# Search by date range
email search --query "SINCE 01-Jan-2024 BEFORE 01-Feb-2024"

# Complex search: unread from a specific sender
email search --query "UNSEEN FROM boss@example.com"
```

### Compose and Reply

```bash
# Compose a new message
email write --to "user@example.com" --subject "Meeting" --body "Let's schedule a call."

# Reply to a message
email reply 42

# Reply all
email reply 42 --all

# Forward a message
email forward 42 --to "team@example.com"
```

### Folder Management

```bash
# List all folders
email folders

# Move a message to a folder
email move 42 --to "Archive"

# Copy a message to a folder
email copy 42 --to "Important"

# Delete a message (move to trash)
email delete 42
```

### Flags and Status

```bash
# Mark as read
email flag set 42 --flag seen

# Mark as unread
email flag remove 42 --flag seen

# Star/flag a message
email flag set 42 --flag flagged

# Remove star
email flag remove 42 --flag flagged
```

### Attachments

```bash
# List attachments for a message
email attachments list 42

# Download attachments
email attachments download 42 --output-dir ./downloads
```

## Workflow Patterns

### Inbox Zero Triage

```bash
# 1. Check unread count
email list --query "NOT SEEN" --page-size 0

# 2. List unread messages
email list --query "NOT SEEN" --page-size 50

# 3. Process: archive, reply, flag, or delete each message
email move 42 --to "Archive"     # Processed
email flag set 43 --flag flagged  # Needs follow-up
email delete 44                   # Not needed
```

### Daily Email Review

```bash
# Messages from today
email list --query "SINCE $(date +%d-%b-%Y)"

# Important unread messages
email list --query "UNSEEN FLAGGED"
```
