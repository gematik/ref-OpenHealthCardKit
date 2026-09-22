---
id: TASK-2
title: Fix Brewfile xcodes formula to use tap-qualified reference
status: To Do
assignee: []
created_date: '2026-09-25 11:20'
labels: []
dependencies: []
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Use tap-qualified xcodes Homebrew formula instead of unqualified formula. The unqualified brew 'xcodes' does not match the installation source used by xcodes CLI. On fresh machines, brew bundle cannot resolve xcodes from configured sources, causing scripts/bootstrap to fail.
<!-- SECTION:DESCRIPTION:END -->
