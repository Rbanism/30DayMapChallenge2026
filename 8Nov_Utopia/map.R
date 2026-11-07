# 30 Day Map Challenge
# 8 November - Utopia
# Roxanne Vuijk

## DATA
# NASA LRO/LOLA south pole DEM, 80m/pixel

# Barker et al., 2023 Planet. Sci. J., 4, 183. https://doi.org/10.3847/PSJ/acf3e1
# Data DOI: 10.60903/gsfcpgda-lola-spole

# download packages
install.packages(c("terra", "ggplot2", "dplyr", "png"))

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

## visualization

elevation_lspole_low <- aggregate(elevation_lspole, fact = c(38, 4), fun="mean")

elevation_lspole_low

plot(elevation_lspole_low)

# table 

elevation_lspole_df <- as.data.frame(elevation_lspole_low, xy = TRUE)

elevation_lspole_df <- rename(elevation_lspole_df, elevation = LDEM_80S_80MPP_ADJ)

# circle

radius <- 270000

elevation_lspole_circle <- filter(elevation_lspole_df, sqrt(x^2 + y^2) <= radius)

# V2 raster: create raster grid + heights

elevation_lspole <- rast("8Nov_Utopia/raw/LDEM_80S_80MPP_ADJ.TIF")

elevation_lspole

minmax(elevation_lspole, compute = TRUE)

plot(elevation_lspole)

## visualization

elevation_lspole_raster <- aggregate(elevation_lspole, fact = 8, fun = "mean")

elevation_lspole_raster

plot(elevation_lspole_raster)

# table 

elevation_raster_df <- as.data.frame(elevation_lspole_raster, xy = TRUE)

elevation_raster_df <- rename(elevation_raster_df, elevation = LDEM_80S_80MPP_ADJ)

# circle

radius <- 270000

elevation_raster_circle <- filter(elevation_raster_df, sqrt(x^2 + y^2) <= radius)