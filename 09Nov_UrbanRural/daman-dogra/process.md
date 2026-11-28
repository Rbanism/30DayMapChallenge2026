# Process

Cattle come from `cbsodataR::cbs_get_data("80781ned", Perioden = "2025JJ00")`, field `RundveeTotaal_84` (number of animals). The table also has 2026, but there the municipal sum (3,618,920) doesn't match the national figure (3,618,760). Those numbers look provisional, so I used 2025 for everything. Population is `BevolkingOp1Januari_1` from table `03759ned` for 2025, totals over sex, age and marital status. Boundaries are the PDOK CBS gebiedsindelingen 2025 `gemeente_gegeneraliseerd`, joined on `statcode`. All 342 matched, and 13 municipalities have no cattle at all.

A `stopifnot` checks the national totals: 3,643,796 cattle and 18,044,027 people.

The map has seven classes of cows per person, teal for people and purple for cows, with a black outline where the ratio is above 1 and `ggrepel` labels on the top 6. My first try was a continuous log scale centred on 1, but cities go down to 1 cow per 1,000 people while the cow side stops at 6, so the purple hardly showed. Binned classes worked better.

Two small things: `cbs_get_data(select = ...)` fails unless `Perioden` is in the selection, and Baarle-Nassau's figure probably comes from a few very large veal farms in a small municipality.
