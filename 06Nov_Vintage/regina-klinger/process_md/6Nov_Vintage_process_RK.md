# Process

Made entirely in R, building on the Geospatial Data Carpentry for Urbanism course (TU Delft).

Data:
- Buildings: one 3DBAG tile (10-282-562), transformed to RD New (EPSG:28992).
- Streets: the Delft streets shapefile from the course preparation files.
- Canals: OpenStreetMap via osmdata, cropped and saved to data/.

Classification: a histogram showed peaks on round years (1650, 1850). I grouped the years with case_when() and ordered them with factor() levels.

Map: ggplot2, Bodoni Moda via showtext, logo with magick and cowplot, adapted from code by Dr. D. Cannatella.

I wrote the code myself. An AI assistant explained concepts, error messages and why code is written the way it is, so I understood the logic of the language instead of just memorising expressions.

What I learned:
- how to stack several vector layers in one plot
- that R works sequentially and by position: case_when() checks conditions from top to bottom (first match wins), and scale_fill_manual() matches colours to factor levels by position
- that cowplot places the logo in normalised coordinates of the whole canvas (0 to 1), so I measured its position in the exported PNG instead of adjusting it manually
