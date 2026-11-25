## --------------------------------------------
#ALL PACKAGES

# define packages to be used
cran_packages <- c("tidyverse", "sf", "pak", "sysfonts", "showtext", "osmdata", "magick", "grid")

# loading packages and checking if packages are installed
load_packages <- function(pkgs) {
  #check for missing packages
  missing_package <- pkgs[!(pkgs %in% installed.packages()[, "Package"])]
  
  #install missing packages
  if (length(missing_package)) {install.packages(missing_package)}
  
  #load all packages
  lapply(pkgs, library, character.only = TRUE)
}

# load the packages
load_packages (cran_packages)


# Print a message to confirm successful loading
cat("All packages have been loaded successfully!\n")


# Download Rbanism logo
library(magick)

rbanism_logo <- image_read('../rbanismlogo.png')


#MAKING THE MAP

# Getting the cycle network of Rotterdam

cyclestreets <- opq("Rotterdam, Netherlands") |> 
  add_osm_feature(key = "highway",
                  value = c("cycleway", "path", "residential", "living street"))|>
  osmdata_sf()
cycle_network <- cyclestreets$osm_lines
cycle_network <- st_transform(cycle_network, 28992)



#PREPARING THE PLOT

#plotbase
p <- ggplot() + 
  geom_sf(data = cycle_network, linewidth = 0.1, color = "black")+
  scale_linewidth_continuous(name = "Bicycle streets:", range = c(0.1, 0.2))+xlim(85258.73,101333.89)+ylim(429211.77,446353.34)+coord_sf(datum=st_crs(28992))

#add custom fonts
font_add_google("roboto","Roboto" )
showtext.auto()


#PLOTTING THE MAP

p_styled <- p + theme_void() + theme(
  plot.background = element_rect(fill = "#f4f4f4", color = NA),
  panel.background = element_rect(fill = "#f4f4f4", color = NA),
  plot.margin = margin(10, 90, 10, 90),
  legend.position = "bottom",
  legend.box = "horizontal",
  legend.title = element_text(size = 10,
                              family = "roboto",
                              color = "black"),
  legend.text = element_text (size = 10, 
                              family = "roboto",
                              color = "black"),
  plot.title = element_text( size = 25,
                             face = "bold",
                             family = "roboto",
                             color = "black"),
  
  plot.subtitle = element_text(size = 12,
                                family = "roboto",
                                color = "black"),
  plot.caption = element_text(size = 8,
                              family = "roboto",
                              color = "black",
                              hjust = 0,
                              lineheight = 0.4),
  legend.key.height = unit (1, "cm"),
  legend.key.width = unit(1, "cm"),
) +
  labs (title = "Bicycle Network of Rotterdam",
       subtitle = "connectivity and layout of bicycle streets in Rotterdam",
       caption = "#30DayMapChallenge\nDescription: The map shows the bicycle network of Rotterdam.\nData: OpenstreetMap\nAuthor: Alankrita Sharma"
  )

p_styled

p_styled <- cowplot::ggdraw(p_styled) + cowplot::draw_image(rbanism_logo, x=0, y=0, width = 0.1,height = 0.1, hjust = 0, vjust = 0) 
  
  
 #EXPORTING THE MAP
output_map <- "Output/02Nov_BicycleStreets.png"

ggsave(filename = output_map, plot = p_styled, device = "png",
       width = 6, height = 6, dpi = 300)

#message to confirm export
cat("map has been exported as", output_map, "with a 1:1 aspect ratio.\n")


  
  




