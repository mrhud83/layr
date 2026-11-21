# Layr web prototype

One HTML file. No build step, no backend, no keys.

## Try it

- On a computer, open `index.html` in a browser. If location is blocked you get a simulated location. Tap the map to walk around and tap a pin to open it.
- On a phone, the page needs HTTPS for GPS, the camera and WebXR. The free route is GitHub Pages:
  1. Merge to `main`.
  2. In the repo settings, open Pages and set the source to "GitHub Actions".
  3. The `Deploy prototype to GitHub Pages` workflow publishes this folder.

## What each device gets

| Device | AR mode | What holds the object in place |
|---|---|---|
| Android phone with Chrome and ARCore | WebXR with hit test and anchors | The phone's tracking. You can walk around the object. |
| iPhone (Safari has no WebXR) | Camera with motion sensors | Rotation only. It holds as you turn, not as you walk. |
| Desktop | 3D preview | Drag to orbit. |

Drops are saved in the browser's local storage. "Copy share link" puts a drop in the URL so someone else can open it on their device.

Map tiles come from OpenStreetMap's public tile server, which is fine for light testing. Move to a hosted provider (see `docs/MVP_PLAN.md`) before sharing widely.
