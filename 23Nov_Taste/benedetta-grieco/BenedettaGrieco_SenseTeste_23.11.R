# Rbanism 23/11 - taste:sense - Benedetta Grieco

# --- Cartella di lavoro: tutti i file vengono letti e salvati qui ---
# setwd("D:/TuDelft/23-11_SenseTaste_BenedettaGrieco")  # removed for reproducibility: run from this folder

# --- Librerie ---
library(sf)
library(dplyr)
library(mapview)
library(giscoR)
library(elevatr)
library(terra)
library(ggplot2)
library(tidyterra)
library(ggnewscale)
library(patchwork)   # per comporre più grafici in un'unica immagine
library(png)         # per leggere il logo
library(geodata)     # per scaricare i confini provinciali (GADM)

# ======================================================================
# SCELTA DELLO SFONDO: scrivi "bianco" oppure "nero" e riesegui tutto
sfondo <- "nero"
# ======================================================================

# --- Colori ---
col_bianco <- "#B3B300"   # vini bianchi
col_rosso  <- "#B30000"   # vini rossi

if (sfondo == "nero") {
  col_sfondo   <- "black"
  col_testo    <- "grey90"
  quota_bassa  <- "grey28"    # pianura
  quota_alta   <- "grey72"    # montagna
  col_curve    <- "white"     # curve di livello bianche (rese leggere con la trasparenza)
  curve_alpha  <- 0.45
  col_confine  <- "grey85"
  col_province <- "grey70"
  col_regione_piccola <- "grey15"
  col_province_piccole <- "grey80"   # province nelle mappe piccole: un po' più chiare
  col_linee    <- "grey85"    # linee che portano ai riquadri delle province
  box_fondo    <- "black"     # riquadri delle province: interno
  box_testo    <- "white"     # riquadri delle province: testo e bordo
  file_logo    <- "Logo_Rbanism_ White.png"   # logo bianco per lo sfondo nero
  ombra_scura  <- "black"     # versanti in ombra
  ombra_chiara <- "grey65"    # versanti al sole
  ombra_limite <- 1
  ombra_alpha  <- 0.35        # intensità delle ombre del rilievo
} else {
  col_sfondo   <- "white"
  col_testo    <- "grey15"
  quota_bassa  <- "grey94"
  quota_alta   <- "grey38"
  col_curve    <- "grey55"    # curve di livello grigie
  curve_alpha  <- 0.6
  col_confine  <- "grey30"
  col_province <- "grey55"
  col_regione_piccola <- "grey95"
  col_province_piccole <- "grey70"
  col_linee    <- "grey30"
  box_fondo    <- "white"     # riquadri delle province: interno bianco
  box_testo    <- "black"     # riquadri delle province: testo e bordo neri
  file_logo    <- "Logo_Rbanism_ Black.png"   # logo scuro per lo sfondo bianco (controlla il nome del file)
  ombra_scura  <- "grey20"
  ombra_chiara <- "white"
  ombra_limite <- 0.64        # pianura e versanti al sole restano bianchi
  ombra_alpha  <- 0.35
}

# --- Dati: vini con colore, quota e distanza dal mare (passi 1-4 già fatti) ---
mappa <- st_read("vini_campania_colori.gpkg")

# coordinate dei vini come colonne X (longitudine) e Y (latitudine),
# servono per calcolare le "nuvole" di densità
vini_xy <- cbind(st_drop_geometry(mappa), st_coordinates(mappa))

# --- Confini, province e rilievo ---
# ogni dato viene scaricato da internet solo la prima volta e salvato nella cartella;
# le volte successive viene letto dal file (più veloce, e i server non ci bloccano)
if (!file.exists("campania.gpkg")) {
  gisco_get_nuts(country = "IT", nuts_level = 2, resolution = "01") |>
    filter(NUTS_ID == "ITF3") |>
    st_write("campania.gpkg", delete_dsn = TRUE)
}
campania <- st_read("campania.gpkg")

if (!file.exists("province_campania.gpkg")) {
  # province italiane da GADM (livello 2), poi teniamo solo quelle della Campania
  gadm(country = "ITA", level = 2, path = ".") |>
    st_as_sf() |>
    filter(NAME_1 == "Campania") |>
    st_write("province_campania.gpkg", delete_dsn = TRUE)
}
province <- st_read("province_campania.gpkg")

# il file delle province può venire da due fonti diverse, con nomi di colonna diversi:
# GISCO (colonna NAME_LATN) oppure GADM (colonna NAME_2). Usiamo sempre NAME_2.
if ("NAME_LATN" %in% names(province)) {
  province$NAME_2 <- province$NAME_LATN
  fonte_province  <- "provinces © EuroGeographics (GISCO)"
} else {
  fonte_province  <- "provinces: GADM"
}

if (!file.exists("dem_campania.tif")) {
  get_elev_raster(campania, z = 8, clip = "locations") |>
    rast() |>
    writeRaster("dem_campania.tif", overwrite = TRUE)
}
dem <- rast("dem_campania.tif")

pendenza    <- terrain(dem, "slope",  unit = "radians")
esposizione <- terrain(dem, "aspect", unit = "radians")
ombra       <- shade(pendenza, esposizione, angle = 40, direction = 315)

# --- Etichette delle province: nome e vino prevalente ---
# per ogni provincia contiamo i vini bianchi e rossi che ci cadono dentro
# e teniamo il colore più frequente, con la sua percentuale
prevalenti <- st_join(mappa, province["NAME_2"]) |>
  st_drop_geometry() |>
  filter(colore != "rosato", !is.na(NAME_2)) |>
  count(NAME_2, colore) |>
  group_by(NAME_2) |>
  mutate(perc = round(100 * n / sum(n))) |>
  slice_max(n, n = 1, with_ties = FALSE) |>
  ungroup() |>
  mutate(
    testo = case_when(
      perc == 50         ~ "white / red 50%",
      colore == "bianco" ~ paste0("white ", perc, "%"),
      TRUE               ~ paste0("red ", perc, "%")
    ),
    # colore del calice accanto al riquadro
    col_calice = case_when(
      perc == 50         ~ "grey60",
      colore == "bianco" ~ col_bianco,
      TRUE               ~ col_rosso
    )
  )

# un punto dentro ogni provincia dove mettere l'etichetta
etichette <- province["NAME_2"] |>
  st_transform(32633) |>
  st_point_on_surface() |>
  st_transform(4326)
etichette <- cbind(st_drop_geometry(etichette), st_coordinates(etichette)) |>
  left_join(prevalenti, by = "NAME_2")

# dove mettere ogni riquadro, fuori dalla regione (longitudine lx, latitudine ly):
# se un riquadro non ti piace dove sta, cambia qui i suoi due numeri
# (lx, ly) è il lato DESTRO del riquadro; il calice sta subito a destra
posizioni <- data.frame(
  NAME_2 = c("Caserta", "Benevento", "Avellino", "Salerno", "Napoli"),
  lx     = c(13.75,      15.70,       16.00,      16.20,     13.95),
  ly     = c(41.47,      41.45,       41.05,      40.30,     40.50)
)
etichette <- etichette |>
  left_join(posizioni, by = "NAME_2") |>
  mutate(etichetta = paste0(toupper(NAME_2), "\n", testo))

# --- Calici: un piccolo bicchiere disegnato con linee e forme semplici ---
# per ogni punto (cx, cy) = base del calice, costruisce la coppa, il vino dentro,
# lo stelo e la base. w = larghezza, h = altezza (in gradi, come la mappa)
calici <- function(punti, w = 0.055, h = 0.10) {
  t <- seq(pi, 2 * pi, length.out = 40)          # mezza ellisse = coppa
  coppa <- list(); vino <- list(); stelo <- list()
  for (i in seq_len(nrow(punti))) {
    cx <- punti$cx[i]; cy <- punti$cy[i]
    bordo <- cy + h                               # orlo del calice
    ry    <- 0.55 * h                             # profondità della coppa
    arco  <- data.frame(x = cx + (w / 2) * cos(t), y = bordo + ry * sin(t), id = i)
    coppa[[i]] <- arco
    livello <- bordo - 0.35 * ry                   # fin dove arriva il vino
    v <- arco[arco$y <= livello, ]
    v$colore <- punti$colore[i]
    vino[[i]] <- v
    stelo[[i]] <- data.frame(x    = c(cx,           cx - 0.3 * w),
                             xend = c(cx,           cx + 0.3 * w),
                             y    = c(bordo - ry,   cy),
                             yend = c(cy,           cy))
  }
  list(coppa = do.call(rbind, coppa), vino = do.call(rbind, vino), stelo = do.call(rbind, stelo))
}

# calici della legenda (in basso a sinistra, nel mare), a destra delle scritte
leg <- calici(data.frame(cx = c(13.90, 13.90), cy = c(40.23, 40.07),
                         colore = c(col_bianco, col_rosso)))
# calici a destra dei riquadri delle province
cal <- calici(data.frame(cx = etichette$lx + 0.045, cy = etichette$ly - 0.055,
                         colore = etichette$col_calice))

# --- Impostazioni comuni ---
raggio     <- c(0.30, 0.30)     # ampiezza delle nuvole (orizzontale, verticale): più alto = più sfumato e largo
riquadro_x <- c(13.4, 16.35)   # più largo della regione, per fare spazio ai riquadri delle province
riquadro_y <- c(39.95, 41.55)
# area di calcolo delle nuvole più grande del riquadro, così le nuvole non vengono tagliate
area_calcolo <- data.frame(X = c(12.9, 16.7), Y = c(39.2, 42.3))

# --- Mappa principale: dove la Campania è bianca e dove è rossa ---
# gli strati si disegnano nell'ordine in cui sono scritti: il primo sta sotto, l'ultimo sopra
mappa_plot <- ggplot() +
  # allarga l'area su cui vengono calcolate le nuvole (non disegna niente)
  geom_blank(data = area_calcolo, aes(X, Y)) +
  # 1. fasce di quota in grigio (ogni 200 m)
  geom_spatraster(data = dem) +
  scale_fill_steps(low = quota_bassa, high = quota_alta,
                   breaks = seq(200, 1800, by = 200), limits = c(0, 1900),
                   oob = scales::squish, na.value = NA, guide = "none") +
  # 2. ombre del rilievo
  new_scale_fill() +
  geom_spatraster(data = ombra, alpha = ombra_alpha) +
  scale_fill_gradient(low = ombra_scura, high = ombra_chiara, limits = c(0, ombra_limite),
                      oob = scales::squish, na.value = NA, guide = "none") +
  # 3. curve di livello sottili: 50 m (per la pianura) e poi ogni 100 m
  geom_spatraster_contour(data = dem, breaks = c(50, seq(100, 1800, by = 100)),
                          colour = col_curve, alpha = curve_alpha, linewidth = 0.2) +
  # 4. confini provinciali tratteggiati
  geom_sf(data = province, fill = NA, colour = col_province, linewidth = 0.35, linetype = "dashed") +
  # 5. confine regionale
  geom_sf(data = campania, fill = NA, colour = col_confine, linewidth = 0.35) +
  # 6. linee che portano dalle province ai riquadri (sotto il vino)
  geom_segment(data = etichette, aes(x = X, y = Y, xend = lx, yend = ly),
               colour = col_linee, linewidth = 0.3) +
  geom_point(data = etichette, aes(X, Y), colour = col_linee, size = 0.8) +
  # 7. il vino: nuvole dei rossi e dei bianchi,
  #    più intense dove i vini sono più concentrati
  stat_density_2d(data = filter(vini_xy, colore == "rosso"),
                  aes(X, Y, alpha = after_stat(level)),
                  geom = "polygon", fill = col_rosso, colour = NA, h = raggio, bins = 18) +
  stat_density_2d(data = filter(vini_xy, colore == "bianco"),
                  aes(X, Y, alpha = after_stat(level)),
                  geom = "polygon", fill = col_bianco, colour = NA, h = raggio, bins = 18) +
  scale_alpha_continuous(range = c(0.06, 0.85), guide = "none") +   # più alto = colori più accesi
  # 8. riquadri delle province, sopra a tutto
  geom_label(data = etichette, aes(lx, ly, label = etichetta), hjust = 1,   # riquadro a sinistra di lx
             family = "Montserrat", size = 2.6, lineheight = 0.9,
             colour = box_testo, fill = box_fondo,        # testo e bordo, interno
             label.r = unit(0, "lines"),                  # angoli squadrati
             label.padding = unit(0.35, "lines")) +
  # 9. calici accanto ai riquadri: il colore dice il vino prevalente
  geom_polygon(data = filter(cal$vino, colore == col_bianco), aes(x, y, group = id), fill = col_bianco) +
  geom_polygon(data = filter(cal$vino, colore == col_rosso),  aes(x, y, group = id), fill = col_rosso) +
  geom_polygon(data = filter(cal$vino, colore == "grey60"),   aes(x, y, group = id), fill = "grey60") +
  geom_path(data = cal$coppa, aes(x, y, group = id), colour = box_testo, linewidth = 0.35) +
  geom_segment(data = cal$stelo, aes(x = x, y = y, xend = xend, yend = yend),
               colour = box_testo, linewidth = 0.35) +
  # legenda con i calici, nel mare in basso a sinistra
  geom_polygon(data = filter(leg$vino, colore == col_bianco), aes(x, y, group = id), fill = col_bianco) +
  geom_polygon(data = filter(leg$vino, colore == col_rosso),  aes(x, y, group = id), fill = col_rosso) +
  geom_path(data = leg$coppa, aes(x, y, group = id), colour = col_testo, linewidth = 0.35) +
  geom_segment(data = leg$stelo, aes(x = x, y = y, xend = xend, yend = yend),
               colour = col_testo, linewidth = 0.35) +
  annotate("text", x = 13.85, y = c(40.28, 40.12), label = c("white wines", "red wines"),
           hjust = 1, size = 3.2, family = "Montserrat", colour = col_testo) +
  coord_sf(xlim = riquadro_x, ylim = riquadro_y, expand = FALSE) +
  theme_void(base_family = "Montserrat") +
  theme(plot.background = element_rect(fill = col_sfondo, colour = NA))

# --- Tre mappe delle denominazioni (DOC, DOCG, IGT), colori Rbanism ---
denominazioni_plot <- ggplot() +
  geom_blank(data = area_calcolo, aes(X, Y)) +
  geom_sf(data = campania, fill = col_regione_piccola, colour = col_province, linewidth = 0.2) +
  stat_density_2d(data = vini_xy,
                  aes(X, Y, fill = lista, alpha = after_stat(level)),
                  geom = "polygon", colour = NA, h = raggio, bins = 15) +
  scale_fill_manual(values = c(DOC = "#93278F", DOCG = "#00A99D", IGT = "#F7931E"), guide = "none") +
  scale_alpha_continuous(range = c(0.06, 0.8), guide = "none") +
  geom_sf(data = province, fill = NA, colour = col_province_piccole, linewidth = 0.15, linetype = "dashed") +
  facet_wrap(~lista, ncol = 1) +          # una mappa per denominazione, una sotto l'altra
  coord_sf(xlim = riquadro_x, ylim = riquadro_y, expand = FALSE) +
  labs(title = "Campania wine designations") +
  theme_void(base_family = "Montserrat") +
  theme(strip.text = element_text(size = 9, face = "bold", hjust = 0, colour = col_testo),
        plot.title = element_text(size = 10, face = "bold", colour = col_testo,
                                  margin = margin(b = 8)),
        plot.background = element_rect(fill = col_sfondo, colour = NA))

# --- Piramide altimetrica: quanti bianchi e quanti rossi in ogni fascia di 100 m ---
piramide_dati <- st_drop_geometry(mappa) |>
  filter(colore != "rosato") |>
  mutate(fascia = cut(quota, breaks = seq(0, 700, by = 100), dig.lab = 4)) |>
  count(fascia, colore) |>
  # i bianchi vanno a sinistra (numeri negativi), i rossi a destra
  mutate(n_lato = ifelse(colore == "bianco", -n, n))

# etichette delle fasce: "0-100 m", "100-200 m", ...
etichette_fasce <- paste0(seq(0, 600, by = 100), "-", seq(100, 700, by = 100), " m")

piramide <- ggplot(piramide_dati, aes(x = n_lato, y = fascia, fill = colore)) +
  geom_col(width = 0.45) +                           # barre sottili
  geom_vline(xintercept = 0, colour = col_testo, linewidth = 0.3) +
  scale_fill_manual(values = c(bianco = col_bianco, rosso = col_rosso), guide = "none") +
  scale_x_continuous(labels = abs) +                 # mostra i numeri senza il segno meno
  scale_y_discrete(labels = etichette_fasce, drop = FALSE) +
  labs(title = "Altitude of the wines",
       subtitle = "Wines per 100 m band:\nwhite (left), red (right)",
       x = NULL, y = NULL) +
  theme_minimal(base_family = "Montserrat") +
  theme(panel.grid = element_blank(),
        text = element_text(colour = col_testo),
        axis.text = element_text(colour = col_testo, size = 6),
        plot.title = element_text(size = 9, face = "bold"),
        plot.subtitle = element_text(size = 6.5),
        plot.background = element_rect(fill = col_sfondo, colour = NA))

# --- Fascia in basso: crediti a sinistra, logo a destra ---
crediti <- paste("Data: Google Maps lists 'DOC / DOCG / IGT Campania' (A. Maione), geocoded with ArcGIS.",
                 paste0("\nBoundaries © EuroGeographics (GISCO); ", fonte_province, "; elevation: AWS Terrain Tiles via elevatr."),
                 "\nMap: Benedetta Grieco | #30DayMapChallenge 2026, day 23: taste:sense")

crediti_plot <- ggplot() +
  annotate("text", x = 0, y = 0.5, label = crediti, hjust = 0, vjust = 0.5,
           family = "Montserrat", size = 2.3, lineheight = 1.2, colour = col_testo) +
  scale_x_continuous(limits = c(0, 1), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
  coord_cartesian(clip = "off") +
  theme_void()

# il logo occupa tutta l'altezza della fascia dei crediti
logo_plot <- if (file.exists(file_logo)) {
  wrap_elements(full = grid::rasterGrob(readPNG(file_logo)))
} else {
  plot_spacer()
}

fascia_crediti <- (crediti_plot | logo_plot) + plot_layout(widths = c(9, 1))

# --- Composizione finale: tavola quadrata ---
# a sinistra la mappa grande; a destra, in colonna, le tre denominazioni e sotto la piramide
colonna_destra <- denominazioni_plot / piramide + plot_layout(heights = c(3, 1.1))
parte_alta     <- (mappa_plot | colonna_destra) + plot_layout(widths = c(2.5, 1))

finale <- (parte_alta / fascia_crediti) +
  plot_layout(heights = c(10, 0.9)) +
  plot_annotation(
    title    = "The wineries of Campania",
    subtitle = paste("A map of the flavours of a territory, traced through the wineries collected over time on personal maps",
                     "\nduring journeys across Campania. Explore the region from the volcanic islands and coast to the Apennine hills,",
                     "\norganised by colour, altitude and designation."),
    theme = theme(text = element_text(family = "Montserrat", colour = col_testo),
                  plot.title = element_text(face = "bold", size = 18),
                  plot.subtitle = element_text(size = 9.5, lineheight = 1.15, margin = margin(t = 4, b = 10)),
                  plot.margin = margin(15, 20, 15, 20),
                  plot.background = element_rect(fill = col_sfondo, colour = NA))
  ) &
  theme(plot.background = element_rect(fill = col_sfondo, colour = NA))

# --- Esporta il PNG ---
# richiede circa un minuto: aspetta che in console ricompaia il simbolo >
nome_file <- paste0("23_taste-sense_BenedettaGrieco_", sfondo, ".png")
ggsave(nome_file, finale,
       width = 10, height = 10, dpi = 300, bg = col_sfondo, device = ragg::agg_png)   # quadrato

# conferma in console: dove è stato salvato il file
message("Mappa salvata in: ", normalizePath(nome_file))

# --- Mostra la mappa salvata nel pannello Plots di RStudio ---
# (mostriamo il PNG esportato: è identico al file finale e non manda in timeout RStudio)
grid::grid.newpage()
grid::grid.raster(readPNG(nome_file))

# ======================================================================
# STORICO: preparazione dati (già eseguita, non serve rieseguirla)
# ----------------------------------------------------------------------
# Geocodifica: KML da My Maps -> nomi e indirizzi -> ArcGIS (tidygeocoder)
# library(xml2); library(tidygeocoder)
# k  <- read_xml("luoghi_da_geocodificare.csv (1).kml"); xml_ns_strip(k)
# pm <- xml_find_all(k, "//Placemark")
# luoghi <- data.frame(nome = trimws(xml_text(xml_find_first(pm, "name"))),
#                      ricerca = xml_text(xml_find_first(pm, "address")))
# luoghi <- geocode(luoghi, address = ricerca, method = "arcgis")
# i <- luoghi$nome == "OCONE 1910 - Taburno Wine County"   # finito in Romania
# fix <- geo("Ocone vini, Ponte, Benevento, Italia", method = "arcgis")
# luoghi$lat[i] <- fix$lat; luoghi$long[i] <- fix$long
# vini  <- read.csv("vini_campania (1).csv", encoding = "UTF-8")
# punti <- st_as_sf(luoghi, coords = c("long", "lat"), crs = 4326)
# mappa <- left_join(vini, punti, by = "nome") |> st_as_sf()
# st_write(mappa, "vini_campania.gpkg", delete_dsn = TRUE)
#
# Passo 1: colore del vino dai vitigni nel nome
# mappa <- mappa |>
#   mutate(colore = case_when(
#     grepl("Rosato|Rosè|rosa", paste(denominazione, vino), ignore.case = TRUE) ~ "rosato",
#     grepl("Aglianico|Piedirosso|Sciascinoso|Tintore|Casavecchia|Pallagrello Nero|Pallegrello Nero|Guarnaccia|Barbera|Sangiovese|Cabernet|Merlot|Montepulciano|Uva di Troia|Lambrusco|Taurasi|Rosso|Ottouve|Ghiandaie", paste(denominazione, vino)) ~ "rosso",
#     grepl("Fiano|Greco|Falanghina|Biancolella|Forastera|Coda di Volpe|Caprettone|Asprinio|Catalanesca|Pallagrello Bianco|Pallegrello Bianco|Malvasia|Trebbiano|Moscato|Bianco|Coda di Pecora|Fenile|Congregazione", paste(denominazione, vino)) ~ "bianco",
#     TRUE ~ "non indicato"))
#
# Passo 2: 7 cantine senza vino indicato -> una riga bianco + una rosso
# doppie <- mappa |> filter(colore == "non indicato")
# nota_txt <- "bianco e rosso aggiunti: l'elenco non specifica il vino"
# mappa <- rbind(
#   mappa |> filter(colore != "non indicato") |> mutate(nota = ""),
#   doppie |> mutate(colore = "bianco", nota = nota_txt),
#   doppie |> mutate(colore = "rosso",  nota = nota_txt))
#
# Passo 4: quota e distanza dal mare
# mappa$quota <- terra::extract(dem, vect(mappa))[, 2]
# costa <- gisco_get_countries(country = "IT", resolution = "01") |>
#   st_transform(32633) |> st_boundary()
# mappa$dist_mare_km <- as.numeric(st_distance(st_transform(mappa, 32633), costa)) / 1000
# st_write(mappa, "vini_campania_colori.gpkg", delete_dsn = TRUE)
