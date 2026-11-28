# dotmind iOS example

One screen: a live indicator replaying a scripted agent turn, then every state and scene.

```bash
brew install xcodegen
cd examples/ios
xcodegen generate
open DotMindExample.xcodeproj
```

The app depends on the Swift package at the repo root through a relative path, so library edits show up on the next build.
