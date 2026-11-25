library(pak)
library(sf)
library(sysfonts)
library(showtext)
library(magick)
library(grid)
library(ggplot2)
library(patchwork)
library(rnaturalearth)
library(cowplot)


#load world map
wmap <- ne_countries(scale="medium", returnclass = "sf")

#define projection
northpole_crs <- st_crs("+proj=laea +lat_0=90 +lon_0=0 +datum=WGS84 +units=m +no_defs")

#transform world map
wmap_laea <- st_transform (wmap, crs=northpole_crs)

#generate latitude and longitude grid lines
lgrid <- st_graticule(ndiscr=50)
lgrid_northpole <- st_transform (lgrid, crs = northpole_crs)

#download rbanism logo
rbanism_logo <- image_read('https://rbanism.org/assets/imgs/about/vi_l.jpg')
logo <- rasterGrob(as.raster(rbanism_logo), interpolate = TRUE)

#plotting the map
p <- ggplot() +
  geom_sf(data =  lgrid_northpole, color = "#dcdcdc", alpha = 0.8, size = 0.2) +
  geom_sf(data = wmap_laea, fill = "#cbcbcb", color = "#7f7f7f", size = 0.2) 

#add custom fonts
font_add_google("roboto","Roboto" )
showtext.auto()

#plot
p_styled <- p + theme_void() + 
  theme(
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    plot.title = element_text( size = 22,
                               face = "bold",
                               family = "roboto",
                               color = "black"),
    plot.caption = element_text(size = 12,
                                family = "roboto",
                                color = "black",
                                hjust = 0,
                                lineheight = 0.4)
  ) +
  labs (title = "Day 22: Projections \nWorld Map in Lambert Azimuthal Equal-Area Projection",
        caption = "\n#30DayMapChallenge. \n\nData: 'rnaturalearth.'\n\nAlankrita Sharma, 2026"
  )



p_styled_logo <- ggdraw(p_styled) + draw_grob(logo, x=0.85, y=0.85, width = 0.15, height = 0.15) 


p_styled_logo

#exporting the map
ggsave("22Nov_Projections.png", plot = p_styled_logo, width = 6, height = 6, dpi = 300, bg = "white")
