# XeeSDK-iOS

iOS SDK for the Xee subscription server. It builds on MIT-licensed open-source code; LICENSE carries the upstream copyright notice.

- Products: `Xee`, `XeeLogger` (Swift Package Manager only; iOS 15+, macOS 12+, visionOS 1+).
- Public keys start with `xee_`. Requests send `Authorization: Api-Key <key>` and `xee-*` headers.

```swift
try await Xee.activate(withAPIKey: "xee_...")
try await Xee.identify("customer-1")
let profile = try await Xee.getProfile()
```

Maintenance: `scripts/audit.sh` fails if an upstream name remains outside LICENSE.

See LICENSE for the upstream notice.
