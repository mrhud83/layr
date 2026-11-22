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
| iPhone | Objects and messages open in Apple AR Quick Look. Routes use camera mode. | ARKit pins objects to the floor. Routes hold as you turn and follow GPS as you walk. |
| Desktop | 3D preview | Drag to orbit. |

## What's in it

- Drag any pin to move it. Select a route to drag its numbered waypoints. Every move can be undone from the toast.
- Routes draw as one continuous line that follows the terrain at a height you set (0 to 3 m above ground). Thin stems drop from the line to the ground. A cyan leg runs from you to the next waypoint and updates as you walk.
- Terrain heights come from the public AWS terrain tiles (Terrarium format, about 5 m resolution, no key). If they fail to load, the line runs flat.
- 12 detailed 3D models (fox with animation, plant, statues, lantern, street lamp, chest and more) with image-based lighting and contact shadows. Credits and licenses are in `models/CREDITS.md`.
- Six light line markers: pin, spot, ripple, caution, beacon, gift. Messages show as cards.
- The map starts empty. Nothing is placed until you drop it.
- The eye button hides every panel so you see the full map. On a keyboard, H toggles it.
- MAP and SAT switch between the street map and satellite imagery.

Drops are saved in the browser's local storage. "Copy share link" puts a drop in the URL so someone else can open it on their device.

Map tiles come from OpenStreetMap's public tile server, which is fine for light testing. Move to a hosted provider (see `docs/MVP_PLAN.md`) before sharing widely.
