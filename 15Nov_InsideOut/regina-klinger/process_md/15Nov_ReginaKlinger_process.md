# Process

Made entirely in R, building on my Day 6 Vintage script and the Geospatial Data Carpentry for Urbanism course (TU Delft).

Data:
- Buildings: one 3DBAG tile (10-282-562), transformed to RD New (EPSG:28992).
- Canals: OpenStreetMap, saved from my Vintage map.
- Trees: OpenStreetMap via osmdata, queried with a bounding box in WGS84 after the full-city query timed out.

Courtyards: I merged the buildings into blocks with st_buffer(), st_union() and a negative buffer to close small gaps. st_difference() cut the blocks out of the tile, st_cast() split the open space into 55 pieces, and st_area() with filter() removed the largest piece, the street network, leaving 54 courtyards.

I wrote the code myself. An AI assistant explained concepts, error messages and why code is written the way it is.

What I learned:
- how to derive new geometries from existing ones instead of downloading more data
- the difference between fill and colour, and that points ignore fill
- that a legend needs aes() labels, and named colours in the scale
- that file names in ggsave() need an extension
