install.packages("tidyverse")
install.packages("sf")
install.packages("rnaturalearth")
install.packages("cowplot")

library(tidyverse)
library(sf)
library(rnaturalearth)

### Data (retrieved on November 9th, countries of institution, date and research name extracted with Copilot)
# Archives of Nobel IG : https://improbable.com/ig/winners/
### Logo
# Rbanism Logo available at : https://github.com/Rbanism/30DayMapChallenge2026/tree/main/resources/logo

### DATA PREPARATION
compiled_ig <- read.csv(file = "data/Ig_Nobel_categories.csv", header = TRUE)
simplified_data <- compiled_ig |>
  mutate(
    from = pmin(Country, `Collaborative.country`),
    to   = pmax(Country, `Collaborative.country`)) |>
  select(Year, `Award.category`, from, to, `Official.prize.description`) |>
  distinct()

write_csv(simplified_data, "Ig_Nobel_simple.csv")

###  WORLD MAP PREP, and PICKING ONE REPRESENTATIVE LOCATION PER COUNTRY
world <- ne_countries(scale = "small", returnclass = "sf") |>
  mutate(country = recode(
    admin))
locations <- world |>
  st_drop_geometry() |>
  transmute(country, longitude = label_x, 
            latitude = label_y)

### CONNECTIONS (based on shared prizes), AND COUNTRY COORDINATES
links <- simplified_data |>
  filter(from != to) |>
  count(from, to, name = "shared_prizes") |>
  left_join(locations, by = c("from" = "country")) |>
  left_join(
    locations,
    by = c("to" = "country"),
    suffix = c("_from", "_to")
  )
setdiff(
  unique(c(simplified_data$from, simplified_data$to)),
  locations$country)

### PREP PLOT
map_plot <- ggplot() +
    geom_sf(
      data = world,
      fill = "#ccbdb0",
      colour = "#f2efec",
      linewidth = 0.3
    ) +
    geom_curve(
      data = links,
      aes(
        x = longitude_from,
        y = latitude_from,
        xend = longitude_to,
        yend = latitude_to,
        linewidth = shared_prizes
      ),
      curvature = 0.2,
      colour = "#05626d",
      alpha = 0.3,
      na.rm = TRUE
    ) +
    scale_linewidth(
      range = c(0.2, 2),
      breaks = c(1, 5, 10, 20),
      name = "Shared prizes"
    ) +
    guides(
      linewidth = guide_legend(
        override.aes = list(alpha = 1)
      )
    ) +
    coord_sf(crs = st_crs(4326)) +
    theme_void() +
    theme(
      panel.background = element_rect(fill = "#f2efec", colour = NA),
      plot.background = element_rect(fill = "#f2efec", colour = NA),
      legend.background = element_rect(fill = "#f2efec", colour = NA),
      legend.position = "bottom",
      plot.title = element_text( family = "American Typewriter",
        size = 22, face = "bold", colour = "#05626d"
      ),
      plot.subtitle = element_text(family =  "American Typewriter", size = 12, face = "italic"),
      plot.caption = element_text( family = "American Typewriter", size = 10, face = "bold", colour = "#ccbdb0"),
      plot.margin = margin(20, 20, 20, 20)
    ) +
    labs(
      title = "Far-fetched & Ignoble",
      subtitle = "Countries jointly represented in Ig Nobel Prize entries",
      caption = "#30DayMapChallenge | Day 16 Collaboration | Data from improbable.com
      Inès Daugerel (Urbanism) & Michael Tellier (Biomedical)"
    )
  
map_plot

### FORMATTING FOR RBANISM POST ( with square size and with the logo)
logo <- png::readPNG("data/Logo_Rbanism_ Blue.png")
final_plot <- cowplot::ggdraw() + # colouring the WHOLE square, to include the space around the map
    cowplot::draw_grob(
      grid::rectGrob(
        gp = grid::gpar(fill = "#f2efec", col = NA)
      )) + # Add the map
    cowplot::draw_plot(map_plot) + # Place the logo in the top-right corner
    cowplot::draw_grob(
      grid::rasterGrob(logo),
      x = 0.84, y = 0.80,
      width = 0.12, height = 0.12
    )
final_plot

### SQUARE SAVE
ggsave(
    "Ig_Nobel_collaboration.png",
    plot = final_plot,
    width = 20, height = 20,
    units = "cm", dpi = 300,
    bg = "#f2efec"
  )

  