# Hexagon map: earthquakes in and around Greece (M4+, 2000 till today)
# Data: USGS Earthquake Catalog (downloaded live, free)

#install.packages(c("sf", "ggplot2", "dplyr", "maps"))  # run once
#install.packages("ggspatial")
#install.packages(c("patchwork", "png"))

library(sf)
library(ggplot2)
library(dplyr)
library(ggspatial)
library(patchwork)


# Greek Grid (GGRS87 / EPSG:2100): metres, made for Greece
crs_greece <- 2100

#1 Download earthquakes from USGS 
#url <- paste0(
#  "https://earthquake.usgs.gov/fdsnws/event/1/query?format=csv",
#  "&starttime=2000-01-01",
#  "&minlatitude=32&maxlatitude=43",
#  "&minlongitude=17&maxlongitude=31",
#  "&minmagnitude=4"
#)
#Download only the first time, afterwards use the saved CSV in this folder

eq <- read.csv("greece_earthquakes.csv")
cat(nrow(eq), "earthquakes loaded\n")

eq_sf <- eq |>
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326) |>
  st_transform(crs_greece)

#2 Land: Greece highlighted, neighbours for context 
world <- maps::map("world", fill = TRUE, plot = FALSE,
                   xlim = c(15, 35), ylim = c(30, 46)) |>
  st_as_sf() |>
  st_make_valid() |>
  st_transform(crs_greece)

greece     <- filter(world, ID == "Greece")
neighbours <- filter(world, ID != "Greece")

#3 Hexagon grid 
hex_size <- 15000   # metres (15000 = 15 km) try 25000 for bigger hexagons

hexes <- st_make_grid(eq_sf, cellsize = hex_size, square = FALSE) |>
  st_as_sf() |>
  mutate(hex_id = row_number())

#4 Count earthquakes per hexagon 
hex_stats <- st_join(eq_sf, hexes) |>
  st_drop_geometry() |>
  group_by(hex_id) |>
  summarise(n = n(), max_mag = max(mag), depth = mean(depth))

hexes <- hexes |>
  left_join(hex_stats, by = "hex_id") |>
  filter(!is.na(n))

#5 Plot 
bbox <- st_bbox(st_transform(
  st_as_sfc(st_bbox(c(xmin = 17, xmax = 31, ymin = 32, ymax = 43),
                    crs = 4326)), crs_greece))

p <- ggplot() +
  geom_sf(data = neighbours, fill = "#1d1f24", colour = "#2a2d33", linewidth = 0.2) +
  geom_sf(data = greece,     fill = "#33363d", colour = NA) +
  geom_sf(data = hexes, aes(fill = n), colour = NA,
          alpha = 0.9) +
  geom_sf(data = greece, fill = NA, colour = "grey50", linewidth = 0.2, alpha = 0.8) +
  scale_fill_viridis_c(
    option = "magma", begin = 0.15, transform = "log10",
    name = "Earthquakes per hexagon",
    guide = "colourbar"
  ) +
  annotation_scale(
    location = "br",                 # bottom right
    width_hint = 0.2,                
    style = "bar",
    bar_cols = c("grey85", "#111216"),
    line_col = "grey85",
    text_col = "grey85",
    pad_x = unit(0.5, "cm"),
    pad_y = unit(0.5, "cm")
  ) +
  coord_sf(xlim = bbox[c("xmin", "xmax")], ylim = bbox[c("ymin", "ymax")],
           expand = FALSE, datum = NA) +
  labs(
    title    = "Day20_Hexagons: Greece's Earthquakes",
    subtitle = paste0(format(nrow(eq), big.mark = ","),
                      " earthquakes of magnitude 4+ in and around Greece, 2000-2026,\n",
                      "counted in 15 km hexagons"),
    caption  = "Data: USGS Earthquake Catalog | Map: Evangelia Palli | #30DayMapChallenge") +
  theme_void(base_family = "sans") +
  theme(
    plot.background  = element_rect(fill = "#111216", colour = NA),
    panel.background = element_rect(fill = "#111216", colour = NA),
    text             = element_text(colour = "grey85"),
    plot.title       = element_text(size = 22, face = "bold", colour = "white"),
    plot.subtitle    = element_text(size = 11, margin = margin(b = 10)),
    plot.caption     = element_text(size = 8, colour = "grey55"),
    legend.position  = "bottom",
    legend.justification = "left",
    legend.title.position = "top",
    legend.key.width = unit(3.5, "cm"),
    legend.key.height = unit(0.35, "cm"),
    plot.margin      = margin(20, 20, 15, 20)
  )

logo <- grid::rasterGrob(png::readPNG("Logo_Rbanism_White.png"))

final <- p +
  inset_element(logo, left = 0.82, bottom = 0.86, right = 0.98, top = 0.99,
                align_to = "full") &
  theme(plot.background = element_rect(fill = "#111216", colour = NA))

ggsave("hexagon_greece.png", final, width = 9, height = 9, dpi = 300,
       bg = "#111216")