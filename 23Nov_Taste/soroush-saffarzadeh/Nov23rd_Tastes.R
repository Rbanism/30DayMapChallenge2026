install.packages("maps")
install.packages("cbsodataR")

library(sf)
library(ggplot2)
library(magick)
library(patchwork)
library(tidyverse)
library(tidygeocoder)
library(cbsodataR)
library(grid)
library(ggrepel)

cities <- cbs_get_sf("gemeente", 2026, verbose = TRUE)

spots <- cities|>
  filter(statnaam %in% c("Delft", "'s-Gravenhage", "Utrecht",
                         "Amsterdam", "Rotterdam"))|>
  mutate(statnaam = ifelse(statnaam == "'s-Gravenhage", "Den Haag", statnaam))|>
  st_transform(28992)

nl <- cbs_get_sf("provincie", 2026, verbose = TRUE)

base <- st_transform(nl, 28992)

saved_places <- read.csv("Data/Saved/Food.csv")|>
  mutate(category = "Food")
coffee_spots <- read.csv("Data/Saved/Coffee Spots.csv", skip = 2)|>
  mutate(category = "Coffee")

all_saved <- bind_rows(
  saved_places |> select(Title, URL, category),
  coffee_spots |> select(Title, URL, category))|>
  filter(!is.na(Title), Title != "")


geocoded_all <- all_saved |>
  mutate(search_query = paste0(Title, ", Netherlands")) |>
  geocode(address = "search_query", method = "osm", lat = "latitude", long = "longitude") |>
  drop_na(longitude, latitude)


spatial_sf <- st_as_sf(geocoded_all, coords = c("longitude", "latitude"), crs = 4326)|>
  st_transform(28992)

anchor_pt <- st_centroid(spots |>
                           filter(statnaam == "Den Haag"))|>
  mutate(anchor = "Den Haag Centraal")

within_nl <- st_filter(spatial_sf, spots, .predicate = st_intersects)

provinces <- st_filter(base, within_nl, .predicate = st_intersects)

region_bbox <- st_bbox(spots)

# Compute distance and standard inverted Min-Max proximity score (0 to 1)
distance_score <- within_nl |>
  mutate(
    dist_m = as.numeric(st_distance(geometry, anchor_pt)),
    dist_km = dist_m / 1000,
    # Standard inverted Min-Max formula: 1 = closest spot, 0 = furthest spot
    proximity_score = 1 - ((dist_km - min(dist_km)) / (max(dist_km) - min(dist_km)))
  )


# Ensure km_breaks and km_labels are defined cleanly
min_km <- min(distance_score$dist_km)
max_km <- max(distance_score$dist_km)

km_breaks <- 1 - ((c(20, 10, min_km) - min_km) / (max_km - min_km))
km_labels <- c(
  "Too far (> 20 km)",
  "Meh, maybe? (10–20 km)",
  "Lets Go! (≤ 10 km)"
)

#  Drop geometry first, clean strings, build a named color vector for all <= 10 km spots
shortlist_df <- distance_score |>
  st_drop_geometry() |>
  filter(dist_km <= 10, !is.na(Title), Title != "") |>
  distinct(Title, .keep_all = TRUE) |>
  arrange(category, dist_km) # Groups by Coffee/Food, sorted closest first

# Named vector: names = Title, values = exact category hex color
shortlist_colors <- setNames(
  ifelse(trimws(tolower(shortlist_df$category)) == "food", "#ff6b6b", "#f4a261"),
  shortlist_df$Title)



#  Plot with both Food and Coffee <= 10 km venues listed and color-coded in the legend
p <- ggplot() +
  geom_sf(data = base, fill = "#242c3d", color = "#3a465e", linewidth = 0.4) +
  geom_sf(data = spots, fill = "#323d54", color = "#526282", linewidth = 0.8) +
  # Weighted Food & Coffee points
  geom_sf(
    data = distance_score,
    aes(color = category, size = proximity_score, alpha = proximity_score)
  ) + 
  # Invisible layer solely to list ALL shortlisted (<= 10 km) Food & Coffee names in the legend
  geom_sf(
    data = distance_score |> filter(Title %in% shortlist_df$Title),
    aes(fill = factor(Title, levels = shortlist_df$Title)),
    alpha = 0,
    size = 0
  ) +
  geom_sf(
    data = anchor_pt,
    aes(shape = "Den Haag Centroid (Anchor)"),
    color = "lightblue",
    size = 10,
    stroke = 0.9
  ) +
  geom_sf_text(
    data = spots,
    aes(label = statnaam),
    size = 3,
    fontface = "bold",
    color = "white",
    alpha = 0.85,
    vjust = -0.5,
    hjust = 0.7
  ) +
  scale_color_manual(
    name = "Category",
    values = c("Food" = "#ff6b6b", "Coffee" = "#f4a261")
  ) +
  scale_shape_manual(
    name = NULL,
    values = c("Den Haag Centroid (Anchor)" = 1)
  ) +
  # Maps each shortlisted venue to its exact Food (#ff6b6b) or Coffee (#f4a261) color
  scale_fill_manual(
    name = "Shortlisted (≤ 10 km)",
    values = shortlist_colors,
    drop = FALSE
  ) +
  scale_size_continuous(
    name = "Worth the Trip?",
    breaks = km_breaks,
    labels = km_labels,
    trans = "exp",
    range = c(0.75, 7.5)
  ) +
  scale_alpha_continuous(
    name = "Worth the Trip?",
    breaks = km_breaks,
    labels = km_labels,
    range = c(0.2, 1.0)
  ) +
  guides(
    color = guide_legend(order = 1, override.aes = list(size = 4, alpha = 1)),
    size  = guide_legend(order = 2, override.aes = list(color = "white", shape = 16)),
    alpha = guide_legend(order = 2, override.aes = list(color = "white", shape = 16)),
    shape = guide_legend(order = 3, override.aes = list(color = "lightblue", size = 5, stroke = 0.9)),
    fill  = guide_legend(
      order = 4,
      override.aes = list(shape = 21, size = 3, alpha = 1, color = NA)
    )
  ) +
  coord_sf(
    xlim = c(region_bbox["xmin"], region_bbox["xmax"]),
    ylim = c(region_bbox["ymin"], region_bbox["ymax"])
  ) +
  theme(
    panel.background  = element_rect(fill = "#161b26", color = NA),
    plot.background   = element_rect(fill = "#161b26", color = NA),
    panel.grid.major  = element_blank(),
    panel.grid.minor  = element_blank(),
    axis.text         = element_blank(),
    axis.ticks        = element_blank(),
    axis.title        = element_blank(),
    plot.title        = element_text(color = "white", face = "bold", size = 13),
    plot.subtitle     = element_text(color = "gray80", size = 10),
    plot.caption      = element_text(color = "gray75", hjust = 1, size = 9, margin = margin(t = 10)),
    legend.background = element_blank(),
    legend.key        = element_blank(),
    legend.key.height = unit(0.35, "cm"),
    legend.text       = element_text(color = "white", size = 8),
    legend.title      = element_text(color = "white", size = 10, face = "bold")
  ) +
  labs(
    title = "Saved Food & Coffee Spots of Google Maps Weighted by Proximity to Den Haag",
    subtitle = "Min-Max normalized proximity (0-1) mapped to real-world kilometer thresholds (labels within 10 km)",
    caption = "#30DayMapChallenge — 'Nov. 23rd, Senses: Taste' by Soroush Saffarzadeh, 2026. Data: Google Maps, OSM, CBS."
  )


print(p)


# Convert your zoom bounding box into a drawable sf rectangle
bbox_poly <- st_as_sfc(region_bbox)

p_keymap <- ggplot() +
  geom_sf(data = base, fill = "#242c3d", color = "#3a465e", linewidth = 0.2) +
  geom_sf(
    data = bbox_poly,
    fill = alpha("yellow", 0.15),
    color = "yellow",
    linewidth = 0.4
  ) +
  theme_void() +
  theme(
    panel.background = element_rect(fill = "#161b26", color = "#526282", linewidth = 0.3),
    plot.background  = element_rect(fill = "#161b26", color = NA)
  )

p_final <- p + inset_element(
  p_keymap,
  left   = 0.02,
  bottom = 0.72,
  right  = 0.24,
  top    = 0.98
)

print(p_final)

rbanism_logo <- image_read("Logo_Rbanism_ White.png")


grid.raster(rbanism_logo,
            x = 0.80, y=0.1,
            width = unit(45, "points"))



