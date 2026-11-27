# install.packages("maps")
# install.packages("ggplot2")

library(sf)
library(ggplot2)
library(magick)
library(patchwork)
library(tidyverse)
library(tidygeocoder)
library(grid)
library(ggrepel)
library(ggforce)


data <- read.csv("Data/processed_data.csv")


preprocessed <- data|>
  select(Topic, contextuality, eng_name, sentiment_label,
         sentiment_score, Count, type, timeline)|>
  filter(contextuality == "Local")|>
  mutate(Topic = as.character(Topic))

unique(preprocessed$Topic)

# Create a dataframe based on spatial topics and their
# corresponding key places
topic_to_place <- tribble(
  ~Topic, ~place_name,
  #  City Theater Specifics
  "5",    "City Theater Metro & Underpass",
  "13",   "City Theater",
  "19",   "City Theater",
  # Tajrish Specifics
  "11",   "Tajrish Sqr.",
  "37",   "Tajrish Sqr.",
  # Valiasr Specifics
  "16",   "Valiasr St.",
  "18",   "Valiasr St.",
  "18",   "Tajrish Sqr.",
  "32",   "Valiasr St.",
  "86",   "Valiasr St.",
  "86",   "Tajrish Sqr.",
  # Vanak
  "1",    "Vanak Sqr.", 
  "86",   "Vanak Sqr.",
  # Topics that go to multiple tweets
  "0",    "Valiasr St.",
  "31",   "City Theater",
  "31",   "Tajrish Sqr.",
  "30",   "City Theater",
  "30",   "Vanak Sqr.",
  # Grand Bazaar and markets
  "2",    "Grand Bazaar"
)|>
  distinct(Topic, place_name)


topic_to_place_wide <- topic_to_place |>
  group_by(Topic) |>
  mutate(loc_id = row_number()) |>
  ungroup() |>
  pivot_wider(
    names_from = loc_id,
    values_from = place_name,
    names_prefix = "place_name"
  )

# Join to preprocessed data
place_links <- preprocessed |>
  left_join(topic_to_place_wide, by = "Topic") |>
  mutate(
    place_name1 = coalesce(place_name1, "Tehran Urban Spaces")
  )

# Geocode unique place names once (expanding Sqr./St. helps OSM match reliably)
unique_places <- tibble(
  place_name = unique(na.omit(c(place_links$place_name1, place_links$place_name2)))
) |>
  mutate(
    search_query = place_name |>
      str_replace("Sqr\\.", "Square") |>
      str_replace("St\\.", "Street") |>
      paste0(", Tehran, Iran")
  ) |>
  geocode(
    address = "search_query",
    method = "osm",
    lat = "lat",
    long = "long"
  ) |>
  select(place_name, lat, long)

# Attach coordinates separately for location 1 and location 2
geotagged <- place_links |>
  left_join(unique_places, by = c("place_name1" = "place_name")) |>
  rename(lat1 = lat, long1 = long) |>
  left_join(unique_places, by = c("place_name2" = "place_name")) |>
  rename(lat2 = lat, long2 = long) |>
  drop_na(lat1, long1)

spatial_sf <- st_as_sf(geotagged, coords = c("lat1", "long1"), crs = 4326)|>
  st_as_sf(geotagged, coords = c("lat2", "long2"), crs = 4326)|>
  st_transform(32639)

# Pivot lat1/long1 and lat2/long2 into long format so multi-location topics appear at both spots
geotagged_long <- geotagged |>
  select(-contextuality) |>
  pivot_longer(
    cols = matches("^(place_name|lat|long)[0-9]+$"),
    names_to = c(".value", "loc_slot"),
    names_pattern = "^(place_name|lat|long)([0-9]+)$"
  ) |>
  filter(!is.na(lat), !is.na(long))


# Summarise sentiment counts and complete missing sentiments only within valid topic-location pairs
topic_sentiment24 <- geotagged_long |>
  group_by(Topic, eng_name, place_name, lat, long, sentiment_label) |>
  summarise(tweet_count = n(), .groups = "drop") |>
  complete(
    nesting(Topic, eng_name, place_name, lat, long),
    sentiment_label,
    fill = list(tweet_count = 0)
  ) |>
  group_by(Topic, eng_name, place_name, lat, long) |>
  mutate(
    tweet_total = sum(tweet_count),
    sentiment_pct   = ifelse(tweet_total > 0, (tweet_count / tweet_total) * 100, 0),
    label_text  = paste0(round(sentiment_pct, 1), "% (", tweet_count, ")")
  ) |>
  ungroup()

locations_utm <- topic_sentiment24 |>
  distinct(Topic, eng_name, place_name, lat, long) |>
  st_as_sf(coords = c("long", "lat"), crs = 4326) |>
  st_transform(st_crs(tehran))

coords_m <- st_coordinates(locations_utm)

locations_utm_df <- locations_utm |>
  st_drop_geometry() |>
  mutate(
    x_utm = coords_m[, "X"],
    y_utm = coords_m[, "Y"]
  )


outer_r_m       <- 800   # 900 m outer radius (1.8 km wide rings)
inner_r_m       <- 380   # 420 m inner donut hole
offset_radius_m <- 2100  # 2,400 m push away from shared hubs (City Theater, Tajrish, Valiasr)

location_offsets <- locations_utm_df |>
  group_by(x_utm, y_utm) |>
  mutate(
    n_shared = n(),
    idx      = row_number(),
    angle    = ifelse(n_shared == 1, 0, (2 * pi * (idx - 1) / n_shared) + (pi / 4)),
    x_adj    = ifelse(n_shared == 1, x_utm, x_utm + offset_radius_m * cos(angle)),
    y_adj    = ifelse(n_shared == 1, y_utm, y_utm + offset_radius_m * sin(angle))
  ) |>
  ungroup()


topic_legend_df <- location_offsets |>
  distinct(Topic, eng_name) |>
  mutate(topic_num = as.numeric(Topic)) |>
  arrange(topic_num) |>
  mutate(legend_label = paste0("T", Topic, ": ", eng_name))

location_offsets <- location_offsets |>
  left_join(topic_legend_df |> select(Topic, legend_label), by = "Topic")

donut_data <- topic_sentiment24 |>
  mutate(sentiment_label = str_to_title(trimws(sentiment_label))) |>
  left_join(location_offsets, by = c("Topic", "eng_name", "place_name")) |>
  arrange(Topic, place_name, sentiment_label) |>
  group_by(Topic, eng_name, place_name, x_adj, y_adj) |>
  mutate(
    frac        = sentiment_pct / 100,
    end_angle   = cumsum(frac) * 2 * pi,
    start_angle = lag(end_angle, default = 0),
    mid_angle   = (start_angle + end_angle) / 2
  ) |>
  ungroup()

focus_area <- st_as_sf(donut_data, coords = c("long", "lat"), crs = 4326)|>
  st_transform(32639)

pad_x <- 4500  
pad_y <- 2500 

custom_bbox <- c(
  xmin = min(location_offsets$x_adj) - outer_r_m - pad_x,
  xmax = max(location_offsets$x_adj) + outer_r_m + pad_x,
  ymin = min(location_offsets$y_adj) - outer_r_m - pad_y,
  ymax = max(location_offsets$y_adj) + outer_r_m + pad_y
)

region_bbox <- st_bbox(custom_bbox)

p <- ggplot() +
  geom_sf(data = tehran, fill = "gray15", color = "gray15", linewidth = 0.4) +
  geom_sf(data = tehran_blocks, fill = "#242c3d", color = "#3a465e", linewidth = 0.03) +
  
  # Leader lines connecting true landmark coordinates to offset ring centers
  geom_segment(
    data = location_offsets |> filter(n_shared > 1),
    aes(x = x_utm, y = y_utm, xend = x_adj, yend = y_adj),
    color = "gray65",
    linetype = "dashed",
    linewidth = 0.35
  ) +
  # Anchor dot at the exact landmark coordinate for multi-topic points
  geom_point(
    data = location_offsets |> filter(n_shared > 1) |> distinct(x_utm, y_utm),
    aes(x = x_utm, y = y_utm),
    color = "#faa819",
    size = 1.8
  ) +
  # Invisible layer solely to populate the Topics legend
  geom_point(
    data = location_offsets,
    aes(
      x     = x_adj,
      y     = y_adj,
      color = factor(legend_label, levels = topic_legend_df$legend_label)
    ),
    alpha = 0,
    size = 0
  ) +
  # Ring (donut) pie charts per topic-location
  geom_arc_bar(
    data = donut_data,
    aes(
      x0    = x_adj,
      y0    = y_adj,
      r0    = inner_r_m,
      r     = outer_r_m,
      start = start_angle,
      end   = end_angle,
      fill  = sentiment_label
    ),
    color = "#161b26",
    linewidth = 0.35
  ) +
  # Percentage labels inside slices (>= 12% shown to keep slices legible)
  geom_text(
    data = donut_data |> filter(sentiment_pct >= 12),
    aes(
      x     = x_adj + ((inner_r_m + outer_r_m) / 2) * sin(mid_angle),
      y     = y_adj + ((inner_r_m + outer_r_m) / 2) * cos(mid_angle),
      label = paste0(round(sentiment_pct), "%")
    ),
    color = "white",
    size = 2.0,
    fontface = "bold"
  ) +
  # Compact topic ID centered inside the hollow donut hole (zero overlap)
  geom_text(
    data = location_offsets,
    aes(
      x     = x_adj,
      y     = y_adj,
      label = paste0("T", Topic)
    ),
    color = "#faa819",
    size = 2.3,
    fontface = "bold"
  ) +
  
  scale_fill_manual(
    name = "Sentiment",
    values = c(
      "Positive" = "#2ec4b6",
      "Neutral"  = "#8d99ae",
      "Negative" = "#ff6b6b"
    )
  ) +
  scale_color_manual(
    name = "Topics",
    values = setNames(rep("#faa819", nrow(topic_legend_df)), topic_legend_df$legend_label)
  ) +
  guides(
    fill  = guide_legend(order = 1),
    color = guide_legend(
      order = 2,
      override.aes = list(shape = NA, alpha = 0),
      keywidth = unit(0, "pt")
    )
  ) +
  coord_sf(
    xlim = c(region_bbox["xmin"], region_bbox["xmax"]),
    ylim = c(region_bbox["ymin"], region_bbox["ymax"]),
    expand = FALSE
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
    legend.key.height = unit(0.38, "cm"),
    legend.text       = element_text(color = "white", size = 8.5),
    legend.title      = element_text(color = "white", size = 10, face = "bold")
  ) +
  labs(
    title = "Spatial Sentiment Analysis per Topic in Tehran, 2022-2026",
    subtitle = "Ring charts show sentiment share per topic; shared landmarks are radially offset",
    caption = "#30DayMapChallenge — 'Nov. 28th, Senses: Feeling' by Soroush Saffarzadeh, 2026. 
    Data: 4TU.ResearchData originated from X(Formerly Twitter), 2026."
  )

print(p)

if (is.na(st_crs(tehran))) {
  st_crs(tehran) <- 32639
}

# Convert `region_bbox` to an sfc polygon and explicitly set its CRS
bbox_poly <- region_bbox |>
  st_as_sfc() |>
  st_set_crs(st_crs(tehran))

# Rebuild keymap and combine with main plot
p_keymap <- ggplot() +
  geom_sf(data = tehran, fill = "#242c3d", color = "#3a465e", linewidth = 0.2) +
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
  bottom = 0.62,
  right  = 0.32,
  top    = 0.98
)


print(p_final)

rbanism_logo <- image_read("Logo_Rbanism_ White.png")

# plotting logo
grid.raster(rbanism_logo,
            x = 0.80, y=0.1,
            width = unit(45, "points"))



