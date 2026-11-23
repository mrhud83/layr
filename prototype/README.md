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

- AR, next to Drop, opens the AR view of everything on the map around you: objects and messages within 300 m, and every route within 600 m as a line on the ground with a ring at each stop. Undo sits at the top of the tool rail when there's something to undo.
- On iPhone, once an object appears in AR it stays locked to the ground and your view; GPS no longer moves it. The camera view measures your lens and the picture's lag while you turn (saved), so objects stop gliding against the picture. Objects appear at their map spot (GPS + compass), then GPS stops: your steps, counted by the motion sensor, carry you toward them (about 0.7 m a step). Apple AR (Quick Look) is an optional button; it holds to the floor but places the object in front of you, not at its map spot.
- After you drop something the map stays open with the pin selected, so you can drag it to fine-tune the spot.
- Guide people to it (objects and messages): None, Line (a glowing line on the ground to it in AR, along sidewalks when the free foot router knows them), Arrow (a floating arrow in AR that turns slowly toward it, with the distance), or Compass.
- Find it: three ways to get to any drop. Compass (a modest arrow that points at the next bend and counts down the walk), X-ray (a heading-up map of buildings, paths and your route fills the dial, with a small pointer on the rim) or AR path (opens AR with a glowing line on the ground to it, from any distance). Choose Sidewalks (suggested walking route) or Direct (straight there). Pocket mode turns the screen black, keeps it awake and speaks directions as you walk, steered by your walking direction. Locking the phone pauses it; browsers can't keep guiding with the screen locked.
- The drop panel is compact: one sideways strip of objects, then Sign and Details (title, range) chips and the guide choice.
- No labels float above objects. In New drop, "Add a sign" lets you write a short sign; it stands a foot to the side of the object at your eye height and turns to face you.
- Drag a 3D model or marker from the picker straight onto the map (on touch, hold it for a fifth of a second, then drag). The panel and buttons slide away while you drag.
- Drag any pin to move it. Select a route to drag its numbered waypoints. Every move can be undone from the toast.
- Routes draw as one continuous line that rises and falls with the terrain at a height you set (0.9 m by default, 0 to 3 m).
- Your floor (− and +) tells the line you're upstairs. It starts on your floor and eases down to the street. On iPhone, GPS altitude can guess it when you're inside a mapped building.
- One path: the orange line starts where you stand and runs ahead along the route; the part behind you is hidden. Step off and it re-plans from where you are back onto the route.
- Routes open in ground view: the path is a bright, steady band on the ground that fades a little with distance, with no raised line or stems. On Android, the band drapes onto the surfaces the camera finds as you look ahead (within 40 m); farther out it follows the elevation model. The view button cycles Ground, Line (raised at the line height) and Tunnel.
- Tunnel view sweeps a slightly see-through arch along the route: shifting rainbow aurora, colour-cycling ribs, amber ribs every 3 m, a pulse that runs ahead, and a see-through floor so you can watch your step.
- Terrain (next to Your floor) turns elevation off, so everything sits flat at your ground level. Within 40 m the ground is always flat at your level.
- iPhone camera mode: drag up or down to sink or lift the ground until it matches the real one. It's saved.
- The eye button in AR hides every control; tap it again to bring them back.
- X-ray shows the ground as a light green wire mesh from the elevation tiles, plus building shells and paths.
- Laser cannon: an interactive drop (opens from up to 150 m). It turns to follow you and fires red bolts that fly at 16 m/s, so a far cannon gives you more time. Keep moving and it lags and misses. Stand still and it locks on and fires once or twice a second. Ten hits and the view closes. Thin stems drop from the line to the ground. A cyan leg runs from you to the next waypoint and updates as you walk.
- Terrain heights come from the public AWS terrain tiles (Terrarium format, about 5 m resolution, no key). If they fail to load, the line runs flat.
- 13 detailed 3D models (fox with animation, plant, statues, lantern, street lamp, chest and more) with image-based lighting and contact shadows. Credits and licenses are in `models/CREDITS.md`.
- Six light line markers: pin, spot, ripple, caution, beacon, gift. Messages show as cards.
- The map starts empty. Nothing is placed until you drop it.
- The eye button hides every panel so you see the full map. On a keyboard, H toggles it.
- MAP and SAT switch between the street map and satellite imagery.

Drops are saved in the browser's local storage. "Copy share link" puts a drop in the URL so someone else can open it on their device.

Map tiles come from OpenStreetMap's public tile server, which is fine for light testing. Move to a hosted provider (see `docs/MVP_PLAN.md`) before sharing widely.
