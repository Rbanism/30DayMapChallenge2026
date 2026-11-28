library(sf)
library(osmdata)
library(ggplot2)

f <- "data/westland.gpkg"
if (!file.exists(f)) {
  gem <- st_read("https://service.pdok.nl/cbs/gebiedsindelingen/2025/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeNames=gemeente_niet_gegeneraliseerd&outputFormat=json")
  westland <- gem[gem$statnaam == "Westland", "statnaam"]
  q <- opq(st_bbox(st_transform(westland, 4326)), timeout = 300)
  g <- osmdata_sf(add_osm_features(q, list(landuse = "greenhouse_horticulture", building = "greenhouse")))
  gh <- st_make_valid(st_transform(rbind(g$osm_polygons[, c("building", "landuse")], g$osm_multipolygons[, c("building", "landuse")]), 28992))
  roads <- st_transform(osmdata_sf(add_osm_feature(q, "highway"))$osm_lines[, "highway"], 28992)
  st_write(westland, f, "westland")
  st_write(st_sf(geometry = st_union(st_intersection(gh[gh$building %in% "greenhouse", ], westland))), f, "glass")
  st_write(st_sf(geometry = st_union(st_intersection(gh[gh$landuse %in% "greenhouse_horticulture", ], westland))), f, "plots")
  st_write(st_intersection(roads, westland), f, "roads")
}
westland <- st_read(f, "westland")
glass <- st_read(f, "glass")
plots <- st_read(f, "plots")
roads <- st_read(f, "roads")

pct <- as.numeric(st_area(glass) / st_area(westland)) * 100
stopifnot(pct > 15, pct < 60)
logo <- png::readPNG("data/Logo_Rbanism_ White.png")

p <- ggplot() +
  geom_sf(data = westland, fill = NA, colour = "grey15", linewidth = 0.3) +
  geom_sf(data = roads, colour = "grey30", linewidth = 0.08, alpha = 0.6) +
  geom_sf(data = plots, fill = "#F7931E1A", colour = NA) +
  geom_sf(data = plots, fill = "#F7931E1A", colour = NA) +
  geom_sf(data = glass, fill = NA, colour = "#F7931E0D", linewidth = 4) +
  geom_sf(data = glass, fill = NA, colour = "#F7931E26", linewidth = 1.5) +
  geom_sf(data = glass, fill = "#F7931ECC", colour = "#ffd9a0", linewidth = 0.1) +
  annotation_custom(grid::rasterGrob(logo, x = 0.99, y = 0.01, hjust = 1, vjust = 0, height = unit(0.12, "npc"))) +
  labs(
    title = "17Nov_LightDark: The Westland glow",
    subtitle = sprintf("%.0f%% of Westland is under glass: the greenhouse city between Den Haag and Hoek van Holland", pct),
    caption = "Data from \u00a9 OpenStreetMap contributors and CBS/PDOK gebiedsindelingen 2025.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026."
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "black", colour = NA),
    text = element_text(colour = "grey85"),
    plot.title = element_text(face = "bold", size = 17, colour = "white"),
    plot.subtitle = element_text(size = 9, margin = margin(4, 0, 8, 0)),
    plot.caption = element_text(size = 6.5, colour = "grey55", hjust = 0.5),
    plot.margin = margin(15, 15, 10, 15)
  )

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "black")
