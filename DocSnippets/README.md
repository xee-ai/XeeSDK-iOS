# DocSnippets

The Swift code the Xee docs show, compiled against this SDK. If a change to the SDK breaks a sample here, the build fails and the sample must be fixed before the change merges. The docs then take the fixed code from this folder; nobody pastes code into a docs page by hand.

## Where the docs come from

The docs are Markdown pages in the `xee-skills` repository (`plugin/skills/xee-docs/docs/`). A page marks a code block as one of these snippets:

````
```swift title="SwiftUI" snippet="activate-swiftui"
````

`node scripts/sync-snippets.mjs` in `xee-skills` copies the snippet into the block. `node scripts/sync-snippets.mjs --check` fails when a page is out of date, which is what CI runs.

## Writing a snippet

```swift
// snippet: activate-uikit
let configuration = XeeConfiguration.builder(withAPIKey: "xee_YOUR_SDK_KEY").build()
// end snippet
```

- The id is lowercase words joined by hyphens, and it is unique across this folder.
- A snippet is shown as written, dedented. Keep it what a reader would paste.
- A line ending in `// docs:hide` compiles here but is left out of the page. Use it for scaffolding such as a stub `ContentView`.
- Write `https://xee.example.test` where the page should say the reader's own server: the sync turns it into the `{{server}}` placeholder that the dashboard fills in.
- A snippet that needs a type the docs do not define (a `PaywallView`, a user model) declares a minimal one on `docs:hide` lines.

Build it for iOS from this folder (a separate package, so the SDK package stays what apps install):

```bash
xcodebuild -scheme XeeDocSnippets -destination 'generic/platform=iOS' build
```
