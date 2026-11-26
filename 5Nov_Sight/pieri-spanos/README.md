# 5Nov_Sight: Cyprus Medieval Castles Viewshed on Pentadaktylos Mountain

![Map](maps/Cyprus%20Castles%20Viewsheds%20Map.png)

**Mappers:** Alex Pieri & Charalambos Spanos\
**Data:** Copernicus DEM GLO-30, castle locations digitised by the mappers

## About the map

We opted for a viewshed. In Cyprus there are 3 prominent medieval mountaintop castles along the northern mountain range of Pentadaktylos with panoramic views. We thought these would be a great subject for our map.

## Process

We sourced the DEM of the island from Copernicus (GLO-30). We put together a quick point layer of the castle locations and loaded them into R.

We used the viewscape package, outlined in this Yang et al. (2024) (DOI:10.1016/j.softx.2024.101662). Following their documentation we applied the viewshed methodology to our data.

We are both GIS professionals but mostly beginners with R (we have had previous experience with python, and one of us had used R in university before some years ago).

We did learn a lot as beginners coming from the very basics of R to generating quite a complex analysis and outputting it as a complete map. There is much still to learn but this was a great introduction / reintroduction to the software.

Looking forward to the next one.

## Files

- [`code/cy_castles_viewsheds.R`](code/cy_castles_viewsheds.R): R code
- [`maps/`](maps): the map, with and without layout
- [`data/`](data): DEM, castle points and Rbanism logo
- Original text: [`content-description.txt`](content-description.txt)
