library(sf); library(ggplot2); library(ggrepel)

g <- read.csv("data/ai_guesses.csv")
if (!file.exists("data/real.csv")) {
  q <- sprintf('SELECT ?city ?lat ?lon WHERE { VALUES ?city { %s } ?item rdfs:label ?city; wdt:P17 wd:Q55; wdt:P31/wdt:P279* wd:Q515; p:P625/psv:P625 [wikibase:geoLatitude ?lat; wikibase:geoLongitude ?lon] FILTER NOT EXISTS { ?item wdt:P576 [] } }',
               paste0('"', g$city, '"@nl', collapse = " "))
  r <- httr::GET("https://query.wikidata.org/sparql", query = list(query = q), httr::accept("text/csv"), httr::user_agent("rbanism-30daymap"))
  x <- read.csv(text = httr::content(r, "text", encoding = "UTF-8"))
  write.csv(x[!duplicated(x$city), ], "data/real.csv", row.names = FALSE)
}
if (!file.exists("data/nl.gpkg")) {
  st_write(st_union(st_read("https://service.pdok.nl/cbs/gebiedsindelingen/2025/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeNames=provincie_gegeneraliseerd&outputFormat=json")),
           "data/nl.gpkg", layer_options = "SPATIAL_INDEX=NO")
}
nl <- st_read("data/nl.gpkg")
real <- read.csv("data/real.csv")
d <- merge(g, real, by = "city", suffixes = c("_g", "_r"))
gp <- st_as_sf(d, coords = c("lon_g", "lat_g"), crs = 4326)
rp <- st_as_sf(d, coords = c("lon_r", "lat_r"), crs = 4326)
d$km <- as.numeric(st_distance(gp, rp, by_element = TRUE)) / 1000
err <- mean(d$km)
stopifnot(nrow(d) == 25, err < 10)

xy_g <- st_coordinates(st_transform(gp, 28992)); xy_r <- st_coordinates(st_transform(rp, 28992))
d$x <- xy_r[, 1]; d$y <- xy_r[, 2]
d$x0 <- xy_r[, 1] + 25 * (xy_g[, 1] - xy_r[, 1]); d$y0 <- xy_r[, 2] + 25 * (xy_g[, 2] - xy_r[, 2])
worst <- d[which.max(d$km), ]
logo <- png::readPNG("data/Logo_Rbanism_ Full.png")

p <- ggplot(d) +
  geom_sf(data = nl, fill = "#e9e4ef", colour = "#b9a9c9", linewidth = 0.3) +
  geom_segment(data = d[d$km > 0.05, ], aes(x0, y0, xend = x, yend = y), colour = "#93278F", linewidth = 0.6, arrow = arrow(length = unit(1.6, "mm"), type = "closed")) +
  geom_point(aes(x0, y0), colour = "#F7931E", size = 1.6) +
  geom_point(aes(x, y), colour = "#00A99D", size = 1.6) +
  geom_text_repel(aes(x, y, label = sprintf("%s %.1f km", city, km)), size = 2.6, bg.colour = "white", bg.r = 0.12,
                  min.segment.length = 0.2, segment.size = 0.2, box.padding = 0.4, seed = 1) +
  annotation_custom(grid::rasterGrob(logo, x = 0.02, y = 0.98, hjust = 0, vjust = 1, height = unit(0.1, "npc"))) +
  coord_sf(crs = 28992, datum = NA) +
  labs(title = "10Nov_PromptingOnly: How AI sees\nthe Netherlands",
       subtitle = sprintf("An AI (GitHub Copilot) guessed the lat/lon of 25 Dutch cities from memory.\nMean error: %.1f km. Worst: %s (%.1f km). Arrows run from the guess (orange)\nto the real location (teal) and are drawn 25\u00d7 longer than they are.",
                         err, worst$city, worst$km),
       caption = "Guesses by AI; real coordinates from Wikidata (CC0); outline from CBS/PDOK.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026.") +
  theme_void() +
  theme(plot.title = element_text(size = 17, face = "bold"), plot.subtitle = element_text(size = 9.5),
        plot.caption = element_text(size = 6.5, hjust = 0.5), plot.margin = margin(15, 15, 10, 15))

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "white")
