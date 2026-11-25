# 0 Setup

#install.packages(c("tidyverse", "sf", "osmdata", "ggplot2", "magick", "cowplot"))
#install.packages("showtext")

# library() lines, file paths as objects

library(sf)
library(osmdata)
library(tidyverse)
library(ggplot2)
library(magick)
library(cowplot)
library(showtext)

#1 Data___________________________________________________________________________________________________
#Using again the tile of Delft city center as the base, first getting the tile:

tile_center <- st_read("C:/Github/30DayMapChallenge/15Nov_InsideOut/data/10-282-562.gpkg", layer = "pand") |>
  st_zm()|>
  st_transform(28992)

st_geometry_type(tile_center)

#checking the crs
st_crs(tile_center)

#now getting the buildings
buildings <- select(tile_center, identificatie, oorspronkelijkbouwjaar, status, b3_dak_type, b3_h_nok, b3_h_maaiveld)

#getting the canals
canals <- st_read("C:/Github/30DayMapChallenge/15Nov_InsideOut/data/canals.gpkg")

st_geometry_type(canals)

#getting the trees
#OSM download
#bounding box of the tile in WGS84 for the OSM query

# bbox_wgs <- st_bbox(st_transform(buildings, 4326))

# trees_osm <- opq(bbox_wgs) |>
#   add_osm_feature(key = "natural", value = "tree")
 
# trees_data <- osmdata_sf(trees_osm)
 
# nrow(trees_data$osm_points)
 
# trees <- select(trees_data$osm_points) |>
#   st_transform(28992) |>
#   st_crop(st_bbox(buildings))
 
# st_write(trees, "C:/Github/30DayMapChallenge/15Nov_InsideOut/data/trees.gpkg")

trees <- st_read("C:/Github/30DayMapChallenge/15Nov_InsideOut/data/trees.gpkg")



#testplot

ggplot() +
  geom_sf(data = buildings,colour = "#9DB17C", fill = "#9DB17C") +
  geom_sf(data = trees, colour = "#1A1A1A") +
  coord_sf(datum = st_crs(28992)) +
  theme_light()

#2 Courtyards______________________________________________________________________________________________
#create a tile where I can cutout the builings to leave the non-built environment
tile <- st_as_sfc(st_bbox(buildings))  
 

#merging the buildings
buildings_closed <- buildings|>
  st_buffer(2) |>
  st_union() |>
  st_buffer(-2)

  


ggplot() +
  geom_sf(data = tile, colour = "grey", fill = "grey") +
  geom_sf(data = buildings_closed, colour = "#9DB17C", fill = "#9DB17C" ) +
  geom_sf(data = trees, colour = "#1A1A1A")+
  coord_sf(datum = st_crs(28992)) +
  theme_light()



#now cut out the buildings to create the open spaces multipolygone

open_space <- st_difference(tile, buildings_closed)
plot(open_space)


ggplot() +
  geom_sf(data = open_space, fill = "#1A1A1A", colour = NA)+
  geom_sf(data = buildings_closed, colour = "#9DB17C", fill = "#9DB17C" ) +
  geom_sf(data = trees, colour = "green")+
  coord_sf(datum = st_crs(28992)) +
  theme_light()

#separate the multipolygone into smaller pieces
open_space <- open_space |>
  st_cast("POLYGON") |>
  st_as_sf()

nrow(open_space)
names(open_space)


open_space <- open_space |>
  mutate(area = st_area(x))


sort(unique(open_space$area))

courtyards <- open_space |>
  filter(area < max(area))

nrow(courtyards)

#3 Map________________________________________________________________________________________________________
#plot the map
font_add_google("Space Grotesk", "grotesk")
showtext_auto()
showtext_opts(dpi = 300)

p1 <- ggplot()+
  geom_sf(data = tile,
          aes(fill = "Streets and Squares"), colour = NA)+
  geom_sf(data = courtyards,
          aes(fill = "Courtyards"), colour = NA)+         
  geom_sf(data = buildings,
          aes(fill = "Buildings"), colour = NA)+
  geom_sf(data = canals, 
          aes(fill = "Canals"), colour = NA)+
  geom_sf(data = trees,
          aes(colour = "Trees"), size = 1.7)+
  coord_sf(datum = 28992)+
  
  scale_fill_manual(values = c("Streets and Squares" = "#3A4640",
                               "Courtyards" = "#7A9E6E",
                               "Buildings" = "black",
                              "Canals" = "#1F271A"
                               ))+
  scale_colour_manual(values = c("Trees" = "#2B3428"))+
  
  labs(title="   15Nov_InsideOut: Delft’s Hidden Courtyards",
       subtitle = "    by Regina Klinger", 
       fill = "Urban Landscape Features", 
       colour = "Vegetation",
       caption = "   Data: 3DBAG, © OpenStreetMap contributors, Geospatial Data Carpentry for Urbanism TU Delft, Dr. D. Cannatella\n\n   #30DayMapChallenge\n\n")+
  
  theme_void()+
  
  theme(plot.background = element_rect(fill = "black", colour = NA), 
        plot.title = element_text(family = "grotesk", colour = "white"), 
        plot.subtitle = element_text(colour = "white"),
        legend.title = element_text(colour = "white"),
        legend.text = element_text(colour = "white"),
        plot.caption = element_text(colour = "white", hjust = 0),
        text = element_text(family = "grotesk"))

p1



#4 Logo and Export________________________________________________________________________________________________________
#bring in the logo
rbanism_logo <- image_read("C:/Github/30DayMapChallenge/15Nov_InsideOut/data/Logo_Rbanism_ White.png")

#put logo on plot
p1_logo <- ggdraw(p1) + 
  draw_image(rbanism_logo, 
             x = 0.77,
             y = 0.29, 
             width = 0.1, 
             height = 0.1)
p1_logo


#save

ggsave("C:/Github/30DayMapChallenge/15Nov_InsideOut/map_png/15Nov_InsideOut_ReginaKlinger.png", p1_logo,
       width = 10, height = 8.5, bg="black", dpi = 300)
