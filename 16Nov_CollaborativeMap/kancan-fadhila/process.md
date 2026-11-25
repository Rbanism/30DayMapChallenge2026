REFLECTION

We were both new to R and to mapping with code, so we started from the GDCU course videos and short guidebooks made from them. We collected our answers in a shared Google Sheet, copied coordinates from Google Maps, and worked in RStudio (Posit Cloud and desktop).
In R we read the Excel file, split each "latitude, longitude" cell into two numbers, built points with sf, and measured every pair of answers with st_distance. Then we layered the map in ggplot2: world map, curved lines, number labels, points, and a table underneath.
Because of the limited time, we used AI assistance to help with the layering and plotting part, also when we find some errors. We ran and edited the code ourselves.
What we learned: sf wants longitude before latitude; a distance on the globe is not a straight line on a flat map; and most of our errors were small ones, like a missing comma, a wrong working directory or an object defined too late.
