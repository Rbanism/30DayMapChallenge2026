# Process

The Delft boundary comes from the PDOK CBS gebiedsindelingen 2025 WFS. Buildings come from `osmdata` with `opq(bbox, timeout = 300, out = "meta")` and `add_osm_feature("building")`; `out = "meta"` adds `osm_timestamp`, `osm_user`, `osm_version` and `osm_changeset`. I kept buildings whose centroid lies in Delft and stored only `year` and `osm_user`. Writing the GeoPackage without a spatial index (`SPATIAL_INDEX=NO`) brought it from 10.9 to 8.5 MB. The meta query for about 40k buildings took around 10 minutes because Overpass throttles it.

The map is `geom_sf` with a purple-teal-orange gradient on a dark background. The subtitle computes the most common year, the share edited in the last two years and the top mapper's share.

`osm_timestamp` is the last edit, not the creation date, so one bulk update wipes out the history. To see who first mapped Delft you'd need the full history (`.osh` files or `ohsome`). One user owning 80% of the last edits is normal in the Netherlands, because BAG updates arrive in large semi-automated rounds.
