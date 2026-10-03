# Test Project

Automated tests of the library (`src`), run through `adl` without showing a window.

The test framework lives in `src/ch/adolio/test` and stays independent of the library. The tests of the library live
in `src/ch/adolio/deactivator/test`, where they are registered in `TestMain.as` as synchronous tests (`ITest`). When
adding, removing or extending a test, update the coverage below.

## Running

From the repository root, with `<air-sdk-path>` the path of an AIR SDK (33.1 or later):

```powershell
npx --yes asconfigc --sdk <air-sdk-path> --project test/asconfig.json --debug=true
& "<air-sdk-path>/bin/adl.exe" test/bin/application.xml test/bin
```

The run prints `All N test(s) passed.` and exits with code 0, or 1 when a test fails.

## Writing Tests

- Create deactivators with `DeactivatorFactory`: no active area update cooldown, so that each update is processed
  right away
- Create elements with `ElementProbe`: no update cooldown, records the activity notifications & fails the test when
  an unchanged activity is notified; its `reaction` acts from the activity callback
- Destroy the deactivator at the end of each scenario

## Coverage

| Test | Covered behavior |
|------|------------------|
| `ActivityTest` | Elements entering & leaving the active area, active area moving, activity propagation through bridges & non-bridges, element covering chunks whose activity swaps, AABB & active area without width or height on a chunk border |
| `LifecycleTest` | Element destroyed twice or after `clear()`, `clear()` without notification, deactivator reuse after `clear()` & destruction of an element linking chunks (bridge or not, enabled or disabled), deactivator destroyed twice, from an activity callback or while left in a juggler |
| `ValidationTest` | Rejection of invalid chunk sizes, active areas & AABBs (null, NaN, infinite or negative size) without changing the context, empty rectangles accepted |
| `ChunksTest` | No chunk allocated for the active area, chunks freed when left, deactivated or cleared, chunk created again in the active area for bridges & non-bridges |
| `RefreshTest` | Bridge moves which must not refresh all the chunks activity (inactive bridge, active bridge crossing chunks over the active area) & the ones which must (active bridge leaving a chunk out of the active area, or the active area) |
| `ReentrancyTest` | Activity callbacks destroying their own element or another one, creating elements & moving another element |
| `CallbackTest` | Activity callback set after the element creation: while disabled, on an active or inactive element & replaced |
| `BridgeChainTest` | Activity propagation & linked chunks along a chain of 10000 bridges, without stack overflow |
| `DebugRenderingTest` | Quads of the debug sprite when elements are created, moved & destroyed, and when the deactivator is cleared; debug rendering enabled & disabled at runtime with existing chunks & elements; debug sprite removed from its parent on destroy |
| `EnablingTest` | No deactivation while disabled, re-enabling after elements or the active area moved & after elements were created |
