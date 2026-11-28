library(sf); library(terra); library(ggplot2)

f <- "data/nobody.tif"
if (!file.exists(f)) {
  cache <- "C:/personal/SA-rbanism/cache/"
  gpkg <- paste0(cache, "vk100_2025/cbs_vk100_2025_v1.gpkg")
  if (!file.exists(gpkg)) {
    download.file("https://download.cbs.nl/vierkant/100/2026-cbs_vk100_2025_v1.zip", paste0(cache, "vk100.zip"), mode = "wb")
    unzip(paste0(cache, "vk100.zip"), exdir = paste0(cache, "vk100_2025"))
  }
  gj <- paste0(cache, "wb_gem.json")
  if (!file.exists(gj)) download.file("https://service.pdok.nl/cbs/wijkenbuurten/2024/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeNames=gemeenten&outputFormat=json&propertyName=gemeentecode,water,geom", gj, mode = "wb")
  land <- st_read(gj, quiet = TRUE) |> subset(water == "NEE")
  # land cells: 100 m grid aligned to the CBS grid, cell centre on land
  r <- rasterize(vect(land), rast(ext(0, 300000, 300000, 625000), res = 100, crs = "EPSG:28992"), field = 1)
  # every cell in the CBS file has residents (>= 5, or -99997 = 1-4, secret); empty cells are simply absent
  id <- st_read(gpkg, query = "SELECT crs28992res100m AS id FROM cbs_vk100_2025", quiet = TRUE)$id
  r[cellFromXY(r, cbind(as.numeric(substr(id, 2, 5)) * 100 + 50, as.numeric(substr(id, 7, 10)) * 100 + 50))] <- 2
  writeRaster(r, f, datatype = "INT1U", gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
}
r <- rast(f)
n <- freq(r)$count
pct <- 100 * n[1] / sum(n)
stopifnot(pct > 50, pct < 95)

m <- matrix(ifelse(values(r) == 1, "#93278F", NA), nrow(r), byrow = TRUE)
e <- as.vector(ext(r))
logo <- png::readPNG("data/Logo_Rbanism_ Full.png")

p <- ggplot() +
  annotation_raster(m, e[1], e[2], e[3], e[4], interpolate = FALSE) +
  geom_point(aes(x = c(e[1], e[2]), y = c(e[3], e[4])), alpha = 0) +
  annotation_custom(grid::rasterGrob(logo, x = 1, y = 1.01, hjust = 1, vjust = 0, height = unit(0.1, "npc"))) +
  coord_sf(crs = 28992, datum = NA, expand = FALSE, clip = "off") +
  labs(title = "18Nov_NULL: Nobody lives here",
       subtitle = sprintf("%.0f%% of Dutch land has no registered resident (100 m cells, 2025).\nPurple = zero people; white = somebody lives there.", pct),
       caption = "Data from CBS Vierkantstatistieken 100 m (2025) and the CBS/PDOK Wijk- en buurtkaart 2024.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026.") +
  theme_void() +
  theme(plot.title = element_text(size = 17, face = "bold"), plot.subtitle = element_text(size = 10),
        plot.caption = element_text(size = 6.5, hjust = 0.5), plot.margin = margin(15, 15, 10, 15))

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "white")
