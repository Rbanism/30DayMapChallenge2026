library(sf)
library(viewscape)
library(png)

#### COMPUTE VIEWSHED #### 

#Read DEM
cy_dem <- terra::rast("data/raw_data/cy_DEM30m_rp/cy_DEM30m_rp.tif")

# Enlarge map extent
e <- terra::ext(cy_dem)
pad <- 0.10 * (e[2] - e[1])     
e_big <- terra::ext(e[1] - pad, e[2] + pad, e[3] - pad, e[4] + pad)
cy_dem_sea <- terra::extend(cy_dem, e_big)
cy_dem_big <- cy_dem_sea
cy_dem_sea[is.na(cy_dem_sea)] <- 0

#Read multiple viewpoints   
castles_vp <- sf::read_sf("data/raw_data/cy_castles_rp/cy_castles_rp.shp") 

# Compute viewsheds
output <- viewscape::compute_viewshed(dsm = cy_dem_sea, 
                                      viewpoints = castles_vp, 
                                      offset_viewpoint = 6,
                                      parallel = TRUE, 
                                      workers = 3,
                                      r = 50000) 

#### PLOT ####

cols <- c("#084887", "#FFAA00", "#A52422")
pts <- terra::vect(castles_vp)

# Hillshade
slope  <- terra::terrain(cy_dem_big, "slope",  unit = "radians")
aspect <- terra::terrain(cy_dem_big, "aspect", unit = "radians")
hill   <- terra::shade(slope, aspect, angle = 40, direction = 270)

# Basemap
terra::plot(hill, 
            col = grey(0:100 / 100), 
            legend = FALSE, 
            axes = FALSE,
            background = "white")

# DEM
terra::plot(cy_dem_big,
            add = TRUE, 
            col = hcl.colors(50, "Terrain"),
            alpha = 0.4, 
            axes = FALSE,
            legend = TRUE)

# Viewsheds
for (i in seq_along(output)) {
  raster_data <- viewscape::visualize_viewshed(output[[i]], outputtype = "raster")
  terra:: plot(raster_data, 
               add = TRUE,
               col = adjustcolor(cols[i], alpha.f = 0.5),
               legend = FALSE, 
               axes = FALSE)
}

# Points and labels
terra::points(pts, pch = 21, cex = 1.8, bg = "white", col = "black", lwd = 1)
terra::text(pts, labels = "name", pos = c(3,1,3), cex = 0.7, col = "black", font = 2, halo = TRUE, hc = "white", lwd = 1)

# Arrow and scale
e  <- terra::ext(cy_dem_big)
w  <- e[2] - e[1]
h  <- e[4] - e[3]

terra::sbar(d = 50000, xy = c(e[2] - 0.20 * w, e[3] + 0.15 * h),
            type = "bar", divs = 2, below = "km",
            labels = c(0, 25, 50), cex = 0.8)

terra::north(xy = c(e[2] - 0.13 * w, e[3] + 0.27 * h), type = 2, d = 20000)

#### TEXT ####

label_box <- function(x, y, txt, cex = 1, font = 1, pad = 0.012) {
  op <- par(xpd = NA); on.exit(par(op))
  u  <- par("usr")
  tw <- strwidth(txt,  cex = cex, font = font)
  th <- strheight(txt, cex = cex, font = font)
  px <- pad * (u[2] - u[1])
  py <- pad * (u[4] - u[3])
  
  top    <- y
  bottom <- y - th - 2 * py
  
  rect(x - px, bottom, x + tw + px, top,
       col = NA, border = NA)
  text(x, top - py, txt, adj = c(0, 1), cex = cex, font = font)
  
  invisible(list(left = x - px, right = x + tw + px, top = top, bottom = bottom))
}

# Set map frame
u <- par("usr")
w <- u[2] - u[1]
h <- u[4] - u[3]

t <- label_box(u[1] + 0.03 * w, u[4] - 0.03 * h,
               "Cyprus Medieval Castles Viewshed\non Pentadaktylos Mountain",
               cex = 1.2, font = 2)

label_box(u[1] + 0.03 * w, t$bottom - 0.02 * h,
          "Areas visible from the top of each \ncastle, calculated from Cyprus' \nDigital Elevation Model \n(source: Copernicus DEM GLO-30).\n",
          cex = 0.8)

# Credit
credit <- "#30DayMapChallenge | Alex Pieri & Charis Spanos | Day 5: Sight - 2026"
cex_c  <- 0.8
pad    <- 0.012

box_w <- strwidth(credit, cex = cex_c) + 2 * pad * w
box_h <- strheight(credit, cex = cex_c) + 2 * pad * h

y_top    <- u[3] + 0.03 * h + box_h     
y_bottom <- y_top - box_h                #

label_box((u[1] + u[2]) / 2 - box_w / 2 + pad * w, y_top, credit, cex = cex_c)

# Logo

logo <- png::readPNG("data/clean_data/Logo_Blue.png")  
nr <- dim(logo)[1]; nc <- dim(logo)[2]

x_per_in <- w / par("pin")[1]
y_per_in <- h / par("pin")[2]

logo_h <- 2*box_h
logo_w <- (logo_h / y_per_in) * (nc / nr) * x_per_in

x_logo <- u[1] + 0.03 * w                

par(xpd = NA)
rasterImage(logo,
            xleft  = x_logo,           ybottom = y_bottom,
            xright = x_logo + logo_w,  ytop    = y_bottom + logo_h,
            interpolate = TRUE)
par(xpd = FALSE)
