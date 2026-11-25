library(leaflet)
library(htmlwidgets)
library(htmltools)
library(sf)
library(dplyr)

#I downloaded geopackage from Geofabrik because OSM server was not working
poi <- st_read('input/flevoland.gpkg', layer = 'flevoland__gis_osm_pois_a_free')
parks <- poi[poi$fclass == 'park',] |> 
  mutate(area_m2 = as.numeric(st_area(geom))) |> 
  filter(area_m2>300) |> 
  filter(name != '')
schools <- poi[poi$fclass == 'school', ] |> 
  filter(name!='')

#Set HTML style for text labels
tag.map.labels <- tags$style(HTML("
  .leaflet-control.map-title {
    transform: translate(-50%,20%);
    position: fixed !important;
    left: 50%;
    text-align: center;
    padding-left: 10px; 
    padding-right: 10px; 
    background: rgba(255,255,255,0.75);
    font-weight: bold;
    font-size: 20px;
  }
  
  .leaflet-control.map-info {
    position: absolute !important;
    bottom: 10px;
    left: 30px;
    margin: 0;
    padding: 20px;
    color: white;
    background: transparent;
    font-weight: bold;
    font-size: 12px;
    white-space: nowrap;
  }
"))

title <- tags$div(tag.map.labels , HTML("November 13_Interaction: Lelystad's Fragmented Amenities"))
info <- tags$div(tag.map.labels , HTML("Source:Esri, Geofabrik | Yoonji Kim | #30DayMapChallenge"))

#Assign Rbanism image as html
logo_path <- normalizePath('input/Logo_Rbanism_ Full.png', winslash = "/", mustWork = TRUE)
logo <- htmltools::tags$img(
  src = knitr::image_uri(logo_path),
  style = "width: 20px; height: auto;"
)

#Create legend
legend_colors <- c('park'= 'lightgreen', 'supermarket'= 'magenta', 'school'= 'lightblue')

#Create leaflet object
m <- leaflet() |>
  #Add basemap: default is OSM as "addTiles() |>"
  addProviderTiles('Esri.WorldImagery') |> 
  #Set starting frame
  setView(lng =5.472944658939208 , lat = 52.50800296398498, zoom=13) |> 
  #Add Markers for Large Franchise supermarkets
  addCircleMarkers(lat = 52.51822637792271, lng = 5.460338408855762, popup = 'AH Kempenaar', color = 'magenta', radius = 5, fillOpacity = 0.8) |> 
  addCircleMarkers(lat = 52.51050610578288, lng = 5.474411338392319, popup = 'Jumbo Stadshart', color = 'magenta', radius = 5, fillOpacity = 0.8) |> 
  addCircleMarkers(lat = 52.5207250158018, lng = 5.484855538845013, popup = 'Lidl Oude Passage', color = 'magenta', radius = 5, fillOpacity = 0.8) |> 
  addCircleMarkers(lat = 52.50145688327049, lng = 5.472293374189127, popup = 'Lidl Tjalk', color = 'magenta', radius = 5, fillOpacity = 0.8) |> 
  addCircleMarkers(lat = 52.50207453639035, lng = 5.488975059146251, popup = 'AH Boswijk', color = 'magenta', radius = 5, fillOpacity = 0.8) |> 
  addCircleMarkers(lat = 52.494656580231556, lng  = 5.490536203853735, popup = 'Jumbo Voorstraat', color = 'magenta', radius = 5, fillOpacity = 0.8) |> 
  addPolygons(data = parks, color = 'yellow', fillColor = 'lightgreen', weight = 2, fillOpacity = 0.5, popup = ~name) |> 
  addPolygons(data = schools, color = 'cyan', fillColor = 'lightblue', weight = 1, fillOpacity = 0.7, popup = ~name) |> 
  addControl(html = title, className = 'map-title')  |> 
  addControl(html = info, className = 'map-info', position = 'bottomleft') |> 
  addControl(html = logo, position = 'bottomleft') |> 
  addLegend(position= 'bottomright', colors = c('lightgreen', 'magenta', 'lightblue'), labels = c('park', 'supermarket', 'school'), title = 'Ameneties')

#Check your map
m

#Save as html
saveWidget(widget=m, file = 'Lelystad.html')
