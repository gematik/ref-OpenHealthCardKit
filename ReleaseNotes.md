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


