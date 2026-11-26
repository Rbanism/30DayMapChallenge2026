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

# 1 Getting the layers and set same CRS_________________________________________________________
# 1.1 Buildings
tile_center <- st_read("data/10-282-562.gpkg", layer = "pand") |> 
  st_zm() |> 
  st_transform(28992)




st_geometry_type(tile_center)
st_crs(tile_center)

buildings <- select(tile_center, identificatie, oorspronkelijkbouwjaar, status, b3_dak_type, b3_h_nok, b3_h_maaiveld)

#testplot to look at it
p0_test <- ggplot(buildings, 
       aes()
       
       ) +
  geom_sf(linewidth = 0.2, colour = "#5B3A29", fill = "beige") +
  labs(title="6Nov_Vintage: Delft's Historic Urban Landscape",
       subtitle = "A Canvas for HUL-sensitive Climate Adaptation")+
  theme_void()+
  theme(plot.background = element_rect(fill = "black", colour = NA), 
        plot.title = element_text(colour = "white"))

p0_test

st_geometry_type(buildings)

#1.2 streets_________________________________________________________________________________________________________
#and give the streets the same boundary as the building tile

delft_streets <- st_read("data/delft-streets.shp", quiet = TRUE) |>
  st_set_crs(28992) |>
  st_crop(st_bbox(buildings))

st_geometry(delft_streets)
st_crs(delft_streets)

#checking if it worked with the same outline

p2 <- ggplot(delft_streets) + 
  geom_sf(linewidth = 0.7, colour ="pink") + 
  theme_void()

p2 

#1.3 classification_________________________________________________________________________________________________
#now giving the buildings diverse categories depending on building period

head(buildings$oorspronkelijkbouwjaar, 20)
unique(buildings$oorspronkelijkbouwjaar)
filter(buildings, oorspronkelijkbouwjaar < 1700)
sort(unique(buildings$oorspronkelijkbouwjaar))
amount_buildings_peryear <- sort(table(buildings$oorspronkelijkbouwjaar))

amount_buildings_peryear

p3 <-  ggplot(buildings, aes(x = oorspronkelijkbouwjaar))+
  geom_histogram()+
  labs(title = "Amount of Buildings in Delft's Center per Original Construction Year", 
       x = "Original Construction Year", 
       y= "Amount")+
  theme_light()
  
p3

#classification of the buildings: categories of <1536, 1536-1654, 1654-1850, 1850-1945, >1945 
sum(is.na(buildings$oorspronkelijkbouwjaar))

buildings <- buildings |>
  mutate(age_class = case_when(
    oorspronkelijkbouwjaar < 1536 ~ "Before the Great City Fire\n(1200-1536)",
    oorspronkelijkbouwjaar < 1654 ~ "Before the Delftse Donderslag\n(1536-1654)",
    oorspronkelijkbouwjaar < 1850 ~ "Until Industrial Revolution\n(1654-1850)",
    oorspronkelijkbouwjaar < 1945 ~ "Industrial Revolution and War Years\n(1850-1945)",
    TRUE ~ "Post-War until today\n(1945-2026)"
    
  ))

#check whether all the cases are being found
count(buildings |>
        st_drop_geometry() |>
        count(age_class)
      )

class(buildings)

buildings |>
  st_drop_geometry() |>
  count(age_class)

#create levels so we can later on colour them according to chronological time order
buildings <- buildings |>
 mutate(age_class = factor(age_class, 
        levels = c("Before the Great City Fire\n(1200-1536)", 
                   "Before the Delftse Donderslag\n(1536-1654)",
                   "Until Industrial Revolution\n(1654-1850)",
                   "Industrial Revolution and War Years\n(1850-1945)",
                   "Post-War until today\n(1945-2026)"))
        )
         
#check whether they are in chronological order
buildings |>
        st_drop_geometry() |>
        count(age_class)

#colour differentiation for plot 1

p1 <- ggplot(buildings, 
             aes()
             ) +
  geom_sf(linewidth = 0.2, colour = "#5B3A29", aes(fill = age_class)) +
  scale_fill_manual(values = c("#F3E3B8",
                               "#D9B77A", 
                               "#B38450", 
                               "#7A5232", 
                               "#4A3222"))+
  labs(title="6Nov_Vintage: Delft Vintage Core",
       subtitle = "Est. 1200", fill = "Construction Period")+
  theme_void()+
  theme(plot.background = element_rect(fill = "black", 
                                       colour = NA), 
        plot.title = element_text(colour = "white"), 
        plot.subtitle = element_text(colour = "white"),
        legend.title = element_text(colour = "white"),
        legend.text = element_text(colour = "white")
        )

p1

#1.4 canals______________________________________________________________________________________________
#adding the historic canals
#install.packages("osmdata")
#library(osmdata)

#bounding box of the buildings tile in WGS84 (EPSG:4326), needed for the OSM downloads
#bbox_wgs <- st_bbox(st_transform(buildings, 4326))

#OSM downloads
water_osm <- opq("Delft, Netherlands")|>
  add_osm_feature(key = "natural", value = "water")

water_data <- osmdata_sf(water_osm)
water_data

#I don't need everything of water_data, so only (multi-) polygones needed
water_poly <- select(water_data$osm_polygons, name)
water_multipoly <- select(water_data$osm_multipolygons, name)

#make them both one table aka bind the rows together and only create the canals within the desired boundary
canals <- bind_rows(water_poly, water_multipoly) |>
  st_transform(28992) |>
  st_crop(st_bbox(buildings))



#check with the plot
p4 <- ggplot(canals) + 
  geom_sf(fill = "#4F6D7A", colour = NA) + 
  theme_void()

p4

#2 Map__________________________________________________________________________________________________________________
#rebuilding p1 and adding a legend for the landscape feature water and fonts

font_add_google("Bodoni Moda", "bodoni")
showtext_auto()
showtext_opts(dpi = 300)

p1 <- ggplot() +
  geom_sf(data = canals,
          aes(colour = "Historic Canal Grid"),
          fill = "#3A4C52"
          )  +
  
  geom_sf(data = delft_streets, 
          linewidth = 0.5, 
          colour = "black") +
  
  geom_sf(data = buildings,
          aes(fill = age_class),
          linewidth = 0.2, 
          colour = "#5B3A29") +
  
  scale_fill_manual(values = c("#F3E3B8",
                               "#D9B77A", 
                               "#B38450", 
                               "#7A5232", 
                               "#4A3222"))+
  scale_colour_manual(values = "#3A4C52")+
                    
  
  labs(title="   Delft Vintage Core - Est. 1200",
       subtitle = "    6Nov_Vintage: Regina Klinger", 
       fill = "Construction Period", 
       colour = "Landscape",
       caption = "   Data: 3DBAG, © OpenStreetMap contributors, Geospatial Data Carpentry for Urbanism TU Delft, Dr. D. Cannatella\n\n   #30DayMapChallenge\n\n")+
  
  theme_void()+
  
  theme(plot.background = element_rect(fill = "black", colour = NA), 
        plot.title = element_text(family = "bodoni", colour = "white"), 
        plot.subtitle = element_text(colour = "white"),
        legend.title = element_text(colour = "white"),
        legend.text = element_text(colour = "white"),
        plot.caption = element_text(colour = "white", hjust = 0),
        text = element_text(family = "bodoni")
  )

p1



#3 Logo and Export________________________________________________________________________________________________________
#bring in the logo
rbanism_logo <- image_read("data/Logo_Rbanism_ White.png")

#put logo on plot
p1_logo <- ggdraw(p1) + 
  draw_image(rbanism_logo, 
             x = 0.74, 
             y = 0.23, 
             width = 0.1, 
             height = 0.1)
p1_logo



ggsave("map.png", p1_logo,
       width = 10, height = 8.5, bg="black", dpi = 300)

ggsave("map_png/6Nov_Vintage.png", p1_logo,
       width = 10, height = 8.5, bg="black", dpi = 300)


#5 Store Data
st_write(canals, "data/canals.gpkg", delete_dsn = TRUE)




