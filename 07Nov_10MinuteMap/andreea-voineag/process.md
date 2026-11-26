STEPS
1. I download the data from OSM: Bucharest's city boundary, street network of Bucharest and public toilets.
2. Loaded the data in R with `sf`.
3. Calculated a 10-minute walking isochrone for each toilet with `osrm::osrmIsochrone()`.
4. Saved the isochrones to a file, so they don't have to be recalculated.
5. Made the map with `ggplot2` and `geom_sf()`, added the logo with `cowplot`
   and formatted the subtitle with `ggtext`.

WHAT I LEARNED
A lot of things, because it was my first time working in RStudio. I had to find
the right packages, understand what the functions do and get familiar with
this new programming language.

- Requests to an online routing server are slow, so it's worth saving the results.
- How to plot multiple layers on the same map.
- In ggplot2, legends only appear for what is inside `aes()`, and the labels must match
  exactly in `scale_..._manual()`.