# 4Nov_Clusters: How many cities does the Netherlands really have?

Officially the Netherlands has 342 municipalities and a few dozen "cities". I've never been sure where one Dutch city ends and the next begins, so I let an algorithm decide, without looking at names or borders.

Every inhabited 100 x 100 m cell (CBS, 2025) is a point. DBSCAN groups points that lie within 300 m of each other (with at least 5 neighbours) into one settlement. Each settlement gets a random colour, and scattered houses that don't join anything stay grey.

That gives 5,277 clusters. The biggest one (orange) runs from Scheveningen through Delft and Zoetermeer to Rotterdam and Gouda: about 2.5 million people on 391 km² of inhabited cells. Amsterdam (about 1.45 million people) is a cluster of its own, separated by the polders and the Green Heart.

The answer depends a lot on the settings. At eps 500 m almost the whole country (79% of cells) merges into one cluster.
