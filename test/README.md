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

- Use `ElementProbe` to create elements: it has no update cooldown and records the activity notifications, failing
  the test when an unchanged activity is notified
- Use a deactivator without active area update cooldown, so that each update is processed right away
- Destroy the deactivator at the end of each scenario

## Coverage

| Test | Covered behavior |
|------|------------------|
| `ActivityTest` | Elements entering & leaving the active area, active area moving, activity propagation through bridges & non-bridges |
