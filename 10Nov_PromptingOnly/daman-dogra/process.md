# Process

**Prompt 1** (from Daman, to GitHub Copilot, the AI coding agent):

> BEFORE looking anything up, write your own from-memory guesses of the lat/lon of 25 Dutch cities to data\ai_guesses.csv.

The agent picked the 25 cities itself (the 12 provincial capitals plus large or well-known cities) and wrote `data/ai_guesses.csv` in one go, using no tools or lookups, with two decimals each.

**Prompt 2** (same session): get the real coordinates (rnaturalearth populated places or Wikidata) into `data\real.csv`.

Natural Earth only had 14 of the 25 cities, so `map.R` queries Wikidata SPARQL: Dutch-language label, country Netherlands, instance of (a subclass of) city, not dissolved. Querying municipalities instead gave Rotterdam a point in the port and matched a dissolved Middelburg in Zuid-Holland. Duplicates (city and town items) differ by under 100 m; the first is kept.

`map.R` computes geodesic distances with sf. It draws arrows from the guess to the real point, scaled ×25 in EPSG:28992, and labels each city with ggrepel. The outline is the union of the PDOK provinces for 2025.

Learned: a 0.5 km mean error is mostly rounding. A real test would use places the model is unlikely to have memorised.
