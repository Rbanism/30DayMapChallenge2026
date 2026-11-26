# Process

I used the CBS 100 m grid for 2025 (448 MB, cached outside the repo) and kept only the resident count per cell in a 1 MB GeoTIFF (`data/inwoners.tif`). Secret cells (`-99997`, 1 to 4 residents) are stored as 2.

DBSCAN (`dbscan` package) runs on the 600,768 cell centroids. I tried a few settings:

| eps | minPts | clusters | biggest share of cells |
|---|---|---|---|
| 150 | 10 | 0 | none (a 3x3 block holds at most 9 cells) |
| 200 | 5 | 8,812 | 1.6% |
| 300 | 5 | 5,277 | 6.5% |
| 300 | 3 | 7,259 | 9.0% (Den Haag-Rotterdam plus Leiden) |
| 500 | 5 | 1,475 | 78.6% (nearly the whole country) |

I went with eps 300 and minPts 5, the last step before everything melts together. On a regular grid DBSCAN moves in jumps: below one cell spacing nothing joins, and one step further almost everything does. So the number of "cities" is really a choice of eps.

Each cluster gets a random colour between teal and purple, the biggest is orange and noise is grey, all drawn with `annotation_raster`.
