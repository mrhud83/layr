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
| Android phone with Chrome and ARCore | WebXR with hit test and anchors | Objects appear at their map position (GPS + compass) and are anchored the moment they appear. You can walk around them. |
| iPhone | Within about 12 m, objects open in Apple AR Quick Look. Farther away, and for the laser cannon, camera mode shows them at their map position. Routes use camera mode. | Quick Look pins objects to the floor. Camera mode holds as you turn and follows GPS as you walk. |
| Desktop | 3D preview | Drag to orbit. |

## What's in it

- Drag any pin to move it. Select a route to drag its numbered waypoints. Every move can be undone from the toast.
- Routes draw as one continuous line that rises and falls with the terrain at a height you set (0.9 m by default, 0 to 3 m).
- Your floor (− and +) tells the line you're upstairs. It starts on your floor and eases down to the street. On iPhone, GPS altitude can guess it when you're inside a mapped building.
- Tunnel view sweeps a solid arch along the route: aurora inside, amber ribs every 3 m, a pulse that runs ahead, and a see-through floor so you can watch your step.
- X-ray shows the ground as a light green wire mesh from the elevation tiles, plus building shells and paths.
- Laser cannon: an interactive drop (opens from up to 150 m). It turns to follow you and fires red bolts that fly at 24 m/s, so a far cannon gives you more time. Keep moving and it lags and misses. Stand still and it locks on and fires once or twice a second. Four hits and the view closes. Thin stems drop from the line to the ground. A cyan leg runs from you to the next waypoint and updates as you walk.
- Terrain heights come from the public AWS terrain tiles (Terrarium format, about 5 m resolution, no key). If they fail to load, the line runs flat.
- 13 detailed 3D models (fox with animation, plant, statues, lantern, street lamp, chest and more) with image-based lighting and contact shadows. Credits and licenses are in `models/CREDITS.md`.
- Six light line markers: pin, spot, ripple, caution, beacon, gift. Messages show as cards.
- The map starts empty. Nothing is placed until you drop it.
- The eye button hides every panel so you see the full map. On a keyboard, H toggles it.
- MAP and SAT switch between the street map and satellite imagery.

Drops are saved in the browser's local storage. "Copy share link" puts a drop in the URL so someone else can open it on their device.

Map tiles come from OpenStreetMap's public tile server, which is fine for light testing. Move to a hosted provider (see `docs/MVP_PLAN.md`) before sharing widely.
