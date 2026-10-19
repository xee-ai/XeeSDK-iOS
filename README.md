# XeeSDK-iOS

iOS SDK for the Xee subscription server. Derived from the Adapty iOS SDK 3.17.3 (MIT License, Copyright (c) 2020 Adapty Tech Inc.): same structure and wire format (paths and JSON keys), renamed to Xee, with the paywall builder removed.

- Products: `Xee`, `XeeLogger` (Swift Package Manager only; iOS 13+, macOS 11+, visionOS 1+).
- Public keys start with `xee_`. Requests send `Authorization: Api-Key <key>` and `xee-*` headers.

```swift
try await Xee.activate(withAPIKey: "xee_...")
try await Xee.identify("customer-1")
let profile = try await Xee.getProfile()
```

Maintenance: `scripts/import-adapty.sh` + `strip-builder.py` + `rename.py` rebuild the sources from upstream; `scripts/audit.sh` fails if Adapty branding or hosts remain.

See LICENSE for the upstream notice.
