#Install packages and load libraries
#run this line only once, then put a # in front of it
#install.packages(c("sf", "ggplot2", "tidyr", "readxl", "ggrepel", "gridExtra", "rnaturalearth", "rnaturalearthdata"))

library(sf)
library(ggplot2)
library(rnaturalearth)
library(rnaturalearthdata)
library(readxl)
library(tidyr)
library(ggrepel)
library(gridExtra)
library(png)
library(grid)

#read excel file and define x and y coordinates
distances <- read_excel("data/Distance of Tastes (Filled).xlsx", sheet = "Answers", skip = 1)

#remove the empty rows and the total/average rows at the bottom
distances <- distances[!is.na(distances$a_coords), ]

#split the coordinates into latitude and longitude
distances <- separate(distances, a_coords, c("a_lat", "a_lon"), sep = ",", convert = TRUE)
distances <- separate(distances, b_coords, c("b_lat", "b_lon"), sep = ",", convert = TRUE)

#categorize the questions and answers "experienced and drawn"
distances$category <- c("Experienced", "Experienced", "Drawn to", "Drawn to", "Drawn to",
                        "Experienced", "Experienced", "Experienced", "Experienced",
                        "Drawn to", "Drawn to", "Drawn to", "Drawn to", "Drawn to", "Drawn to")

#calculate the distance between our answers in km
points_a <- st_as_sf(distances, coords = c("a_lon", "a_lat"), crs = 4326)
points_b <- st_as_sf(distances, coords = c("b_lon", "b_lat"), crs = 4326)
distances$km <- round(as.numeric(st_distance(points_a, points_b, by_element = TRUE)) / 1000)

#answers closer than 2000 km are "Close", the others are "Far"
distances$closeness <- ifelse(distances$km < 2000, "Close (under 2000 km)", "Far")

#find the middle point of each curve (midpoint from a straight line pushed sideways), the label goes there
curv <- 0.15
distances$mid_lon <- (distances$a_lon + distances$b_lon) / 2 + 0.5 * curv * (distances$b_lat - distances$a_lat)
distances$mid_lat <- (distances$a_lat + distances$b_lat) / 2 - 0.5 * curv * (distances$b_lon - distances$a_lon)

#give each question a number, the number goes on the line
#the table under the map explains what each number means
distances$no <- 1:nrow(distances)

#load rbanism logo
logo <- rasterGrob(readPNG("data/Logo_CL.png"), interpolate = TRUE)

#load the world map
world <- ne_countries(scale = "medium", returnclass = "sf")

#draw the map, layer by layer
map <- ggplot() +
  
  #layer 1: world map in the background (grey countries, white borders)
  geom_sf(data = world, fill = "grey90", color = "white") +
  
  #layer 2: one line for each question, from answer A to answer B
  #the color shows the category (Experienced or Drawn to)
  #the line type shows closeness (dashed = close, solid = far)
  geom_curve(data = distances,
               aes(x = a_lon, y = a_lat, xend = b_lon, yend = b_lat,
                   color = category, linetype = closeness),
               curvature = curv, linewidth = 0.9) +
  
  #layer 3: a small number in the middle of each line (see the table for the question)
  geom_label_repel(data = distances,
                   aes(x = mid_lon, y = mid_lat, label = paste0(no, ": ", km, " km"), color = category),
                   size = 3.5, fill = "white", label.padding = 0.15,
                   box.padding = 0.2, max.overlaps = Inf,
                   show.legend = FALSE, seed = 1) +
  
  #layer 4: circles = the places of person A (drawn last so they stay on top)
  geom_point(data = distances, aes(x = a_lon, y = a_lat, shape = "A"),
             size = 4, fill = "black", color = "white", stroke = 0.8) +
  
  #layer 5: triangles = the places of person B (drawn last so they stay on top)
  geom_point(data = distances, aes(x = b_lon, y = b_lat, shape = "B"),
             size = 4, fill = "black", color = "white", stroke = 0.8) +
  
  #rbanism logo in the bottom right corner
  annotation_custom(logo, xmin = 126, xmax = 142, ymin = -34, ymax = -18) +
  
  #line colors: orange = Experienced, green = Drawn to
  scale_color_manual(values = c("Experienced" = "#d95f02", "Drawn to" = "#1b9e77")) +
  
  #point shapes: 21 = circle (A), 24 = triangle (B)
  scale_shape_manual(values = c("A" = 21, "B" = 24)) +
  
  #line types: dashed = close, solid = far
  scale_linetype_manual(values = c("Close (under 2000 km)" = "dashed", "Far" = "solid")) +
  
  #zoom to the part of the world we use
  coord_sf(xlim = c(-80, 145), ylim = c(-35, 65)) +
  
  #title and the names of the legends
  labs(title = "16Nov_Collaborative: Distances of Tastes",
       subtitle = "How Far Apart Are Two Architects Everyday Life and Their Inspirations\n#30DayMapChallenge",
       caption = "Authors: Elifnaz Kancan & Zulfa Nur Fadhila, 2026\nSources: Questionnaire (Google Sheet), Natural Earth",
       color = "Line color = category",
       shape = "Point shape = person",
       linetype = "Line type = closeness") +
  
  #clean background and legend at the bottom
  theme_void() +
  theme(legend.position = "bottom",
        legend.box = "vertical",
        plot.title = element_text(size = 20, face = "bold"),
        plot.caption = element_text(size = 9, hjust = 0, color = "grey30"))

#make the table that goes under the map
table_data <- data.frame(
  No = distances$no,
  Question = distances$question,
  A = distances$a_place,
  B = distances$b_place,
  Category = distances$category,
  Km = distances$km
)
table <- tableGrob(table_data, rows = NULL, theme = ttheme_minimal(base_size = 9))

#put the map on top and the table under it
final <- arrangeGrob(map, table, ncol = 1, heights = c(3, 2))

#show it in the Plots panel
grid.arrange(final)

#save it as a big png file (it appears in the Files panel)
ggsave("distances_of_two_tastes.png", final, width = 14, height = 12, dpi = 300, bg = "white")
