## Description
My tastes map mainly explores the spots I bookmarked for food or coffee on my personal google map. 
I aimed to calculate how far the spots I'd found in cities only within NL are easily reachable. How the map of my tastes looks like and how close they are to where I currently live, i.e., Den Haag.

## Process
I had to takeout my saved locations from google takeout as .csv file and geotag them based on their URLs within the csv files. There were two separate spreadsheets for Food and Coffee spots, 
so I had to bind them as a single dataframe. I geocoded the points using the "geocode()" function based on the OSM data information. And, I realized you need to convert the df to an sf,
so the data would acquire a geometry based on its latitude and longitude. To calculate the distance, the centroid of the city of Den Haag was generated and used as the anchor point.
The major distance calculation was done using the "st_distance()" function. The calculated distances were normalized and for a better understanding of the values in a real-world experience, 
I decided to put three valued categories with 10km length of intervals. This index helped to understand not only how distant a spot is from the anchor point, but how much value that distance holds
from a user (e.g., me) perspective. At the end, the spots within the satisfactory value (i.e., <10km) were shortlisted based on their category, so I can visit those spots within my most desired threshold.

## References
CBS, 2026.
OSM, 2026.
Google Maps, 2026.
