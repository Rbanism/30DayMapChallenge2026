# 24Nov_Network: The fietsknooppunten

![Map](map.png)

**Mapper:** Daman Dogra\
**Data:** [OpenStreetMap](https://www.openstreetmap.org/copyright) (© OpenStreetMap contributors, ODbL), [CBS/PDOK gebiedsindelingen 2025](https://service.pdok.nl/cbs/gebiedsindelingen/2025/wfs/v1_0) (CC BY 4.0)

The numbered cycling junctions between Den Haag, Delft and Westland, drawn like a transit map: 156 junctions and 459 km of links.

What the map shows: [map.md](map.md). How it was made: [process.md](process.md).

## Run it

From this folder: `Rscript map.R`. It rewrites `map.png`.

Packages: sf, osmdata, ggplot2, png.

`data/rcn.gpkg` holds the links, junctions and boundaries for the box. Delete it to re-query Overpass.

## Files

- [`map.R`](map.R): the whole pipeline
- [`map.png`](map.png): the map (1.1 MB)
- [`data/Logo_Rbanism_ Full.png`](data/Logo_Rbanism_%20Full.png) (121 KB)
- [`data/rcn.gpkg`](data/rcn.gpkg) (676 KB)
