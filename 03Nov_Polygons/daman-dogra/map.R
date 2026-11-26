library(terra)
library(sf)
library(ggplot2)

nl <- st_transform(st_as_sf(geodata::gadm("NLD", level = 0, path = "data")), 28992)
elev <- geodata::elevation_30s(country = "NLD", path = "data") # already masked to NL
v <- as.polygons(elev < 0)
names(v) <- "below"
pct <- round(100 * expanse(v[v$below == 1]) / sum(expanse(v)))
stopifnot(pct > 10, pct < 40)

polders <- disagg(as.polygons(ifel(elev < 0, floor(elev), NA))) # one block per 1 m depth step
names(polders) <- "depth"
polders <- st_transform(st_as_sf(polders), 28992)

# raw WFS is ~8 MB, so cache a simplified copy
if (!file.exists("data/dikes.gpkg")) st_write(st_simplify(st_geometry(st_read("https://geo.rijkswaterstaat.nl/services/ogc/wvp/nbpw/wfs?service=WFS&version=2.0.0&request=GetFeature&typeNames=nbpw:nbpw_dijktrajecten_formeel&outputFormat=application/json&srsName=EPSG:28992")), dTolerance = 50), "data/dikes.gpkg")
dikes <- st_read("data/dikes.gpkg", quiet = TRUE)
km <- round(as.numeric(sum(st_length(dikes))) / 1000)

logo <- grid::rasterGrob(png::readPNG("data/Logo_Rbanism_ White.png"))
bb <- st_bbox(nl)

ggplot() +
  geom_sf(data = nl, fill = "#243142", colour = "grey50", linewidth = 0.3 / .pt) +
  geom_sf(data = polders, aes(fill = depth), colour = "white", linewidth = 0.1) +
  geom_sf(data = dikes, aes(colour = "Primary flood defences\n(dikes, dams, dunes)"), linewidth = 0.4, show.legend = "line") +
  scale_fill_gradient(low = "#DEEBF7", high = "#08519C", name = "Height below sea level (m, 1 m steps)") +
  scale_colour_manual(values = "#F7931E", name = NULL) +
  annotation_custom(logo, xmin = bb$xmax - 50000, xmax = bb$xmax, ymin = bb$ymin, ymax = bb$ymin + 60000) +
  labs(
    title = "3Nov_Polygons: Below sea level",
    subtitle = paste0(nrow(polders), " polygons make up the ", pct, "% of the Netherlands below sea level,\nkept dry by ", km, " km of primary flood defences"),
    caption = "Data from SRTM (via geodata), GADM and Rijkswaterstaat.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026."
  ) +
  theme_void() +
  theme(
    text = element_text(colour = "white"),
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(size = 6, colour = "grey70"),
    legend.position = "bottom",
    legend.title.position = "top",
    legend.key.width = unit(1.5, "cm"),
    legend.key.height = unit(0.25, "cm"),
    plot.margin = margin(15, 15, 15, 15)
  )

ggsave("map.png", width = 2000, height = 2600, units = "px", dpi = 300, bg = "#0B1320")
