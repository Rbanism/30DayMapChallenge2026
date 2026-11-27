# 28Nov_Feeling: Spatial Sentiment Analysis per Topics in Tehran, 2022-2026.

![Map](Nov28_Feeling_Map.png)

**Mapper:** Soroush Saffarzadeh\
**Data:** 4TU.ResearchData, originated from X (formerly Twitter) (2026)

## About the map

The map is derived from the master's thesis entitled ["Urban Digital Memory: Leveraging Social Media Data on Public Spaces to Inform Urban Design Processes"](https://resolver.tudelft.nl/uuid:b53fa71f-14ef-49a9-87a8-4a73372ff841) that focused on the spatial discourses shaped by citizens of Tehran regarding public space interventions and how they expressed their feelings regarding those matters in the form of tweets on X. This map is a fraction of how the analysis would look like if we try to visualize and spatialize it, a starting point towards a well-developed map of digital memories.

## Process

I already had the analyzed data as a csv format which is no published and accessible via [4TU.ResearchData](https://doi.org/10.4121/60d059e9-991f-4887-802f-3e28e41eb962.v1). I attempted geotagging the topics and sentiments based on the key names of the places which topics are related to. Afterwards, I set the CRS of the base layer of Tehran with the geotagged local topics, i.e., points, so the projections would align. After that, I had to visualize the sentiment percentages (tweet counts) for a better understanding of their proportions per topics. 

## Files

- [`Nov23rd_Tastes.R`](Nov28_Feeling_Script.R): R code
- [`Nov23_Tastes.png`](Nov28_Feeling_Map.png): the map
- [`Data/Tehran_Base`](tehran_boundary.gpkg): Tehran's Boundary Layer (Basemap)
- [Data/DOI](https://doi.org/10.4121/60d059e9-991f-4887-802f-3e28e41eb962.v1): Processed data from the sentiment analysis & topic modeling
