# Release 5.7.0

## Changed

- Update to OpenSSL-Swift version to 4.2.0 (OpenSSL 3.2.1)

# Release 5.6.0

## Added

- New NFCHealthCardSession offers a structured concurrency API

## Other

- adapt app target NFCDemo to use the new NFCHealthCardSession API

# Release 5.5.0

## Added

- Extend HealthCardControl API to offer structured concurrency endpoints (more to come)

## Fixed

- Fix AID of EgkFileSystem.DF.HCA
- Fix wrong PIN input length for Change-Pin use case

# Release 5.4.0

## Changed

- Adapt for Xcode15 development

# Release 5.3.0

## Add

 - Package.swift added to project

## Changed

- For development include gematik owned dependencies via SPM (instead of Carthage)

# Release 5.2.1

## Added

 - Improved error display in app target
 - expose API for changing PIN without straining the PUK counter

# Release 5.1.0

## Fixed

 - Fix error state handling in demo app target

## Changed

- "Freeze" some `enums`
- Update to OpenSSL-Swift version to 4.0.0
- Change Xcode version to 14.0

# Release 5.0.0

## Breaking

  - Change `VerifyPinResponse` to bridge all possible verify responses

## Added

  - Add error type `CoreNFCError` for all errors occurring in CoreNFC
  - Add convenience interfaces for PIN-verification

## Changed

  - Change ResetRetryCounter to set a new PIN with ChangeReferenceDate

## Internals

 - Revive Integration Tests

# Release 4.1.0

## Added

  - Add reset retry counter for password

# Release 4.0.0

## Changed

  - Update to OpenSSL version 3.0.3 
  - Update to GemCommonsKit version 1.3
  - Update to ASN1Kit version 1.1.0
  - Change Xcode version to 13.3.1
  - Change OpenSSL Dependency to use Github (to enable binary download)


# Release 3.0.7

## Added

 - Add list of NFC reading results
 - Add details of a reading result with state and sent commandos 
 - Add share functionality of NFC reading result
 - Add new NFC reading layout
 
## Fixed

 - Fix CAN with leading zero
 - Fix dark mode 

## Changed

 - Change layout to use more standard elements and colors 

## Other

 - Update OpenSSL-swift dependency (uses OpenSSL 1.1.1n)

# Release 3.0.5

## feature

- App Icon

## bugfix

- fix dependencies for app target

# Release 3.0.3

## Features

- Use OpenSSL for crypto instead of custom ecc implementation
- extend `HealthCardCommands` and `HealthCardControl` to allow for signing a digest/hash as opposed to always transmitting the complete data block that needs to be hashed and signed on card

## Bugfixes

- Fix Secure Channel Communication bug with some cards (gemSpec_COS: N033.100,N033.200,N033.300,N033.400)
- Fix unfinished nfc stream when card is never read


## Internal

- Integrated NFC Demo Project

# Release 2.0.4

- fix dead links in README

# Release 2.0.2

- make use of Combine framework
- add swift package manager support

# Release 1.0.3

- bugfixes for communication through a secured card channel via NFC - remove embedding of dependencies from project.yml

# Release 1.0.2

- Consolidation of several projects into this one


