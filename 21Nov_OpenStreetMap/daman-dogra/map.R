library(sf); library(osmdata); library(ggplot2)

f <- "data/delft.gpkg"
if (!file.exists(f)) {
  gem <- st_read("https://service.pdok.nl/cbs/gebiedsindelingen/2025/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeNames=gemeente_niet_gegeneraliseerd&outputFormat=json")
  delft <- gem[gem$statnaam == "Delft", "statnaam"]
  b <- osmdata_sf(add_osm_feature(opq(st_bbox(st_transform(delft, 4326)), timeout = 300, out = "meta"), "building"))$osm_polygons
  b <- st_transform(b[, c("osm_timestamp", "osm_user", "osm_version")], 28992)
  b <- b[lengths(st_intersects(st_centroid(b), delft)) > 0, ]
  b$year <- as.integer(substr(b$osm_timestamp, 1, 4))
  st_write(delft, f, "delft", layer_options = "SPATIAL_INDEX=NO")
  st_write(b[, c("year", "osm_user")], f, "buildings", layer_options = "SPATIAL_INDEX=NO")
}
delft <- st_read(f, "delft")
b <- st_read(f, "buildings")

top <- names(which.max(table(b$year)))
pct2 <- 100 * mean(b$year >= max(b$year) - 1)
u <- sort(table(b$osm_user), decreasing = TRUE)[1]
stopifnot(nrow(b) > 10000, pct2 > 0, pct2 < 100)
logo <- png::readPNG("data/Logo_Rbanism_ White.png")

p <- ggplot() +
  geom_sf(data = delft, fill = "#1b1b1b", colour = NA) +
  geom_sf(data = b, aes(fill = year), colour = NA) +
  scale_fill_gradientn(colours = c("#93278F", "#00A99D", "#F7931E"), name = "Year of last edit",
                       guide = guide_colourbar(barwidth = unit(6, "cm"), barheight = unit(0.25, "cm"), title.position = "top")) +
  annotation_custom(grid::rasterGrob(logo, x = 1, y = 1.01, hjust = 1, vjust = 0, height = unit(0.1, "npc"))) +
  coord_sf(datum = NA, clip = "off") +
  labs(title = "21Nov_OpenStreetMap: Who mapped Delft?",
       subtitle = sprintf("%s OSM buildings in Delft, coloured by the year they were last edited.\nMost common year: %s. %.0f%% were touched in %d or %d.\nOne mapper, %s, made the latest edit to %.0f%% of all buildings.",
                         format(nrow(b), big.mark = ","), top, pct2, max(b$year) - 1, max(b$year), names(u), 100 * u / nrow(b)),
       caption = "Data from \u00a9 OpenStreetMap contributors and CBS/PDOK.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026.") +
  theme_void() +
  theme(text = element_text(colour = "white"), legend.position = "top", legend.justification = "left", legend.margin = margin(t = 8),
        legend.title = element_text(size = 8), legend.text = element_text(size = 7),
        plot.title = element_text(size = 17, face = "bold"), plot.subtitle = element_text(size = 10),
        plot.caption = element_text(size = 6.5, hjust = 0.5, colour = "grey70"), plot.margin = margin(15, 15, 10, 15))

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "#0d0d0d")
