# dotmind iOS example

One screen: a Look picker (Classic, Icons, Pixel), a live indicator replaying a scripted agent turn, every state in the chosen look, the icons and pixel scenes, then the fixed scenes.

```bash
brew install xcodegen
cd examples/ios
xcodegen generate
open DotMindExample.xcodeproj
```

The app depends on the Swift package at the repo root through a relative path, so library edits show up on the next build.
