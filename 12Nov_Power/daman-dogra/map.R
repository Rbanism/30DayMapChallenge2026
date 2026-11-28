library(sf)
library(osmdata)
library(ggplot2)

f <- "data/power.gpkg"
if (!file.exists(f)) {
  # NL land + Dutch EEZ, so offshore wind farms count but Belgian/German ones don't
  eez <- st_read("https://geo.vliz.be/geoserver/MarineRegions/wfs?service=WFS&version=1.0.0&request=GetFeature&typeName=MarineRegions:eez&cql_filter=mrgid=5668&outputFormat=application/json")
  land <- st_as_sf(geodata::gadm("NLD", level = 0, path = tempdir()))[, "COUNTRY"]
  nl <- st_union(c(st_geometry(st_make_valid(eez)), st_geometry(land)))
  q <- opq(st_bbox(nl), timeout = 300)
  wt <- osmdata_sf(add_osm_feature(add_osm_feature(q, "power", "generator"), "generator:source", "wind"))
  turbines <- rbind(wt$osm_points[wt$osm_points$power %in% "generator", "osm_id"], st_centroid(wt$osm_polygons[, "osm_id"]))
  ln <- osmdata_sf(add_osm_feature(q, "power", "line"))$osm_lines
  kv <- sapply(strsplit(ln$voltage, ";"), \(v) max(as.numeric(v)))
  st_write(st_transform(st_filter(turbines, nl), 28992), f, "turbines")
  st_write(st_transform(st_intersection(ln[which(kv >= 110000), "voltage"], nl), 28992), f, "lines")
  st_write(st_transform(land, 28992), f, "land")
  st_write(st_transform(eez[, "geoname"], 28992), f, "eez")
}
turbines <- st_read(f, "turbines")
lines <- st_read(f, "lines")
land <- st_read(f, "land")
eez <- st_read(f, "eez")

n <- nrow(turbines)
stopifnot(n > 1000)
sea <- sum(lengths(st_intersects(turbines, land)) == 0)
bb <- st_bbox(c(st_geometry(land), st_geometry(turbines)))
logo <- png::readPNG("data/Logo_Rbanism_ White.png")

p <- ggplot() +
  geom_sf(data = land, fill = "#121a2b", colour = NA) +
  geom_sf(data = eez, fill = NA, colour = "#2a3550", linewidth = 0.3, linetype = "dotted") +
  geom_sf(data = lines, colour = "#00A99D", linewidth = 2.4, alpha = 0.06) +
  geom_sf(data = lines, colour = "#00A99D", linewidth = 1.1, alpha = 0.18) +
  geom_sf(data = lines, colour = "#7ff5e9", linewidth = 0.25) +
  geom_sf(data = turbines, colour = "#F7931E", size = 1.1, alpha = 0.12, stroke = 0) +
  geom_sf(data = turbines, colour = "#ffe2b0", size = 0.35, stroke = 0) +
  annotation_custom(grid::rasterGrob(logo, x = 0.98, y = 0.02, hjust = 1, vjust = 0, height = unit(0.13, "npc"))) +
  coord_sf(xlim = bb[c(1, 3)] + c(-5e3, 5e3), ylim = bb[c(2, 4)] + c(-5e3, 5e3), expand = FALSE) +
  labs(
    title = "12Nov_Power: The new Dutch power grid",
    subtitle = sprintf("%s wind turbines (%s in the North Sea) and every high-voltage line (110 kV+)", format(n, big.mark = ","), format(sea, big.mark = ",")),
    caption = "Data from \u00a9 OpenStreetMap contributors, Marine Regions (Dutch EEZ) and GADM.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026."
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#070b14", colour = NA),
    text = element_text(colour = "grey85"),
    plot.title = element_text(face = "bold", size = 17, colour = "white"),
    plot.subtitle = element_text(size = 10, margin = margin(4, 0, 8, 0)),
    plot.caption = element_text(size = 6.5, colour = "grey60", hjust = 0.5),
    plot.margin = margin(15, 15, 10, 15)
  )

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "#070b14")
