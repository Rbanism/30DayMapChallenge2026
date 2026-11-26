# Process

The map is made with one R script, `map.R`, using terra, sf, ggplot2, geodata and png.

1. `geodata::elevation_30s()` downloads SRTM elevation for the Netherlands (about 1 km resolution, masked to the country). `geodata::gadm()` gives the outline. Both are cached in `data/` with the white Rbanism logo.
2. `terra::as.polygons(elev < 0)` gives one polygon below and one above sea level. Their areas give the share below sea level, and a `stopifnot()` checks it is between 10% and 40%.
3. To make the polygons visible, the below-sea-level cells are floored to whole metres. `as.polygons()` then merges cells of the same step, and `disagg()` splits them into separate blocks.
4. Rijkswaterstaat's primary flood defences (NBPW, `nbpw_dijktrajecten_formeel`) are read from its WFS. On the first run they are simplified to 50 m and cached as `data/dikes.gpkg` (230 KB).
5. Everything is drawn with `geom_sf` in RD New (EPSG:28992) on a dark background. The blocks have thin white edges, the dikes are drawn in Rbanism orange, and the logo is added with `annotation_custom`.

One flat blue polygon looked like a blob. Splitting it into one-metre depth steps made the polygons readable, and adding the dikes shows why that land is still dry.
