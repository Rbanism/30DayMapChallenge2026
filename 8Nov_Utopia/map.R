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
  scale_fill_gradient(low = "grey20", high = "white") + 
  coord_equal()

map

# add circle on top

map_circle <- map + 
  new_scale_fill() +
  geom_raster(data = elevation_raster_circle, aes(x = x, y = y, fill = elevation)) + 
  scale_fill_gradient2(low = "#907768", mid = "#B5A295", high = "#394045", midpoint = 0) 


