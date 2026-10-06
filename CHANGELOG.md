Starling-Spatial-Deactivator: Changelog
=======================================

Version 0.4 - 2026-10-06
------------------------

- Spatial Deactivator: Replaced Juggler inheritance by IAnimatable (the juggler methods are not available anymore)
- Spatial Element: Made time advance internal (elements are not IAnimatable anymore)
- Spatial Deactivator: Renamed isEnable to isEnabled (isEnable is kept as a deprecated alias)
- Spatial Deactivator: Added validation of chunk sizes, active areas & AABBs (invalid values raise an ArgumentError)
- Spatial Deactivator: Added enabling & disabling of the debug rendering at runtime (isDebugRenderingEnabled)
- Spatial Deactivator: Added chunks count
- Spatial Deactivator: Changed activity callbacks to be called once the context is up to date & only when the activity has really changed (callbacks can now create, destroy or move elements)
- Spatial Deactivator: Changed clear() to destroy the remaining elements, without calling their callbacks
- Spatial Deactivator: Made destroy() idempotent & releasing all its references
- Spatial Element: Made destroy() idempotent
- Spatial Deactivator: Fixed clear() leaving elements pointing at destroyed chunks
- Spatial Deactivator: Fixed chunks & elements being deactivated while disabled
- Spatial Deactivator: Fixed inconsistent chunks & elements activity after re-enabling
- Spatial Deactivator: Fixed elements toggled off & on when the active chunks change
- Spatial Deactivator: Fixed stack overflows when propagating activity along long chains of bridges
- Spatial Deactivator: Fixed chunks never freed & stopped creating chunks for the active area
- Spatial Deactivator: Fixed rectangles without width or height on a chunk border touching no chunk
- Spatial Element: Fixed activity changes lost when the callback is set after the element became active
- Spatial Element: Fixed activity not recomputed when destroying an active bridge
- Spatial Deactivator: Improved chunks activity refresh to only visit active & linked chunks
- Spatial Element: Reduced chunks activity refreshes when bridges cross chunks
- Demo: Added help panel & keyboard toggles for the deactivator features
- Demo: Fixed active area updated at each frame & overshooting its target on long frames
- Tests: Added test project
- Project: Stopped bundling Starling in the library SWC
- Project: Added Starling version to its SWC name
- Project: Removed unneeded application descriptor of the library
- Documentation: Converted the HTML demo page into a markdown article (How it works) & removed the Flash demo
- Documentation: Documented the requirements, the build instructions, the full API & the activity callbacks rules in the README
- Project: Updated copyright dates

Version 0.3 - 2021-10-19
------------------------

- Spatial Deactivator: Added enabling / disabling capability
- Spatial Deactivator: Added version
- Spatial Element: Reduced memory consumption by re-using list of chunks
- Project: Migrated to Visual Studio Code with the ActionScript & MXML extension

Version 0.2 - 2017-11-12
------------------------

- Spatial Deactivator: Changed chunks storage data structure to 2d Dictionary with integer keys
- Added direct update of active area & AABB if cooldown is over when user updates context
- Updated README to match the latest API
- Forced Spatial Elements to start inactive (for consistency reasons, the deactivator must manage all spatial activations & deactivations)
- Spatial Deactivator: Fixed active area first update delay (and delay after reset as well)
- Spatial Element: Fixed first update delay by initializing _timeSinceLastUpdate to Number.MAX_VALUE
- Spatial Element: Made activity changed callback field private
- Demo: Updated the Starling Forum link to reach the dedicated topic
- Spatial Element: Added isActivityBridge flag & updated logic to support it (closes #1)
- Reduced a bit memory allocations by re-using Vector of chunks

Version 0.1 - 2017-06-12
------------------------

- Initial version