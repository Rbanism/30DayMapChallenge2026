
# 06_final.R  |  #30DayMapChallenge 2026  |  Smell | Cinco 

library(sf)
library(ggplot2)
library(ggrepel)
library(patchwork)   
library(png)         


wwtp    <- st_read("data/wwtp.gpkg", quiet = TRUE)
buurten <- st_read("data/buurten_study.gpkg", quiet = TRUE)
rose    <- read.csv("data/smell_rose.csv")


center <- st_coordinates(st_centroid(st_geometry(wwtp)))
cx <- center[1]
cy <- center[2]


max_r <- 4000                                    
rose$r    <- rose$pct / max(rose$pct) * max_r    
rose$days <- round(rose$pct * 365 / 100)         
rose$top  <- rose$sector %in% c(0, 30, 60, 90)   
half_days <- round(sum(rose$pct[rose$top]) * 365 / 100)

rose$lab_x <- cx + (rose$r + 350) * sin(rose$sector * pi / 180)
rose$lab_y <- cy + (rose$r + 350) * cos(rose$sector * pi / 180)


petals <- list()
for (i in 1:nrow(rose)) {
  angles <- seq(rose$sector[i] - 15, rose$sector[i] + 15, by = 1) * pi / 180
  x <- c(cx, cx + rose$r[i] * sin(angles), cx)
  y <- c(cy, cy + rose$r[i] * cos(angles), cy)
  petals[[i]] <- st_polygon(list(cbind(x, y)))
}
rose_sf <- st_sf(rose, geometry = st_sfc(petals, crs = 28992))


buurten$klasse <- cut(buurten$pct_sensitive,
                      breaks = c(0, 25, 30, 35, 40, 100),
                      labels = c("< 25%", "25-30%", "30-35%", "35-40%", "40% +"),
                      right = FALSE, include.lowest = TRUE)
levels(buurten$klasse) <- c(levels(buurten$klasse), "Too few residents")
buurten$klasse[is.na(buurten$klasse)] <- "Too few residents"
colours6 <- c("#ffffff", "#fde3d3", "#f9b48f", "#f2864f", "#d9581f", "grey88")


smell_zone   <- st_union(rose_sf)
buurten$id   <- 1:nrow(buurten)
buurten$area <- as.numeric(st_area(buurten))
inside       <- suppressWarnings(st_intersection(buurten, smell_zone))
inside$share <- as.numeric(st_area(inside)) / inside$area
buurten$A    <- buurten$id %in% inside$id[inside$share >= 0.5]


buurten$B  <- buurten$klasse == "40% +"
buurten$AB <- buurten$A & buurten$B
both       <- buurten[buurten$AB, ]
n_sensitive <- round(sum(both$inwoners * both$pct_sensitive / 100, na.rm = TRUE))


print(rose[, c("sector", "pct", "days")])
cat("Days per year towards north and east:", half_days, "\n")
print(table(A = buurten$A, B = buurten$B))
cat("Neighbourhoods in A AND B:", paste(both$buurtnaam, collapse = ", "), "\n")
cat("Children and seniors in A AND B:", n_sensitive, "\n")


final <- ggplot() +
  geom_sf(data = buurten, aes(fill = klasse), alpha = 0.35, colour = "grey80", linewidth = 0.1) +
  geom_sf(data = both, aes(fill = klasse), colour = "black", linewidth = 0.5) +
  geom_sf(data = rose_sf, fill = NA, colour = "grey15", linewidth = 0.35) +
  geom_sf(data = rose_sf[rose_sf$top, ], fill = NA, colour = "grey10", linewidth = 1) +
  geom_sf(data = wwtp, fill = "grey15", colour = NA) +
  geom_text(data = rose, aes(x = lab_x, y = lab_y, label = paste0(days, " d"),
                             fontface = ifelse(top, "bold", "plain")),
            size = 2.6, colour = "grey15") +
  geom_label_repel(data = both, aes(label = buurtnaam, geometry = geom),
                   stat = "sf_coordinates", size = 2.4, fill = "white", colour = "grey10",
                   label.size = 0, min.segment.length = 0, segment.colour = "grey10",
                   segment.size = 0.3, seed = 1) +
  scale_fill_manual(values = colours6, drop = FALSE,
                    name = "Children (0-14)\n+ seniors (65+)") +
  guides(fill = guide_legend(override.aes = list(alpha = 1))) +
  coord_sf(xlim = c(cx - 5000, cx + 5000), ylim = c(cy - 5000, cy + 5000),
           expand = FALSE, datum = NA) +
  labs(
    title = "Where does the smell go, and who is there?",
    subtitle = paste0(
      "Petal length = days per year the wind carries air from the Harnaschpolder ",
      "wastewater treatment plant\nin that direction (KNMI, 2021-2025). For about ",
      half_days, " days a year it blows toward the north and east (bold petals).\n",
      "Outlined: neighbourhoods mostly inside the petals AND with 40% or more ",
      "children and seniors,\ngroups more sensitive to odour nuisance. About ",
      format(n_sensitive, big.mark = ","), " children and seniors live there."),
    caption = paste0(
      "Data: KNMI hourly wind, station Rotterdam (344) | ",
      "CBS Wijk- en buurtkaart 2024 (CBS, Kadaster) | OpenStreetMap contributors\n",
      "#30DayMapChallenge 2026 | Smell | made in R")
  ) +
  theme_void(base_size = 10) +
  theme(
    plot.title    = element_text(face = "bold", size = 16),
    plot.subtitle = element_text(colour = "grey30", size = 8.5, lineheight = 1.15,
                                 margin = margin(b = 10)),
    plot.caption  = element_text(colour = "grey50", size = 6.5, hjust = 0, lineheight = 1.1),
    legend.title  = element_text(size = 8),
    legend.text   = element_text(size = 7.5),
    plot.background = element_rect(fill = "white", colour = NA),
    plot.margin   = margin(15, 15, 10, 15)
  )

logo <- grid::rasterGrob(readPNG("../../resources/logo/Logo_Rbanism_ CL.png"), interpolate = TRUE)
final_logo <- final +
  inset_element(logo, left = 0.87, right = 0.98, bottom = 0.86, top = 0.985,
                align_to = "full", on_top = TRUE)

ggsave("30DMC2026_smell.png", final_logo, width = 8, height = 8.8, dpi = 300)
cat("Saved: 30DMC2026_smell.png\n")


