# Process

Two Overpass queries with `osmdata` over the bounding box of the Netherlands and its EEZ: `power=generator` + `generator:source=wind` (nodes, plus centroids of polygons) and `power=line`. The EEZ comes from the Marine Regions WFS and the land from GADM (`geodata`). I kept the turbines on land or inside the EEZ, which drops the German and Belgian ones, and clipped the lines to the same shape. Everything is stored in `data/power.gpkg` (about 2 MB) and reused on later runs.

Without that filter the bounding box gave about 7,800 turbines, most of them German. For "at sea" I counted everything outside GADM land (which includes the IJsselmeer), giving 697; the EEZ polygon overlaps the coast, so it can't be used for that. OSM `voltage` is often a list like `380000;220000;0`, so I take the maximum before keeping lines of 110 kV and up.

The glow is plain ggplot: every line is drawn three times (wide and faint, medium, then a thin bright core), and the points get the same treatment. Overpass sometimes returns a 502 error; rerunning the script fixes it.
