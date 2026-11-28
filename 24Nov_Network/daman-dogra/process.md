# Process

Two Overpass queries with `osmdata` for a fixed box (4.12 to 4.41 E, 51.94 to 52.14 N): relations with `route=bicycle` and `network=rcn` for the links, and nodes with an `rcn_ref` key for the junctions. Municipal boundaries come from the CBS/PDOK gebiedsindelingen WFS (2025). Everything is cropped to the box and saved in `data/rcn.gpkg` (about 0.7 MB). Overpass returned 502 errors a few times; rerunning helped.

A junction is often mapped as two or more nodes, one on each side of the road: 111 nodes had a twin with the same number within 150 m. Keeping the first of each group (`st_is_within_distance` + `mapply`) brings the count from 218 down to 156. The 459 km is measured on the `st_union` of the links, so stretches shared by several routes count once.

For the transit-map look the junctions are `shape = 21` points with a white fill and purple stroke, with `geom_sf_text` on top. Place names sit at `st_point_on_surface(st_buffer(gem, -1200))` so they stay clear of the cropped edges, and the logo goes in the title band (`clip = "off"`) so it doesn't cover any junctions.
