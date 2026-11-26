# THE WORLD IN MOTION
# GLOBAL MIGRATION NETWORK — 2024
# #30DayMapChallenge | 13Nov_Interactions
# Author: Rashi Karkoon

# 1. Loading Packages along with already installed ones
packages <- c(
  "httr",
  "openxlsx",
  "dplyr",
  "sf",
  "ggplot2",
  "countrycode",
  "rnaturalearth",
  "cowplot",
  "magick"
)

new_packages <- packages[
  !packages %in% rownames(installed.packages())
]

if (length(new_packages) > 0) {
  install.packages(new_packages)
}

invisible(lapply(packages, library, character.only = TRUE))


# 2. Downloading the Migration Data from Website
# Source: United Nations Department of Economic and Social Affairs
# Population Division - International Migrant Stock 2024

dir.create("data", showWarnings = FALSE)

migration_url <- paste0(
  "https://www.un.org/development/desa/pd/sites/",
  "www.un.org.development.desa.pd/files/",
  "undesa_pd_2024_ims_stock_by_sex_destination_and_origin.xlsx"
)

migration_file <- "data/UN_migration_2024.xlsx"

if (!file.exists(migration_file)) {
  
  response <- httr::GET(
    migration_url,
    httr::user_agent("Mozilla/5.0"),
    httr::add_headers(
      Referer = paste0(
        "https://www.un.org/development/desa/pd/",
        "content/international-migrant-stock"
      )
    ),
    httr::timeout(120)
  )
  
  httr::stop_for_status(response)
  
  writeBin(
    httr::content(response, "raw"),
    migration_file
  )
}

stopifnot(file.exists(migration_file))

# 3. Importing Bilateral Migration table

migration <- openxlsx::read.xlsx(
  migration_file,
  sheet = "Table 1",
  startRow = 11,
  na.strings = c("..", "")
)

# Assigning distinct column names

years <- c(1990, 1995, 2000, 2005, 2010, 2015, 2020, 2024)

expected_names <- c(
  "index",
  "destination",
  "destination_notes",
  "destination_type",
  "destination_code",
  "origin",
  "origin_code",
  paste0("total_", years),
  paste0("male_", years),
  paste0("female_", years)
)

if (ncol(migration) != length(expected_names)) {
  stop(
    paste(
      "Unexpected number of columns:",
      ncol(migration),
      "- expected:",
      length(expected_names)
    )
  )
}

names(migration) <- expected_names

# Inspecting the imported data

print(head(migration))
print(dim(migration))


# 4. Cleaning the 2024 Migration Data

migration_2024 <- migration %>%
  mutate(
    destination_code = as.numeric(destination_code),
    origin_code = as.numeric(origin_code),
    total_2024 = as.numeric(total_2024)
  ) %>%
  filter(
    !is.na(destination_code),
    !is.na(origin_code),
    destination_code < 900,
    origin_code < 900,
    !is.na(total_2024),
    total_2024 > 0
  )


# 5. Converting the Country Codes TO ISO3

migration_2024 <- migration_2024 %>%
  mutate(
    destination_iso = countrycode::countrycode(
      destination_code,
      origin = "un",
      destination = "iso3c",
      warn = FALSE
    ),
    origin_iso = countrycode::countrycode(
      origin_code,
      origin = "un",
      destination = "iso3c",
      warn = FALSE
    )
  ) %>%
  filter(
    !is.na(destination_iso),
    !is.na(origin_iso),
    destination_iso != origin_iso
  )


# 6. Downloading World Country Boundaries

world <- rnaturalearth::ne_countries(
  scale = "medium",
  returnclass = "sf"
)

# Robinson projection

robinson_crs <- "+proj=robin +lon_0=0 +datum=WGS84 +units=m +no_defs"

world_projected <- st_transform(
  world,
  crs = robinson_crs
)

# Creating one representative point per country for lines origin or destination

country_points <- st_point_on_surface(world_projected)

point_coordinates <- st_coordinates(country_points)

country_lookup <- world_projected %>%
  st_drop_geometry() %>%
  transmute(
    iso3 = iso_a3,
    origin_region = region_un
  ) %>%
  mutate(
    x = point_coordinates[, 1],
    y = point_coordinates[, 2]
  ) %>%
  filter(!is.na(iso3), iso3 != "-99") %>%
  distinct(iso3, .keep_all = TRUE)


# 7. Joining the Origin and Destination

routes <- migration_2024 %>%
  left_join(
    country_lookup %>%
      rename(
        origin_iso = iso3,
        origin_x = x,
        origin_y = y
      ),
    by = "origin_iso"
  ) %>%
  left_join(
    country_lookup %>%
      select(
        iso3,
        destination_x = x,
        destination_y = y
      ),
    by = c("destination_iso" = "iso3")
  ) %>%
  filter(
    !is.na(origin_region),
    !is.na(origin_x),
    !is.na(origin_y),
    !is.na(destination_x),
    !is.na(destination_y)
  )

# Check how many routes were matched

cat("Matched migration connections:", nrow(routes), "\n")

cat(
  "Unmatched origin/destination records:",
  nrow(migration_2024) - nrow(routes),
  "\n"
)


# 8. Selecting the Largest Migration Connection

# Keep the strongest 400 bilateral connections

routes_top <- routes %>%
  slice_max(
    order_by = total_2024,
    n = 400,
    with_ties = FALSE
  ) %>%
  mutate(route_id = row_number())

cat("Connections selected for map:", nrow(routes_top), "\n")


# 9. Creating Curved Connections for the Lines

# Quadratic Bezier curve in projected map coordinates

make_curve <- function(x0, y0, x1, y1, n = 40) {
  
  dx <- x1 - x0
  dy <- y1 - y0
  
  distance <- sqrt(dx^2 + dy^2)
  
  if (distance == 0) {
    return(NULL)
  }
  
  # Control point creates the arc
  
  bend <- distance * 0.16
  
  cx <- (x0 + x1) / 2 - (dy / distance) * bend
  cy <- (y0 + y1) / 2 + (dx / distance) * bend
  
  t <- seq(0, 1, length.out = n)
  
  x <- (1 - t)^2 * x0 +
    2 * (1 - t) * t * cx +
    t^2 * x1
  
  y <- (1 - t)^2 * y0 +
    2 * (1 - t) * t * cy +
    t^2 * y1
  
  data.frame(x = x, y = y)
}


curve_list <- lapply(seq_len(nrow(routes_top)), function(i) {
  
  r <- routes_top[i, ]
  
  curve <- make_curve(
    r$origin_x,
    r$origin_y,
    r$destination_x,
    r$destination_y
  )
  
  if (is.null(curve)) return(NULL)
  
  curve$route_id <- r$route_id
  curve$origin_region <- r$origin_region
  curve$total_2024 <- r$total_2024
  
  curve
})

curves <- bind_rows(curve_list)


# 10. Color Pallete as per the origin country

region_colours <- c(
  "Africa" = "#F08A5D",
  "Americas" = "#E6B85C",
  "Asia" = "#4CC9B0",
  "Europe" = "#B18CFF",
  "Oceania" = "#58A6E7"
)


# 11. Drawing the Migration Map Final

migration_map <- ggplot() +
  
  # World boundaries
  
  geom_sf(
    data = world_projected,
    fill = "#111318",
    color = "#454950",
    linewidth = 0.22
  ) +
  
  # Curved migration connections
  
  geom_path(
    data = curves,
    aes(
      x = x,
      y = y,
      group = route_id,
      color = origin_region,
      linewidth = total_2024
    ),
    alpha = 0.55,
    lineend = "round"
  ) +
  
  # Region colours
  
  scale_color_manual(
    values = region_colours,
    name = "Origin region"
  ) +
  
  guides(
    color = guide_legend(
      override.aes = list(
        linewidth = 2.5,
        alpha = 1
      )
    )
  ) +
  
  # Larger migration stocks have thicker lines
  
  scale_linewidth_continuous(
    range = c(0.12, 1.0),
    trans = "sqrt",
    guide = "none"
  ) +
  
  # Map projection
  
  coord_sf(
    crs = robinson_crs,
    datum = NA,
    expand = FALSE
  ) +
  
  # Title, subtitle and credits
  
  labs(
    title = "THE WORLD IN MOTION",
    subtitle = "#30DayMapChallenge | 13Nov_Interactions:Global migration network",
    caption = paste(
      "Author: Rashi Karkoon",
      "Source:  UN DESA, International Migrant Stock 2024",
      "Line colour represents the origin region.",
      sep = "\n"
    )
  ) +
  
  # Remove standard chart elements
  
  theme_void() +
  
  # Custom styling
  
  theme(
    
    plot.background = element_rect(
      fill = "#050609",
      color = NA
    ),
    
    panel.background = element_rect(
      fill = "#050609",
      color = NA
    ),
    
    # Reduced title size
    
    plot.title = element_text(
      color = "#F5F1E9",
      size = 21,
      face = "bold",
      hjust = 0.5,
      margin = margin(b = 10)
    ),
    
    # Subtitle
    
    plot.subtitle = element_text(
      color = "#E6B85C",
      size = 11,
      hjust = 0.5,
      margin = margin(b = 15)
    ),
    
    # Author and source credits
    
    plot.caption = element_text(
      color = "#999999",
      size = 8,
      hjust = 0.5,
      lineheight = 1.3,
      margin = margin(t = 15)
    ),
    
    # Legend position and styling
    
    legend.position = "bottom",
    
    legend.title = element_text(
      color = "#F5F1E9"
    ),
    
    legend.background = element_rect(
      fill = "#050609",
      color = NA
    ),
    
    legend.key.width = grid::unit(0.8, "cm"),
    legend.spacing.x = grid::unit(0.15, "cm"),
    legend.text = element_text(
      color = "#D0D0D0",
      size = 9
    ),
    
    # Overall margins
    
    plot.margin = margin(20, 0, 20, 0)
  )


# 12. Adding the Logo

logo_file <- list.files(
  "data",
  pattern = "Logo",
  full.names = TRUE,
  ignore.case = TRUE
)

logo_path <- logo_file

final_map <- cowplot::ggdraw() +
  
  cowplot::draw_plot(
    migration_map,
    x = -0.007,
    y = 0,
    width = 1,
    height = 1
  ) +
  
  cowplot::draw_image(
    logo_path,
    x = 0.78,
    y = 0.035,
    width = 0.07,
    height = 0.07
  )


# 13. Printing the Final Map

print(final_map)


# 14. Exporting the Map in Folder

ggsave(
  "map.png",
  plot = final_map,
  width = 12,
  height = 8.5,
  dpi = 300,
  bg = "#050609"
)

cat("MAP EXPORTED SUCCESSFULLY\n")

# END OF SCRIPT
