library(sf); library(terra); library(dbscan); library(ggplot2)

f <- "data/inwoners.tif"
if (!file.exists(f)) {
  cache <- "C:/personal/SA-rbanism/cache/"
  gpkg <- paste0(cache, "vk100_2025/cbs_vk100_2025_v1.gpkg")
  if (!file.exists(gpkg)) {
    download.file("https://download.cbs.nl/vierkant/100/2026-cbs_vk100_2025_v1.zip", paste0(cache, "vk100.zip"), mode = "wb")
    unzip(paste0(cache, "vk100.zip"), exdir = paste0(cache, "vk100_2025"))
  }
  d <- st_read(gpkg, query = "SELECT crs28992res100m AS id, aantal_inwoners AS p FROM cbs_vk100_2025", quiet = TRUE)
  r <- rast(ext(0, 300000, 300000, 625000), res = 100, crs = "EPSG:28992")
  # -99997 = secret (1-4 residents): stored as 2
  i <- cellFromXY(r, cbind(as.numeric(substr(d$id, 2, 5)) * 100 + 50, as.numeric(substr(d$id, 7, 10)) * 100 + 50))
  r[i[!is.na(i)]] <- pmax(d$p, 2)[!is.na(i)]
  writeRaster(r, f, datatype = "INT2U", gdal = "COMPRESS=DEFLATE", overwrite = TRUE)
}
r <- rast(f)
cells <- which(!is.na(values(r)))
xy <- xyFromCell(r, cells)
pop <- values(r)[cells]

cl <- dbscan(xy, eps = 300, minPts = 5)$cluster
size <- tapply(pop[cl > 0], cl[cl > 0], sum)
big <- as.integer(names(which.max(size)))
n <- length(size)
stopifnot(n > 1000, n < 20000)

set.seed(30)
pal <- hcl(runif(n, 140, 330), 55, 60)
col <- ifelse(cl == 0, "#3a3a3a", ifelse(cl == big, "#F7931E", pal[pmax(cl, 1)]))
m <- matrix(NA_character_, nrow(r), ncol(r))
rc <- rowColFromCell(r, cells)
m[rc] <- col
e <- as.vector(ext(r))
c_big <- colMeans(xy[cl == big, ])
logo <- png::readPNG("data/Logo_Rbanism_ White.png")

p <- ggplot() +
  annotation_raster(m, e[1], e[2], e[3], e[4], interpolate = FALSE) +
  geom_point(aes(x = c(e[1], e[2]), y = c(e[3], e[4])), alpha = 0) +
  annotate("text", x = c_big[1] - 28000, y = c_big[2] + 22000, hjust = 1, colour = "#F7931E", size = 3.2, fontface = "bold",
           label = sprintf("Den Haag-Rotterdam\n%.1f million people", max(size) / 1e6)) +
  annotation_custom(grid::rasterGrob(logo, x = 0.98, y = 0.02, hjust = 1, vjust = 0, height = unit(0.12, "npc"))) +
  coord_sf(crs = 28992, datum = NA, expand = FALSE, clip = "off") +
  labs(title = "4Nov_Clusters: How many cities does the\nNetherlands really have?",
       subtitle = sprintf("DBSCAN on inhabited 100 m cells (eps 300 m, minPts 5) finds %s clusters.\nThe biggest runs from Den Haag to Rotterdam: %.1f million people on %.0f km\u00b2.\nAmsterdam is a cluster of its own. Grey cells don't belong to any cluster.",
                         format(n, big.mark = ","), max(size) / 1e6, sum(cl == big) / 100),
       caption = "Data from CBS Vierkantstatistieken 100 m (2025).\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026.") +
  theme_void() +
  theme(text = element_text(colour = "white"),
        plot.title = element_text(size = 17, face = "bold"), plot.subtitle = element_text(size = 9, lineheight = 1.1),
        plot.caption = element_text(size = 6.5, hjust = 0.5, colour = "grey70"), plot.margin = margin(15, 15, 10, 15))

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "#0d0d0d")
