library(sf)
library(tidyverse)
library(here)
library(cowplot)
library(magick)
library(osrm)
library(ggtext)

boundaries <-st_read(here('data','boundary.gpkg'))
streets<-st_read(here('data','streets.gpkg'))
toilets <- st_read(here('data', 'public toilets.gpkg'))

isochr <- map(1:nrow(toilets),function(i){
  message("Punctul ", i, " din ", nrow(toilets))
  Sys.sleep(1)
    osrmIsochrone(loc= toilets[i,],
                breaks= c(0,10),
                osrm.profile='foot',
                res=15)
}) |>
  bind_rows()

st_write(isochr, here("data", "isochrones_10min.gpkg"))

final_map <- ggplot () +
  geom_sf (data = boundaries, 
           fill= NA, 
           colour= 'white',
           linewidth= 1) +
  geom_sf(data= streets,
          linewidth=0.1,
          color='white') +
  geom_sf(data= isochr,
          aes(fill='10 minutes walking isochrone'),
          alpha=0.75,
          color=NA)+
  geom_sf(data= toilets,
          aes(color='Public toilets'),
          size= 1, 
          show.legend = 'point',
          stroke= 0.2)+
  scale_fill_manual(values=c('10 minutes walking isochrone'='pink'),
                    name=NULL)+
  scale_color_manual(values=c('Public toilets'='purple'),
                     name=NULL)+
  labs(title = 'ACCESSIBILITY TO PUBLIC TOILETS',
       subtitle = 'Public toilets in Bucharest within a 10-minute walk<br><span style="color:#999999"><i>#30DayMapChallenge | DAY 7: 10 MINUTE MAP</i></span>',
       caption= 'Author: Andreea Voineag, 2026\nSource: OSM')+
  theme_void() +
  theme(plot.background = element_rect(fill='black',color=NA),
        text= element_text(color='white'),
        legend.text=element_text(size=6),
        plot.title=element_text(face='bold',
                                margin=margin(l=20,b=5)),
        plot.subtitle=element_markdown(size= 8,margin=margin(l=20, b=10)),
        plot.caption=element_text(hjust=0, size=7,
                                  margin= margin (l=20)),
        legend.position='right',
        plot.margin=margin(15,15,15))

ggdraw(final_map) +
  draw_image(here('data', 'Logo_Rbanism_ White.png'),
                  x=0.8,y=0.05,
                  width= 0.15, height=0.15)

