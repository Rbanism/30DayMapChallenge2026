# Process

I downloaded the latest CBS 100 m grid (`2026-cbs_vk100_2025_v1.zip`, a 448 MB GeoPackage with 600,768 cells) to a cache outside the repo. The CBS website refused the TLS handshake from Windows, so I fetched the file with Python instead.

No cell has `aantal_inwoners = 0`. The lowest count is 5 (counts are rounded), and `-99997` means secret, i.e. 1 to 4 residents. Empty cells are simply not in the file. So I count `-99997` as inhabited and every land cell missing from the file as uninhabited, which makes this a map of missing rows.

For the land grid I rasterized the land parts (`water = "NEE"`) of the municipalities in the PDOK Wijk- en buurtkaart 2024 onto a 100 m grid aligned with the CBS cells (cell centre on land). Every CBS cell code (`E0136N3713` is x 13,600, y 371,300) then marks its cell as inhabited. Small ditches and lakes inside municipal land count as land.

The result is a 0.4 MB GeoTIFF (`data/nobody.tif`), drawn with `annotation_raster`.
