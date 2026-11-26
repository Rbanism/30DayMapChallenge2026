# 1Nov_Points: Little Netherlands
# Places whose names are linked to Dutch towns and provinces (per Wikipedia / Wikidata).
# Run from this folder: Rscript map.R

library(sf)
library(ggplot2)
library(dplyr)
library(readr)
library(rnaturalearth)
library(ggrepel)
library(png)
library(grid)

eqearth <- "+proj=eqearth"
orange <- "#F7931E"
bg <- "#16161d"

# --- Data -------------------------------------------------------------------
places <- read_csv("data/namesakes.csv", show_col_types = FALSE)

stopifnot(
  nrow(places) >= 40, nrow(places) <= 80,
  !anyNA(places[c("lon", "lat", "origin_lon", "origin_lat")]),
  all(abs(places$lon) <= 180), all(abs(places$lat) <= 90),
  all(places$type %in% c("city", "region", "island", "country")),
  all(grepl("^https://", places$source_url))
)

places <- places |>
  mutate(type = factor(type, levels = c("city", "island", "region", "country")))

pts <- st_as_sf(places, coords = c("lon", "lat"), crs = 4326)

# Great-circle arcs from the Dutch origin to each namesake (s2 ships with sf)
arc_coords <- lapply(seq_len(nrow(places)), \(i) {
  gc <- s2::s2_make_line(c(places$origin_lon[i], places$lon[i]),
                         c(places$origin_lat[i], places$lat[i]))
  p <- s2::s2_interpolate_normalized(gc, seq(0, 1, length.out = 100))
  cbind(s2::s2_x(p), s2::s2_y(p))
})
# shortcut: the three Pacific islands are near-antipodal, so their arcs run over the pole
# and along the map edge; they are skipped rather than split
arc_coords <- Filter(\(m) max(m[, 2]) < 85, arc_coords)
arcs <- st_sfc(lapply(arc_coords, st_linestring), crs = 4326)

world <- ne_countries(scale = "medium", returnclass = "sf")

sphere <- st_sfc(st_polygon(list(cbind(
  c(rep(-180, 181), rep(180, 181), -180),
  c(-90:90, 90:-90, -90)
))), crs = 4326)

# --- Labels -----------------------------------------------------------------
labelled <- c("Brooklyn", "Harlem", "Zeeland, MI", "Harlingen, TX",
              "Amsterdam, SK", "New Zealand", "New Holland", "Cape Horn",
              "Gor\u00e9e", "Ny-Friesland", "Delft Island", "Utrecht",
              "New Amsterdam", "Groningen", "Hoorn Islands")

# All points go to ggrepel (unlabelled ones as "") so labels avoid every point
labels <- pts |>
  mutate(label = case_when(
    !name %in% labelled ~ "",
    name == dutch_origin ~ paste0(name, ", ", country, "  \u2190 ", dutch_origin),
    TRUE ~ paste0(name, "  \u2190 ", dutch_origin)
  )) |>
  st_transform(eqearth)
labels <- cbind(labels, st_coordinates(labels))

# --- Map --------------------------------------------------------------------
logo <- rasterGrob(readPNG("data/Logo_Rbanism_White.png"), interpolate = TRUE)

p <- ggplot() +
  geom_sf(data = sphere, fill = "#1e1e28", colour = "#2c2c38", linewidth = 0.3) +
  geom_sf(data = world, fill = "#3a3a44", colour = "#4a4a55", linewidth = 0.1) +
  geom_sf(data = arcs, colour = orange, alpha = 0.18, linewidth = 0.25) +
  geom_sf(data = pts, aes(shape = type, size = type),
          colour = orange, fill = orange, alpha = 0.9) +
  geom_text_repel(
    data = labels, aes(X, Y, label = label),
    colour = "grey92", size = 2.8, family = "sans",
    segment.colour = "grey70", segment.size = 0.25,
    min.segment.length = 0, box.padding = 0.4, point.padding = 0.2,
    force = 2, max.overlaps = Inf, seed = 1
  ) +
  annotation_custom(logo, xmin = -17.6e6, xmax = -15.4e6,
                    ymin = -9.2e6, ymax = -6.0e6) +
  scale_shape_manual(values = c(city = 16, island = 17, region = 15, country = 18)) +
  scale_size_manual(values = c(city = 1.6, island = 2.2, region = 2.6, country = 4.2)) +
  coord_sf(crs = eqearth, datum = NA, expand = FALSE, clip = "off") +
  labs(
    title = "1Nov_Points: Little Netherlands",
    subtitle = paste0(nrow(places), " places whose names are linked to a Dutch town or province ",
                          "(per Wikipedia / Wikidata), with faint arcs to the Dutch place"),
    caption = "Data from Wikidata, GeoNames and Natural Earth.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026.",
    shape = NULL, size = NULL, x = NULL, y = NULL
  ) +
  theme_void(base_family = "sans") +
  theme(
    plot.background = element_rect(fill = bg, colour = NA),
    panel.background = element_rect(fill = bg, colour = NA),
    plot.title = element_text(colour = orange, size = 22, face = "bold"),
    plot.subtitle = element_text(colour = "grey80", size = 11, margin = margin(t = 4, b = 10)),
    plot.caption = element_text(colour = "grey65", size = 8, hjust = 1),
    legend.position = "inside",
    legend.position.inside = c(0.04, 0.5),
    legend.text = element_text(colour = "grey85", size = 8),
    legend.key.size = unit(10, "pt"),
    plot.margin = margin(20, 20, 14, 20)
  )

ggsave("map.png", p, width = 3000, height = 2000, units = "px", dpi = 300, bg = bg)
