---
id: TASK-1
title: Explicitly select required Bundler version in scripts/bootstrap
status: To Do
assignee: []
created_date: '2026-09-25 11:20'
labels: []
dependencies: []
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Current guard only checks whether some bundle executable exists, not whether Bundler 4.0.20 is installed/selected. On nodes with pre-existing Ruby/Bundler, the install branch is skipped and unqualified bundle install runs against old toolchain despite lockfile requiring Bundler 4.0.20.
<!-- SECTION:DESCRIPTION:END -->
