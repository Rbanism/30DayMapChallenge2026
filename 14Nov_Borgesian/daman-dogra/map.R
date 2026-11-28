library(sf); library(osmdata); library(ggplot2); library(dplyr); library(ggrepel)

f <- "data/borges.gpkg"
if (!file.exists(f)) {
  gem <- st_read("https://service.pdok.nl/cbs/gebiedsindelingen/2025/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeNames=gemeente_niet_gegeneraliseerd&outputFormat=json")
  delft <- gem[gem$statnaam == "Delft", "statnaam"]
  q <- opq(st_bbox(st_transform(delft, 4326)), timeout = 300)
  b <- st_transform(osmdata_sf(add_osm_feature(q, "building"))$osm_polygons, 28992)
  b <- b[lengths(st_intersects(st_centroid(st_geometry(b)), delft)) > 0, ]
  p <- osmdata_sf(add_osm_features(q, c('"amenity"', '"shop"', '"tourism"', '"craft"', '"leisure"', '"landuse"="cemetery"')))
  cem <- st_transform(p$osm_polygons[p$osm_polygons$landuse %in% "cemetery" | p$osm_polygons$amenity %in% "grave_yard", "osm_id"], 28992)
  # tags of each building plus the tags of the shop/amenity nodes inside it
  tg <- c("amenity", "shop", "tourism", "craft", "leisure")
  b$id <- seq_len(nrow(b))
  t <- rbind(st_drop_geometry(b)[, c("id", tg)], st_drop_geometry(st_join(st_transform(p$osm_points[, tg], 28992), b["id"], left = FALSE))[, c("id", tg)])
  b$cat <- case_when(
    b$name %in% "Nieuwe Kerk" ~ "a",
    lengths(st_intersects(st_centroid(st_geometry(b)), cem)) > 0 | b$id %in% t$id[t$amenity %in% "funeral_hall" | t$shop %in% "funeral_directors"] ~ "b",
    b$building %in% c("farm", "farm_auxiliary", "barn", "stable", "cowshed") | b$id %in% t$id[t$amenity %in% c("veterinary", "animal_boarding", "animal_shelter") | t$shop %in% "pet"] ~ "c",
    b$id %in% t$id[t$amenity %in% c("kindergarten", "childcare") | t$shop %in% "butcher"] ~ "d",
    b$building %in% "houseboat" | b$id %in% t$id[t$leisure %in% c("swimming_pool", "water_park")] ~ "e",
    !is.na(b$heritage) | !is.na(b$`ref:rce`) | !is.na(b$historic) ~ "f",
    b$building %in% c("construction", "ruins", "abandoned") ~ "g",
    b$id %in% t$id[t$amenity %in% c("library", "public_bookcase")] ~ "h",
    b$building %in% "dormitory" | b$id %in% t$id[t$amenity %in% c("bar", "pub", "nightclub", "biergarten")] ~ "i",
    b$building %in% "apartments" ~ "j",
    b$id %in% t$id[t$tourism %in% c("museum", "gallery", "artwork") | t$amenity %in% "arts_centre" | t$shop %in% c("art", "frame") | t$craft %in% c("painter", "pottery")] ~ "k",
    b$id %in% t$id[t$craft %in% c("plumber", "glaziery") | t$shop %in% c("hardware", "doityourself", "houseware") | t$amenity %in% c("fire_station", "hospital", "clinic")] ~ "m",
    as.numeric(st_area(b)) < 15 ~ "n",
    TRUE ~ "l")
  st_write(delft, f, "delft", layer_options = "SPATIAL_INDEX=NO")
  st_write(cem, f, "cemeteries", layer_options = "SPATIAL_INDEX=NO")
  st_write(st_simplify(b["cat"], preserveTopology = TRUE, dTolerance = 0.3), f, "buildings", layer_options = "SPATIAL_INDEX=NO")
}
delft <- st_read(f, "delft")
cem <- st_read(f, "cemeteries")
b <- st_read(f, "buildings")

lab <- c(a = "(a) belonging to the Emperor", b = "(b) embalmed", c = "(c) tame", d = "(d) suckling pigs", e = "(e) sirens",
         f = "(f) fabulous", g = "(g) stray dogs", h = "(h) included in the present classification", i = "(i) frenzied",
         j = "(j) innumerable", k = "(k) drawn with a very fine camel-hair brush", l = "(l) et cetera",
         m = "(m) having just broken the water pitcher", n = "(n) that from a long way off look like flies")
pal <- c(a = "#F7931E", b = "#3d3d3d", c = "#8c6d31", d = "#f28cb1", e = "#1f78b4", f = "#93278F", g = "#b15928",
         h = "#00A99D", i = "#e31a1c", j = "#7f9cc0", k = "#33a02c", l = "#c4b79d", m = "#e6c619", n = "#111111")
n <- table(factor(b$cat, names(lab)))
etc <- 100 * n[["l"]] / nrow(b)
stopifnot(n[["a"]] == 1, sum(n > 0) >= 12, etc > 0, etc < 100)
emperor <- st_point_on_surface(b[b$cat == "a", ])
logo <- png::readPNG("data/Logo_Rbanism_ Full.png")

p <- ggplot() +
  geom_sf(data = delft, fill = "#ece4d3", colour = NA) +
  geom_sf(data = cem, fill = pal[["b"]], alpha = 0.35, colour = NA) +
  geom_sf(data = b, aes(fill = factor(cat, names(lab))), colour = NA) +
  geom_text_repel(data = emperor, aes(geometry = geom), label = "(a) the Nieuwe Kerk,\ntomb of the House of Orange", stat = "sf_coordinates",
                  size = 2.6, fontface = "italic", nudge_x = -1800, nudge_y = 900, segment.size = 0.3, bg.colour = "#f5f0e6") +
  scale_fill_manual(values = pal, labels = sprintf("%s (%s)", lab, format(n, big.mark = ",", trim = TRUE)), drop = FALSE, name = NULL) +
  annotation_custom(grid::rasterGrob(logo, x = 1, y = 1.01, hjust = 1, vjust = 0, height = unit(0.1, "npc"))) +
  coord_sf(datum = NA, clip = "off") +
  guides(fill = guide_legend(ncol = 2, keywidth = unit(0.35, "cm"), keyheight = unit(0.35, "cm"))) +
  labs(title = "14Nov_Borgesian: Borges's Chinese\nencyclopedia of Delft",
       subtitle = sprintf("All %s OSM buildings of Delft, sorted into the 14 animal classes of the\n'Celestial Emporium of Benevolent Knowledge'. %.0f%% end up as 'et cetera'.",
                         format(nrow(b), big.mark = ","), etc),
       caption = "Data from \u00a9 OpenStreetMap contributors and CBS/PDOK. Classes after J. L. Borges,\n'The Analytical Language of John Wilkins' (1942).\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026.") +
  theme_void() +
  theme(legend.position = "bottom", legend.text = element_text(size = 7), legend.margin = margin(t = 5),
        plot.title = element_text(size = 17, face = "bold"), plot.subtitle = element_text(size = 9.5),
        plot.caption = element_text(size = 6.5, hjust = 0.5), plot.margin = margin(15, 15, 10, 15))

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "#f5f0e6")
