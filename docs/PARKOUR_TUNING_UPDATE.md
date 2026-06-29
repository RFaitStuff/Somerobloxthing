# Parkour / Camera Tuning Update

This pass focused on controller feel without changing the wider world structure.

## Movement update loop

- Movement now updates from `RunService.PreSimulation` when available, with `Heartbeat` fallback.
- The controller still writes `HumanoidRootPart.AssemblyLinearVelocity`, but now does it closer to the physics step.
- Camera remains render-step driven so it stays visually smooth.

## Sprint / walk intent

- Sprint is intentionally still the default movement state.
- Holding the sprint/walk key keeps the player in the slower precision ground mode.
- The tuner now labels `WalkSpeed` as hold-walk speed and `SprintSpeed` as the default traversal speed.

## Bullet jump

- Fixed vertical bullet jump logic so looking straight up creates a true upward rocket jump.
- Looking downward no longer uses the same rocket path. It now creates the intended ground-pop behavior: upward plus forward.
- Added clearer tuner descriptions for normal bullet jump, pure-up bullet jump, ground-look pop, and speed caps.

## Jump / double jump

- Slightly increased jump and double-jump height.
- Slightly increased double-jump forward correction.
- Added wall-return assist: after a wall hop, a normal double jump can drive back toward the last wall if the player aims or moves toward it.

## Wall climbing and wall latch

- Wall detection now separates contact from aim-qualified latch.
- Wall contact is forgiving and uses multiple spherecast heights.
- Wall latch requires stronger camera intent toward the wall.
- Pressed jump only wall-hops if the player is trying to continue along/up the wall.
- Held jump can chain wall hops at a tunable repeat interval.
- Wall latch now dampens into a stop instead of snapping velocity to zero instantly.
- Wall hop briefly keeps character facing camera direction so jumping into a wall should not instantly rotate the character away.

## Aim glide

- Aim glide base duration was reduced to 6 seconds.
- Air control was increased slightly, but left restrained so aim glide still feels controlled instead of fully free-flight.

## Slide and slope feel

- Slide start got a small boost increase.
- Flat slide friction was slightly reduced.
- Slide steering was slightly increased.
- Downhill slope acceleration was increased so sliding down hills gains more noticeable momentum.
- Uphill friction remains high so uphill slides lose speed.

## Camera

- Camera shoulder and aim offsets were reduced slightly, not heavily.
- Aim distance was brought closer to normal distance so aiming feels less pulled-back.
- Camera collision no longer ignores every other player character by default. It still ignores the local character, but other players/companions can now obstruct the camera instead of the camera clipping inside them.

## Animation

- Added parkour animation aliases: `BulletJump`, `DoubleJump`, `AimGlide`, `WallLatch`, `WallHopVertical`, `WallHopHorizontal`, and `HardLanding`.
- Added temporary fallback IDs for these aliases using built-in Roblox default-style animations where no real custom animation exists yet.
- Slide now plays `SlideStart` first and delays the slide loop briefly instead of immediately jumping straight to the loop.

## Debug/tuning UI

- Tuner rows now include short descriptions explaining how values affect feel.
- Added wall, slope, bullet jump, aim glide, and camera values that matter for this pass.
- Debug text now shows wall contact separately from wall aim, wall contact age, and approach value.

## Still needs Studio tuning

- Actual custom slide/bullet jump/wall latch/wall hop animations.
- Testing exact wall-hop interval, wall detection radius, and double-jump wall-return assist.
- Testing camera collision against player companions and large enemies.
- Verifying movement feel in real terrain with slopes, ledges, corners, and public-player overlap.
