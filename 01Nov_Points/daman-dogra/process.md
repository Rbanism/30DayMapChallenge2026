# Process

I started from a Wikidata SPARQL query for items whose "named after" (P138) points to something in the Netherlands. That returned over 1,000 hits, mostly streets and features named after rivers. I curated the list by hand and kept a place only if Wikipedia or Wikidata explicitly links its name to a Dutch place. A shared spelling could be coincidence, so it wasn't enough. Middelburg (Eastern Cape) is "midway", Nieuw Nickerie is named after a river, and Haarlem (Western Cape) is only "presumably" Dutch. Coordinates are stored in `data/namesakes.csv`, so `map.R` runs offline.

The map uses `sf` and `ggplot2` in the Equal Earth projection, with the Natural Earth basemap from `rnaturalearth`. Labels use `ggrepel`. I passed every point to the repel layer (most with an empty label) so labels also avoid unlabelled points.

`st_segmentize()` on lon/lat data wants `lwgeom`, but `s2`, which ships with `sf`, can interpolate great circles on its own. The arcs to the Pacific islands are nearly antipodal: they run over the pole and end up tracing the edge of the Equal Earth map, so I dropped those three. And a hard-coded "Gorée" broke under the C locale until I wrote it as `\u00e9`.
