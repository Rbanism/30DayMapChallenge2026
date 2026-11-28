library(sf); library(cbsodataR); library(ggplot2); library(ggrepel)

f <- "data/cows.gpkg"
if (!file.exists(f)) {
  gem <- st_read("https://service.pdok.nl/cbs/gebiedsindelingen/2025/wfs/v1_0?request=GetFeature&service=WFS&version=2.0.0&typeNames=gemeente_gegeneraliseerd&outputFormat=json")[, c("statcode", "statnaam")]
  cows <- cbs_get_data("80781ned", Perioden = "2025JJ00", select = c("RegioS", "Perioden", "RundveeTotaal_84"))
  pop <- cbs_get_data("03759ned", Perioden = "2025JJ00", Geslacht = "T001038", Leeftijd = "10000", BurgerlijkeStaat = "T001019",
                      select = c("RegioS", "Perioden", "BevolkingOp1Januari_1"))
  gem$cows <- cows$RundveeTotaal_84[match(gem$statcode, trimws(cows$RegioS))]
  gem$people <- pop$BevolkingOp1Januari_1[match(gem$statcode, trimws(pop$RegioS))]
  st_write(gem, f)
}
gem <- st_read(f)

stopifnot(sum(gem$cows) > 3.5e6, sum(gem$cows) < 4e6, sum(gem$people) > 17.5e6, sum(gem$people) < 18.5e6)
gem$ratio <- gem$cows / gem$people
more <- gem[gem$ratio > 1, ]
top <- st_point_on_surface(more[order(-more$ratio)[1:6], ])
logo <- png::readPNG("data/Logo_Rbanism_ Full.png")

p <- ggplot(gem) +
  geom_sf(aes(fill = cut(ratio, c(-Inf, 0.01, 0.1, 0.5, 1, 1.5, 2, Inf))), colour = "white", linewidth = 0.1) +
  geom_sf(data = more, fill = NA, colour = "black", linewidth = 0.45) +
  geom_text_repel(data = top, aes(geometry = geom, label = sprintf("%s  %.1f", statnaam, ratio)), stat = "sf_coordinates",
                  size = 2.6, fontface = "bold", hjust = 0, direction = "y", nudge_x = 60000, min.segment.length = 0, segment.size = 0.3, bg.colour = "white") +
  scale_fill_manual(values = c("#00A99D", "#66cbc4", "#b3e5e1", "#e8f6f5", "#e3b8e1", "#c06fbc", "#93278F"),
                    labels = c("< 0.01", "0.01 - 0.1", "0.1 - 0.5", "0.5 - 1", "1 - 1.5  cows win", "1.5 - 2", "> 2"),
                    name = "Cows per person") +
  annotation_custom(grid::rasterGrob(logo, x = 1, y = 1.01, hjust = 1, vjust = 0, height = unit(0.11, "npc"))) +
  coord_sf(datum = NA, clip = "off") +
  labs(title = "9Nov_UrbanRural: Cows vs people",
       subtitle = sprintf("The Netherlands has %.1f million cattle and %.1f million people (2025).\nIn %d of %d municipalities (outlined) the cows win, most of all in %s (%.1f cows per person).",
                         sum(gem$cows) / 1e6, sum(gem$people) / 1e6, nrow(more), nrow(gem), top$statnaam[1], top$ratio[1]),
       caption = "Data from CBS StatLine 80781ned (cattle) and 03759ned (population), with CBS/PDOK boundaries for 2025.\nMap by Daman Dogra for Rbanism's #30DayMapChallenge 2026.") +
  theme_void() +
  theme(legend.position = "inside", legend.position.inside = c(0.02, 0.98), legend.justification = c(0, 1),
        legend.title = element_text(size = 8, face = "bold"), legend.text = element_text(size = 7),
        plot.title = element_text(size = 17, face = "bold"), plot.subtitle = element_text(size = 10),
        plot.caption = element_text(size = 6, hjust = 0.5), plot.margin = margin(15, 15, 10, 15))

ggsave("map.png", p, width = 2400, height = 3000, units = "px", dpi = 300, bg = "white")
