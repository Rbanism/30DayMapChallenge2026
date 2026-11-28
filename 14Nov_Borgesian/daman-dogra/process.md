# Process

R (sf, osmdata, ggplot2, dplyr, ggrepel). The Delft boundary comes from the PDOK gebiedsindelingen 2025. Buildings, POIs and cemeteries come from Overpass; buildings are kept if their centroid lies in Delft. Each building gets its own tags plus those of any amenity/shop/craft/tourism/leisure nodes inside it. Rules are checked in Borges's order, and the first match wins. Only the class and the slightly simplified geometry are saved (`data/borges.gpkg`, 6.7 MB).

| Class | Rule (OSM) | n |
|---|---|---|
| (a) belonging to the Emperor | `name=Nieuwe Kerk` | 1 |
| (b) embalmed | centroid in `landuse=cemetery`/`amenity=grave_yard`, funeral hall/directors | 5 |
| (c) tame | farm/barn/stable buildings, vet, animal boarding/shelter, pet shop | 21 |
| (d) suckling pigs | kindergarten, childcare, butcher | 33 |
| (e) sirens | `building=houseboat`, swimming pool, water park | 34 |
| (f) fabulous | has `heritage`, `ref:rce` or `historic` | 1,282 |
| (g) stray dogs | `building=construction/ruins/abandoned` | 114 |
| (h) included in the present classification | library, public bookcase | 6 |
| (i) frenzied | bar, pub, nightclub, biergarten, dormitory | 37 |
| (j) innumerable | `building=apartments` | 2,328 |
| (k) drawn with a very fine camel-hair brush | museum, gallery, artwork, arts centre, art/frame shop, painter, potter | 18 |
| (l) et cetera | everything else | 22,375 |
| (m) having just broken the water pitcher | plumber, glazier, hardware/DIY/houseware shop, fire station, hospital, clinic | 14 |
| (n) that from a long way off look like flies | footprint < 15 m² | 13,443 |

The order of the rules matters as much as the rules themselves. A small listed shed ends up "fabulous" rather than a "fly" only because (f) comes before (n). Almost all of the flies turn out to be garden sheds.
