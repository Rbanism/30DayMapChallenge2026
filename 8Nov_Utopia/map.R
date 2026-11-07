# 30 Day Map Challenge
# 8 November - Utopia
# Roxanne Vuijk

## DATA
# NASA LRO/LOLA south pole DEM, 80m/pixel

# Barker et al., 2023 Planet. Sci. J., 4, 183. https://doi.org/10.3847/PSJ/acf3e1
# Data DOI: 10.60903/gsfcpgda-lola-spole

# download packages
install.packages(c("terra", "ggplot2", "dplyr", "png"))
install.packages("ggnewscale")

# load installed packages
library(terra)
library(ggplot2)
library(dplyr)

# download data
options(timeout = max(500, getOption("timeout")))

if (!file.exists("8Nov_Utopia/raw/LDEM_80S_80MPP_ADJ.TIF") ) 
  { download.file( url = "https://pgda.gsfc.nasa.gov/data/LOLA_20mpp/LDEM_80S_80MPP_ADJ.TIF",
              destfile = "8Nov_Utopia/raw/LDEM_80S_80MPP_ADJ.TIF",
              mode = "wb")
              }

download.file( url = "https://pgda.gsfc.nasa.gov/data/LOLA_20mpp/LDEM_80S_80MPP_ADJ.TIF",
              destfile = "8Nov_Utopia/raw/LDEM_80S_80MPP_ADJ.TIF",
              mode = "wb")

# V1 lines: create raster grid + heights

elevation_lspole <- rast("8Nov_Utopia/raw/LDEM_80S_80MPP_ADJ.TIF")

elevation_lspole

minmax(elevation_lspole, compute = TRUE)

plot(elevation_lspole)



elevation_lspole_low <- aggregate(elevation_lspole, fact = c(38, 4), fun="mean")

elevation_lspole_low

plot(elevation_lspole_low)

# table V1

elevation_lspole_df <- as.data.frame(elevation_lspole_low, xy = TRUE)

elevation_lspole_df <- rename(elevation_lspole_df, elevation = LDEM_80S_80MPP_ADJ)

# circle V1

radius <- 270000

elevation_lspole_circle <- filter(elevation_lspole_df, sqrt(x^2 + y^2) <= radius)


# V2 raster: create raster grid + heights

elevation_lspole <- rast("8Nov_Utopia/raw/LDEM_80S_80MPP_ADJ.TIF")

elevation_lspole

minmax(elevation_lspole, compute = TRUE)

plot(elevation_lspole)



elevation_lspole_raster <- aggregate(elevation_lspole, fact = 8, fun = "mean")

elevation_lspole_raster

plot(elevation_lspole_raster)

# table V2

elevation_raster_df <- as.data.frame(elevation_lspole_raster, xy = TRUE)

elevation_raster_df <- rename(elevation_raster_df, elevation = LDEM_80S_80MPP_ADJ)

# circle V2

radius <- 270000

elevation_raster_circle <- filter(elevation_raster_df, sqrt(x^2 + y^2) <= radius)

# plot + visualize V2
map <- ggplot () +
  geom_raster(data = elevation_raster_df, aes(x = x, y = y, fill = elevation)) + 
  scale_fill_gradient(low = "black", high = "grey40", guide = "none") + 
  scale_x_continuous(
    breaks = seq(-300000, 300000, 100000),
    labels = seq(-300,300,100),
    expand = c(0, 0),
    sec.axis = dup_axis(name = NULL)
  ) + 
  scale_y_continuous(
    breaks = seq(-300000, 300000, 100000),
    labels = seq(-300,300,100),
    expand = c(0, 0),
    sec.axis = dup_axis(name = NULL)
  ) + 
  theme_minimal() +
  theme(panel.grid = element_blank(), 
        axis.ticks = element_line(colour = "white"), 
        axis.title.x = element_text(hjust = 0), 
        plot.background = element_rect(fill = "black", colour = NA), 
        text = element_text(colour = "white"),
        axis.text = element_text(colour = "white")
        ) +
  labs(x = "Distance from pole (km)", y = NULL) + 
  coord_equal()

map

# add circle on top

angle <- seq(0, 2 * pi, length.out = 360)

points_table <- data.frame(
  x = 100000 * cos(angle),
  y = 100000 * sin(angle)
)

points_table2 <- data.frame(
  x = 200000 * cos(angle),
  y = 200000 * sin(angle)
)

points_table_pole <- data.frame(
  x = 1000 * cos(angle),
  y = 1000 * sin(angle)
)

map_circle <- map + 
  new_scale_fill() +
  geom_raster(data = elevation_raster_circle, aes(x = x, y = y, fill = elevation)) + 
  scale_fill_gradient2(
    low = "#554846", 
    mid = "#A5AEB7", 
    high = "#C8E0F4", 
    midpoint = 0, 
    name = "Elevation (m)\nrelative to mean radius", 
    breaks = seq(-7200, 7200, 7200), 
    limits = c(-7200, 7200)) +
  geom_vline(xintercept = seq(-300000, 300000, 100000), colour = "white", linewidth = 0.2, alpha = 0.5) +
  geom_hline(yintercept = seq(-300000, 300000, 100000), colour = "white", linewidth = 0.2, alpha = 0.5) +
  geom_vline(xintercept = 0, colour = "white", linewidth = 0.2) +
  geom_hline(yintercept = 0, colour = "white", linewidth = 0.2) +
  geom_path(data = points_table, aes(x=x, y=y), colour = "white", linewidth = 0.2) +
  geom_path(data = points_table2, aes(x=x, y=y), colour = "white", linewidth = 0.2, alpha = 0.5) +
  geom_path(data = points_table_pole, aes(x=x, y=y), colour = "white", linewidth = 2)

map_circle
