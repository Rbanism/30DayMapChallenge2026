# 10Nov_PromptingOnly: How AI sees the Netherlands

An AI coding agent (GitHub Copilot) was asked to write down, from memory and before looking anything up, the latitude and longitude of 25 Dutch cities. The map compares those guesses (orange) with the real coordinates from Wikidata (teal).

The AI knows the Netherlands well. The mean error is **0.5 km**, and Leiden, Rotterdam and Apeldoorn are off by 0 km: the guesses match Wikidata's own coordinates, which are rounded to two decimals. The worst guess is Maastricht at 1.9 km, then 's-Hertogenbosch (1.6 km) and Amsterdam (1.2 km).

To make the errors visible at national scale, the arrows are drawn 25 times longer than the real offsets.

The real lesson: the AI didn't "find" these cities. It remembered the coordinates that sit in Wikipedia and Wikidata infoboxes, rounding included. Asking a model where a city is mostly tests how often its infobox appeared in training data.
