library(sf)
library(osmdata)
library(ggplot2)

f <- "data/rcn.gpkg"
if (!file.exists(f)) {
  bb <- c(xmin = 4.12, ymin = 51.94, xmax = 4.41, ymax = 52.14)
  q <- opq(bb, timeout = 300)
  links <- osmdata_sf(add_osm_feature(add_osm_feature(q, "route", "bicycle"), "network", "rcn"))$osm_multilines
  nodes <- osmdata_sf(add_osm_feature(q, "rcn_ref"))$osm_points
  gem <- st_read("https://service.pdok.nl/cbs/gebiedsindelingen/2025/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeNames=gemeente_gegeneraliseerd&outputFormat=json")
  st_write(st_transform(st_crop(st_make_valid(links[, "route"]), bb), 28992), f, "links")
  st_write(st_transform(st_crop(nodes[!is.na(nodes$rcn_ref), "rcn_ref"], bb), 28992), f, "nodes")
  st_write(st_crop(gem[, "statnaam"], st_transform(st_as_sfc(st_bbox(bb, crs = 4326)), 28992)), f, "gemeenten")
}
links <- st_read(f, "links")
nodes <- st_read(f, "nodes")
gem <- st_read(f, "gemeenten")

# one junction is often mapped as 2+ nodes (one per road side): keep the first of each same-number group within 150 m
near <- st_is_within_distance(nodes, dist = 150)
nodes <- nodes[!mapply(\(i, js) any(js < i & nodes$rcn_ref[js] == nodes$rcn_ref[i]), seq_along(near), near), ]
stopifnot(nrow(nodes) > 100)
km <- round(sum(st_length(st_union(links))) / 1000)
logo <- png::readPNG("data/Logo_Rbanism_ Full.png")
lab <- st_point_on_surface(st_buffer(gem, -1200))
lab <- lab[!st_is_empty(lab), ]

p <- ggplot() +
  geom_sf(data = gem, fill = "#efebe2", colour = "white", linewidth = 0.6) +
  geom_sf_text(data = lab, aes(label = statnaam), colour = "#c9c1b0", size = 3, fontface = "bold.italic") +
  geom_sf(data = links, colour = "#00A99D", linewidth = 0.55) +
  geom_sf(data = nodes, shape = 21, size = 3.6, fill = "white", colour = "#93278F", stroke = 0.6) +
  geom_sf_text(data = nodes, aes(label = rcn_ref), size = 1.5, colour = "#93278F", fontface = "bold") +
  annotation_custom(grid::rasterGrob(logo, x = 1, y = 1.01, hjust = 1, vjust = 0, height = unit(0.085, "npc"))) +
  coord_sf(expand = FALSE, clip = "off") +
  labs(
    title = "24Nov_Network: The fietsknooppunten",
    subtitle = sprintf("%d numbered cycling junctions and %d km of links between Delft, Den Haag and Westland", nrow(nodes), km),
    caption = "Data from \u00a9 OpenStreetMap contributors and CBS/PDOK gebiedsindelingen 2025.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026."
  ) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "#faf8f3", colour = NA),
    plot.title = element_text(face = "bold", size = 17, colour = "#1a1a2e"),
    plot.subtitle = element_text(size = 9.5, colour = "grey25", margin = margin(4, 0, 8, 0)),
    plot.caption = element_text(size = 6.5, colour = "grey45", hjust = 0.5),
    plot.margin = margin(15, 15, 10, 15)
  )

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "#faf8f3")
