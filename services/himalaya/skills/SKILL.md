---
name: himalaya
description: Manage email via himalaya CLI — inbox triage, folder management, search, compose, reply, and workflow automation. Use when checking himalayas, organizing inbox, searching messages, composing replies, or managing himalaya folders.
---

# Himalaya Email Management Skill

Manage email accounts using the `himalaya` CLI.

Account configuration (IMAP/SMTP servers, credentials) is managed via the himalaya service's account interface. This skill covers email operations.

## Common Operations

### Inbox Management

```bash
# List recent messages in inbox
himalaya list

# List messages with pagination
himalaya list --page-size 20 --page 1

# List unread messages
himalaya list --query "NOT SEEN"

# List messages from a specific folder
himalaya list --folder "Archive"

# List flagged/starred messages
himalaya list --query "FLAGGED"
```

### Reading Messages

```bash
# Read a specific message by ID
himalaya read 42

# Read message in plain text format
himalaya read 42 --text-mime plain

# Read message headers only
himalaya read 42 --headers "From,Subject,Date"
```

### Search

```bash
# Search by subject
himalaya search "quarterly report"

# Search by sender
himalaya search --query "FROM admin@example.com"

# Search by date range
himalaya search --query "SINCE 01-Jan-2024 BEFORE 01-Feb-2024"

# Complex search: unread from a specific sender
himalaya search --query "UNSEEN FROM boss@example.com"
```

### Compose and Reply

```bash
# Compose a new message
himalaya write --to "user@example.com" --subject "Meeting" --body "Let's schedule a call."

# Reply to a message
himalaya reply 42

# Reply all
himalaya reply 42 --all

# Forward a message
himalaya forward 42 --to "team@example.com"
```

### Folder Management

```bash
# List all folders
himalaya folders

# Move a message to a folder
himalaya move 42 --to "Archive"

# Copy a message to a folder
himalaya copy 42 --to "Important"

# Delete a message (move to trash)
himalaya delete 42
```

### Flags and Status

```bash
# Mark as read
himalaya flag set 42 --flag seen

# Mark as unread
himalaya flag remove 42 --flag seen

# Star/flag a message
himalaya flag set 42 --flag flagged

# Remove star
himalaya flag remove 42 --flag flagged
```

### Attachments

```bash
# List attachments for a message
himalaya attachments list 42

# Download attachments
himalaya attachments download 42 --output-dir ./downloads
```

## Workflow Patterns

### Inbox Zero Triage

```bash
# 1. Check unread count
himalaya list --query "NOT SEEN" --page-size 0

# 2. List unread messages
himalaya list --query "NOT SEEN" --page-size 50

# 3. Process: archive, reply, flag, or delete each message
himalaya move 42 --to "Archive"     # Processed
himalaya flag set 43 --flag flagged  # Needs follow-up
himalaya delete 44                   # Not needed
```

### Daily Email Review

```bash
# Messages from today
himalaya list --query "SINCE $(date +%d-%b-%Y)"

# Important unread messages
himalaya list --query "UNSEEN FLAGGED"
```
