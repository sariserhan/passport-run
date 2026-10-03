# World map and passport pages

The main menu's **WORLD MAP** shows a flat geographic map with gold pins for cleared countries and territories from the saved passport. Tap a pin to display its name; a readable list appears below the map. Unvisited places are not pinned. Landmarks and fictional locations remain in the passport rather than receiving invented country coordinates.

The map uses an equirectangular projection and simplified [Natural Earth 1:110m country outlines](https://github.com/nvkelso/natural-earth-vector/blob/master/geojson/ne_110m_admin_0_countries.geojson). Natural Earth data is public domain: https://www.naturalearthdata.com/about/terms-of-use/. Downloaded 2026-10-02; original GeoJSON SHA-256 `6866c877d39cba9c357620878839b336d569f8c662d3cfab4cb1dbe2d39c977f`. Outer polygon rings are rounded to one decimal degree for this small overview. Tiny shapes that cannot triangulate at this resolution are skipped; saved destination pins remain visible. This is an overview rather than a detailed boundary map.

All 250 destination pin coordinates come from the existing mledoze/countries snapshot, under the bundled ODbL license. The adapted geometry/coordinate asset is `resources/geography/world-map.json`, exported with the game. Geography license and source attribution remain bundled.

**MY PASSPORT** displays a bound paper page with the completed destination's name, scenery image, visa page number and rotated completion stamp. Previous/Next turn pages; search filters earned pages. Empty or unmatched collections never show a completed stamp. Pages are derived from durable discoveries, so ordinary profile reload preserves them. Existing travel stickers and history remain accessible.

## Connected travel routes

The map draws connections in saved completion-history order, behind earned pins. Balloon Tour also provides a short upcoming itinerary and green current-location marker. Lines split across the date line; repeated or invalid destinations add no zero-length/bogus connections. History remains bounded to the existing last 200 completions. This records actual completion order rather than inferring a route from country proximity.
