---
id: TASK-3
title: >-
  Make XCTest async test entries homogeneous in
  CardSimulationCardReaderProviderTests
status: To Do
assignee: []
created_date: '2026-09-25 11:20'
labels: []
dependencies: []
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
testTCPClient_input_streaming is being made async, but testTCPClient_output_streaming remains synchronous. The allTests array must have homogeneous XCTest entry types or CardSimulationCardReaderProviderTests will fail to compile.
<!-- SECTION:DESCRIPTION:END -->
