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

