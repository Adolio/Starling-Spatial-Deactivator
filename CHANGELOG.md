Starling-Spatial-Deactivator: Changelog
=======================================

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