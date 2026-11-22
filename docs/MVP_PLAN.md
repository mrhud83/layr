# Layr MVP plan

Layr lets anyone pick a spot on a map, drop a 3D object, an animation, a message, or a route there, and have other people find it and open it in AR when they arrive.

This plan covers the first MVP. It has three hard requirements:

1. Zero cost to build and run at MVP scale.
2. Content that stays fixed to the world. No sliding, no swimming, no drifting with GPS.
3. A simple core loop: drop on a map, walk there, open it in front of you. Precise positioning through VPS is an optional upgrade on top of that loop.

---

## 1. The core idea that makes it feel solid

Most location AR apps slide because they position content from GPS every frame. Phone GPS is off by 5 to 20 meters and the compass by 10 to 30 degrees, and both wander. If the object's pose follows those readings, it swims.

Layr separates two problems:

- **Finding** content uses GPS. It only has to be good enough to tell you "you're within 30 m, tap to open."
- **Holding** content in place uses the phone's visual-inertial tracking (ARKit on iOS, ARCore on Android). Once an object is placed, it is attached to an AR anchor in the local tracking space and never moved by GPS again. VIO is accurate to centimeters over the area a person walks around in, so the object stays put.

Every content item therefore has two placement modes.

| Mode | When | Where the object appears | Accuracy |
|---|---|---|---|
| Proximity reveal (default) | Always available. No VPS coverage needed. | On the ground in front of the viewer, 2 to 3 m away, facing them | Stable to the cm once placed. Location is "near the pin." |
| Precise (VPS) | The creator placed it on site with VPS, and the viewer has VPS coverage | At the exact lat/lng/altitude/heading the creator chose | Typically under 1 m and a few degrees, depending on VPS quality |

If a precise item can't localize (no coverage, bad light, indoors), it falls back to proximity reveal automatically. The viewer always gets something.

### Perceptual cues that sell "stuck"

Tracking stability is half of it. The other half is rendering cues that tell the brain the object is in the room:

- A contact shadow under every object (a transparent shadow-catcher plane on the detected floor).
- Light estimation from ARKit/ARCore applied to the scene light.
- Environment occlusion where the device supports depth (LiDAR iPhones, ARCore Depth API devices). People and walls hide the object correctly.
- Objects sit on a detected plane, never floating at a guessed height.
- A short "settle" animation on spawn (scale up and drop 5 cm) so placement reads as intentional instead of a pop.

---

## 2. Technology choices

All of these are free at MVP scale. Check each vendor's pricing page before launch, since free tiers change.

| Layer | Choice | Why | Cost |
|---|---|---|---|
| App engine | Unity 6 (Personal) with AR Foundation 6 | One codebase for iOS and Android. AR Foundation wraps native ARKit/ARCore, so tracking quality matches a native app. | Free under Unity's revenue threshold |
| VPS | Google ARCore Geospatial API via ARCore Extensions for Unity | Works on both iOS and Android, covers wherever Google has Street View imagery, gives terrain and rooftop anchors. | No usage charge at time of writing. Quota of 1,000 sessions/min per project. Needs a Google Cloud project and API key. |
| 3D loading | glTFast (Unity package) | Runtime GLB loading with embedded animations, Draco and meshopt compression. | Free, open source |
| Backend | Supabase (Postgres + PostGIS, Auth, Edge Functions) | Real geospatial queries (`ST_DWithin`), row-level security, anonymous auth. | Free tier: 500 MB DB, 50k MAU |
| Asset storage | Cloudflare R2 | 10 GB free and zero egress fees. GLB downloads would burn through Supabase's 5 GB egress fast. | Free tier |
| Map tiles | MapTiler Cloud free tier (raster tiles), behind a `ITileProvider` interface | Simple slippy map in Unity. Swappable for Stadia, Protomaps, or Google Map Tiles later. | Free tier |
| Starter content | CC0 model packs (Kenney, Quaternius, Poly Pizza CC0 items) | Gives creators something to drop on day one without uploading. | Free, public domain |
| CI | GitHub Actions | Builds, tests, and a weekly ping so the free Supabase project doesn't pause. | Free for this usage |

### Things that aren't free, and the workaround

- **iOS distribution.** You can run the app on your own iPhone with a free Apple ID, but the build expires every 7 days. TestFlight and the App Store need the $99/year Apple Developer Program. For a $0 MVP, test on your own devices and pay only when you're ready for outside testers.
- **Google Play.** A one-time $25 fee. Sideloading an APK to testers costs nothing.
- **Supabase pause.** Free projects pause after 7 days without activity. A scheduled GitHub Action that hits the API weekly prevents it.

### Why not WebAR

iOS Safari still doesn't support WebXR immersive AR, and 8th Wall, the main commercial workaround, has shut down. Web-based AR on iPhone also can't access ARKit's tracking quality or Google's VPS. A native app is the only way to meet the "firmly stuck" bar on both platforms.

### Why not two native apps

Swift + Kotlin would give the best possible integration, but doubles the work. AR Foundation exposes the same ARKit and ARCore tracking underneath, so the object stability is the same. Unity also handles GLB rendering and animation in one place. Revisit if Unity becomes a bottleneck for the map and UI screens (see risks).

---

## 3. Architecture

```
┌────────────────────────── Unity app (iOS + Android) ──────────────────────────┐
│                                                                               │
│  Map screen          Create flow           AR session                         │
│  - slippy map        - pick type           - AR Foundation (ARKit/ARCore)     │
│  - nearby pins       - pick model/text     - Plane, depth, light managers     │
│  - in-range badge    - set radius          - Geospatial (optional, ARCore Ext)│
│        │                    │              - Placement controller             │
│        └──────────┬─────────┘              - glTFast loader + disk cache      │
│                   │                                   │                       │
│            LayrClient (REST, typed models)  ◄─────────┘                       │
└───────────────────┬───────────────────────────────────────────────────────────┘
                    │ HTTPS
     ┌──────────────┴──────────────┐            ┌───────────────────┐
     │ Supabase                    │            │ Cloudflare R2     │
     │ - Auth (anon + magic link)  │  presigned │ - GLB files       │
     │ - Postgres + PostGIS        │ ─────────► │ - thumbnails      │
     │ - RPC: drops_nearby, etc.   │   upload   └───────────────────┘
     │ - Edge Function: sign_upload│
     └─────────────────────────────┘
                                                ┌───────────────────┐
             AR session ──────────────────────► │ Google Geospatial │
                                                │ (VPS, optional)   │
                                                └───────────────────┘
```

### Repository layout

```
layr/
  app/                 Unity project
    Assets/Layr/
      Map/             tile renderer, pin layer, location service
      Create/          creation flow UI and state
      AR/              session bootstrap, placement, anchoring, geospatial
      Content/         renderers per content type (model, message, route)
      Net/             LayrClient, DTOs, auth, caching
      Tests/           edit-mode and play-mode tests
  backend/
    supabase/
      migrations/      SQL schema, PostGIS, RLS policies
      functions/       edge functions (sign_upload, report)
    scripts/           seed data, keep-alive ping
  content/             curated CC0 starter models + manifest.json
  docs/
```

---

## 4. Data model

```sql
create extension if not exists postgis;

create type drop_kind as enum ('model', 'message', 'route');
create type placement_mode as enum ('proximity', 'precise');

create table drops (
  id              uuid primary key default gen_random_uuid(),
  owner_id        uuid not null references auth.users(id),
  kind            drop_kind not null,
  title           text not null check (char_length(title) <= 80),

  -- where it is on the map (always set)
  location        geography(Point, 4326) not null,
  reveal_radius_m integer not null default 30 check (reveal_radius_m between 10 and 200),

  -- precise placement (set only when created on site with good VPS)
  placement       placement_mode not null default 'proximity',
  altitude_m      double precision,          -- WGS84 ellipsoid or terrain-relative, see anchor_type
  anchor_type     text check (anchor_type in ('terrain', 'rooftop', 'wgs84')),
  heading_deg     double precision,          -- object yaw, 0 = north
  vps_h_acc_m     real,                      -- horizontal accuracy at authoring time
  vps_yaw_acc_deg real,                      -- heading accuracy at authoring time

  -- content
  payload         jsonb not null,            -- see payload shapes below
  scale           real not null default 1.0,

  visibility      text not null default 'public' check (visibility in ('public', 'unlisted')),
  created_at      timestamptz not null default now(),
  expires_at      timestamptz,
  hidden          boolean not null default false   -- set by moderation
);

create index drops_location_gix on drops using gist (location);
```

Payload shapes:

```jsonc
// model
{ "asset_key": "models/abc123.glb", "thumb_key": "thumbs/abc123.jpg",
  "animation": "Idle", "loop": true, "tris": 18000, "bytes": 2400000 }

// message
{ "text": "Look up. The hawk nests here every spring.", "style": "card", "color": "#FFD23F" }

// route: ordered waypoints, rendered as arrows + a path ribbon
{ "points": [[lng, lat], [lng, lat], ...], "label": "Short loop to the overlook" }
```

Core RPCs (Postgres functions called from the app):

- `drops_nearby(lat, lng, radius_m, limit)` returns pins for the map with distance, sorted nearest first.
- `drop_detail(id)` returns the full record plus short-lived signed asset URLs.
- `create_drop(...)` validates input server-side and inserts.

Row-level security: anyone (including anonymous users) can read public, non-hidden drops. Only the owner can update or delete their own.

---

## 5. User flows

### 5.1 Drop from the map (remote, proximity mode)

1. Open the map. Long-press a spot. A pin appears.
2. Choose what to drop: a model from the starter library (or upload a GLB), a message, or a route.
3. Set the reveal radius (default 30 m) and a title.
4. Save. The pin is live for everyone.

### 5.2 Find and open (the main loop)

1. The map shows nearby pins. Each one shows distance.
2. The app treats you as in range when `distance - gps_accuracy <= reveal_radius`. This stops people from being locked out by a bad GPS fix right next to the pin.
3. When in range, the pin turns active and an "Open" button appears. Optional local notification when the app is in the foreground.
4. Tap Open. The app has already prefetched the asset (see 6.4), so the AR view starts with content ready.
5. AR view: "Point at the ground" prompt until a horizontal plane is found (usually 1 to 2 seconds).
6. The object spawns 2.5 m ahead on the plane, facing the viewer, attached to an anchor. It stays there while you walk around it.
7. If the drop is precise and Geospatial is available, step 6 is replaced by the precise flow below.

### 5.3 Place on site with VPS (precise mode)

1. Creator stands at the spot and taps "Place here."
2. The app starts Geospatial and shows a localization meter. It waits until horizontal accuracy is under 1.5 m and yaw accuracy under 5 degrees. Below that, it offers "Place anyway (approximate)" which saves a proximity drop.
3. Creator positions and rotates the object on the ground with drag and twist gestures.
4. On save, the app converts the object's local pose to a geospatial pose and stores lat, lng, terrain-relative altitude, heading, and the accuracy values.

### 5.4 Open a precise drop

1. When in range, the AR view starts Geospatial and shows "Look at nearby buildings" while it localizes.
2. Once accuracy meets the thresholds, the app resolves a terrain anchor (or rooftop anchor) at the stored pose.
3. Stability handling, described in 6.2.
4. If localization doesn't reach the thresholds within 15 seconds, it offers "Show it here instead" and falls back to proximity reveal.

---

## 6. AR implementation details

### 6.1 Proximity placement

- Use `ARRaycastManager` from screen center against detected planes, then step forward to 2.5 m along the camera's flattened forward vector, and raycast again downward to hit the floor.
- Create an `ARAnchor` at the hit pose and parent the content under it. Never set the content's world position again after that.
- Rotate the content to face the camera on the Y axis only.
- If no plane is found after 5 seconds, use a fallback anchor at estimated floor height (camera height minus 1.4 m) and keep refining when a plane appears. Refining here means moving the anchor once, with a short ease, not continuously.

### 6.2 Geospatial placement without jitter

Geospatial anchors are corrected by Google's VPS as it refines its estimate. Those corrections are what can make content hop. The plan:

1. Don't resolve until accuracy is good (thresholds in 5.3). Track `horizontalAccuracy` and `orientationYawAccuracy` from `AREarthManager.CameraGeospatialPose`.
2. Resolve with `ResolveAnchorOnTerrainAsync` so altitude comes from Google's terrain model, not from the authoring phone's barometer.
3. After it resolves, keep the geospatial anchor as the source of truth, but render the content through a smoothing parent:
   - If the anchor's pose changes by less than 2 cm or 0.5 degrees, ignore it.
   - If it changes by more, ease toward the new pose over 300 ms.
   - If it jumps by more than 1 m (a VPS relocalization), fade out, snap, fade in. A visible fade reads as intentional. A slide reads as broken.
4. Once accuracy has been stable for 3 seconds, optionally "lock" by creating a local `ARAnchor` at the current pose and stop following geospatial updates for the rest of the session. Make lock-vs-follow a setting so it can be tested in the field.

### 6.3 Content rendering

- URP mobile renderer. Target 60 fps on a mid-range 2021 phone (Pixel 6, iPhone 12).
- Model budget for user uploads: 10 MB GLB, 100k triangles, 2048 px textures max. Validate on upload. Recommend `gltf-transform` compression (meshopt + KTX2) in the upload guide.
- Animations: glTFast imports GLB animations as legacy or Mecanim clips. Play the named clip from the payload, looping if set.
- Messages: a world-space card on a thin post, readable from 5 m, billboarding on Y only.
- Routes: in the map view, a polyline. In AR, arrows on the ground pointing toward the next waypoint, placed relative to the viewer using compass heading. Routes are inherently GPS-scale, so they're "guidance" content, not precise content, in the MVP.

### 6.4 Prefetch and cache

- When a drop comes within 200 m, download its asset in the background to a disk cache keyed by `asset_key` plus content hash.
- LRU cache capped at 500 MB.
- The Open button only appears once the asset is cached, or shows a progress ring while it finishes.

### 6.5 Session reliability

- One `ARSession` for the lifetime of the AR screen. Pause on background, resume on foreground, and check `ARSession.state` for tracking loss.
- On limited tracking, show "Move your phone slowly" and hide nothing. ARKit and ARCore recover anchors after tracking returns.
- Check device support at startup (`ARSession.CheckAvailability`) and Geospatial support separately (`AREarthManager.IsGeospatialModeSupported`). Unsupported devices still get map browsing.

---

## 7. Moderation and safety (minimum viable)

Public AR content in physical places needs a floor of safety from day one:

- Report button on every drop. Three reports auto-hide pending review.
- Blocklist on message text.
- Uploads require a signed-in (non-anonymous) account. Viewing doesn't.
- Rate limit: 20 drops per user per day.
- No drops inside a small radius of schools and hospitals. Start with a manual exclusion list, add an OpenStreetMap-derived list later.
- Safety prompt in AR: "Watch your surroundings." Don't spawn content in a roadway when a road layer is available (post-MVP).
- Privacy: don't store viewer location history. Location is used client-side and in the nearby query only.

---

## 8. Build phases

Times assume one developer working part-time. Each phase ends with something you can hold in your hand and test outdoors.

### Phase 0. Spike the risky part (1 to 2 weeks)

Goal: prove the "stuck" feeling before building anything else.

- Unity 6 project with AR Foundation 6 and ARCore Extensions, URP.
- Scene that places a CC0 GLB on a detected plane with a contact shadow and light estimation.
- Same scene with Geospatial enabled. Hardcode a lat/lng near you, resolve a terrain anchor, apply the smoothing from 6.2.
- Build to one iPhone and one Android phone.
- Exit test: walk a 5 m circle around the object. It shouldn't visibly move. For Geospatial, it should appear within about 1 m of the hardcoded spot in a Street View-covered area.

### Phase 1. Backend and map (2 weeks)

- Supabase project, migrations from section 4, RLS, RPCs.
- R2 bucket and the `sign_upload` edge function.
- Seed 20 drops around your area.
- Unity map screen: slippy tiles, user dot, pins from `drops_nearby`, distance labels.
- Anonymous auth on first launch.

### Phase 2. Core loop, proximity mode (2 weeks)

- Create flow for model (from starter library) and message.
- In-range detection with the accuracy-aware rule.
- Prefetch and cache.
- Open into AR, proximity placement.
- Exit test: a friend drops something at a park, you walk there, open it, walk around it.

### Phase 3. Precise mode (2 weeks)

- On-site placement with localization meter and gesture editing.
- Precise resolve on open, with fallback.
- Lock-vs-follow setting.
- Exit test: two phones, one creator and one viewer, see the object in the same spot within about 1 m.

### Phase 4. Routes, uploads, polish (2 weeks)

- Route content type.
- GLB upload with validation.
- Occlusion where supported.
- Report and hide.
- Onboarding: three screens explaining drop, find, open.

### Phase 5. Field test (1 to 2 weeks)

- 10 to 20 testers, sideloaded Android builds and your own iOS devices.
- Instrumentation (section 9). Fix the top issues.

Total: roughly 10 to 12 weeks part-time.

---

## 9. How to measure "super reliable"

Ship these metrics from Phase 2 on. Store them in a Supabase `events` table (anonymous, no location history).

| Metric | Target for MVP |
|---|---|
| Time from tapping Open to object visible | Under 3 s for proximity, under 10 s for precise |
| Proximity open success rate | Over 98% |
| Precise localization success (in VPS coverage) | Over 85% within 15 s |
| Anchor drift during a session | Under 5 cm over a 2-minute walk-around (measured in a test scene against a printed marker) |
| Crash-free sessions | Over 99.5% |
| Frame rate in AR | 60 fps median, 45 fps p5 |

### Testing approach

- **Edit-mode tests** for pure logic: in-range rule, geodesic math, payload validation, smoothing filter.
- **AR Foundation XR Simulation** in the Unity editor for placement flows without a phone.
- **ARCore Recording and Playback** to capture real outdoor sessions once and replay them in automated play-mode tests on an Android device. This is the best tool for catching regressions in the anchoring code.
- **Field checklist** per release: one walk-around test per content type, one precise test at a fixed reference spot.

---

## 10. Risks and decisions to watch

| Risk | Impact | Mitigation |
|---|---|---|
| Google changes Geospatial API pricing or terms | Precise mode gets expensive | VPS is optional by design. Proximity mode keeps the product working. Keep geospatial code behind an `IVpsProvider` interface so another provider can slot in. |
| VPS coverage gaps (parks, rural, indoors) | Precise drops fail | Automatic fallback to proximity. Show creators a coverage indicator while placing (`AREarthManager.CheckVpsAvailabilityAsync`). |
| Map UI in Unity feels clunky | Worse first impression than native maps | Keep the map layer thin. If it becomes a problem, embed Unity as a library inside a native or Flutter shell that owns the map screens. |
| Free tiers run out | Unexpected bills | R2 for assets removes the main egress risk. Set billing alerts. Supabase free has hard caps, not overage charges. |
| Users upload copyrighted or inappropriate models | Legal and trust problems | Signed-in uploads only, report and hide, terms of use that require users to own or have rights to uploads. Starter library is CC0 only. |
| 7-day iOS dev builds | Testing friction | Accept it during Phases 0 to 4. Budget $99 for the Apple program at Phase 5 if you want outside iOS testers. |

---

## 11. Out of scope for the MVP

- Indoor precise placement (ARCore Cloud Anchors are free and could cover this in v2).
- Multi-user live sessions where people see each other's edits in real time.
- Collections, trails, or quests that chain drops together.
- Social features: follows, likes, comments.
- In-app 3D editor beyond position, rotation, and scale.
- Web viewer. A web map for browsing drops is cheap to add later. WebAR viewing waits until iOS supports it.

---

## 12. First week checklist

1. Create a Google Cloud project, enable the ARCore API, create an API key restricted to the app's bundle IDs.
2. Create a Supabase project and a Cloudflare account with an R2 bucket.
3. Install Unity 6 LTS with iOS and Android build support.
4. New URP project, add AR Foundation 6, Apple ARKit, Google ARCore XR plugin, ARCore Extensions, glTFast.
5. Download one CC0 model pack and import a test GLB.
6. Build the Phase 0 placement scene and run the walk-around test on both phones.

---

## 13. Surroundings scan, X-ray view and obstacle-aware routes

The web prototype tests these ideas with free data. The native app does them properly.

| Feature | Web prototype (now) | Native app |
|---|---|---|
| X-ray outlines of buildings | OpenStreetMap footprints and heights, aligned by compass and GPS. Works in the dark because it's map data. | Google Streetscape Geometry: building and terrain meshes that come with VPS localization, already aligned. |
| Live scan of the immediate area | WebXR depth sensing on Android Chrome: a lasting point scan. Needs some light. | iPhone Pro LiDAR scene reconstruction works in near darkness. ARCore Depth API on Android. |
| Route that bends around obstacles | Legs follow OSM walkways (FOSSGIS foot routing). The live leg runs A* on a 50 cm grid around buildings and scanned obstacles. | Same planner, fed by the LiDAR or depth mesh and Streetscape Geometry. |
| VPS precision | Not wired. Options: MultiSet (WebXR, Android only, paid, needs pre-scanned sites and a token server), or manual alignment with the ⟲ ⟳ buttons against the building outlines. | Google Geospatial API: free at time of writing, global coverage wherever Street View exists. |

Low light: AR tracking itself (ARKit and ARCore) needs some visual texture, so in real darkness the camera loses tracking on phones without LiDAR. The map-based outlines still render. LiDAR iPhones keep tracking and scanning in very low light.
