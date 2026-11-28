# Process

The Westland boundary comes from the CBS/PDOK gebiedsindelingen WFS (2025). PDOK ignored my `cql_filter`, so the script downloads all municipalities and picks Westland in R. Its bounding box goes into two Overpass queries with `osmdata`: `landuse=greenhouse_horticulture` or `building=greenhouse`, and all `highway` ways. Both are clipped to Westland, the greenhouses are dissolved with `st_union`, and the result is saved as `data/westland.gpkg` (about 4 MB).

How much is "under glass" depends on the tag. Merging the plots and the buildings gives 52%, but that includes paths, ditches and basins. The `building=greenhouse` footprints alone give 29%, close to the roughly 2,300 ha of glass that is usually quoted. The map shows both: plots as a dim haze, buildings as the bright glow.

The glow is three layers: a wide outline at about 5% alpha, a medium one at about 15%, then the fill. In `geom_sf` the `alpha` argument only affects fills, so the transparency goes into the hex colour (`#F7931E26`). Rscript runs in a non-UTF-8 locale here, so the © has to be written as `\u00a9`.
