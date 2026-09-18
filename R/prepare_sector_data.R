# Derive real per-sector tree data, summary stats, and biomass points from the
# field workbook for the OJS explorer, replacing the old placeholder sector tables.
#
# Sector assignment: biomass_data's station_id -> upper_lower is used as the
# canonical lookup (clean, one row per station, no conflicts) rather than
# Dataset's own upper-lower column (sparse: populated on ~35% of rows, and also
# includes several offshore caye stations outside the three lagoon sectors this
# site maps). Cross-checked: for the 228 Dataset rows that DO have both a
# station_id present in biomass_data and a non-blank upper-lower value, the two
# sheets agree on every row.
library(readxl)
library(dplyr)
library(jsonlite)

src <- "data/Placencia_mangroves_2025.xlsx"
if (!file.exists(src)) {
  stop("Missing ", src, ". Run R/download_data.R first.")
}

sector_labels <- c("Upper" = "upper", "Lower" = "lower", "Main Creeks" = "main creek")

dataset <- suppressMessages(read_excel(src, sheet = "Dataset"))
biomass <- suppressMessages(read_excel(src, sheet = "biomass_data"))

sector_lookup <- biomass %>%
  distinct(station_id, upper_lower) %>%
  mutate(sector = unname(sector_labels[upper_lower])) %>%
  filter(!is.na(sector)) %>%
  select(station_id, sector)

trees <- dataset %>%
  inner_join(sector_lookup, by = "station_id") %>%
  transmute(
    station_id,
    sector,
    species,
    morphotype,
    dbh_cm = `dbh (cm)`,
    height_m = `height (m)`,
    agb_kg = suppressWarnings(as.numeric(`aboveground biomass (kg) per tree`)),
    bgb_kg = suppressWarnings(as.numeric(`Belowground biomass (kg) per tree`)),
    total_biomass_kg = suppressWarnings(as.numeric(`Total biomass per tree`))
  ) %>%
  filter(!is.na(species), !is.na(dbh_cm), !is.na(height_m))

sector_summary <- trees %>%
  group_by(sector) %>%
  summarise(
    n_trees = n(),
    n_stations = n_distinct(station_id),
    n_species = n_distinct(species),
    mean_dbh_cm = mean(dbh_cm),
    sd_dbh_cm = sd(dbh_cm),
    mean_height_m = mean(height_m),
    sd_height_m = sd(height_m),
    total_biomass_kg = sum(total_biomass_kg, na.rm = TRUE),
    .groups = "drop"
  )

species_composition <- trees %>%
  group_by(sector, species) %>%
  summarise(n_trees = n(), .groups = "drop") %>%
  arrange(sector, desc(n_trees))

# biomass_data's own average_agb_per_point/average_bgb_per_point/total_biomass_per_point/
# density columns are corrupted: the sheet's "geometry" column contains an unquoted comma
# (e.g. "c(358951.75, 1843630.99)") that Excel split across two cells, shifting every column
# after it one to the right. lat/long/upper_lower (before the shift) are unaffected, so those
# are used for station coordinates/sector, and point-level biomass is instead computed from
# the already-verified per-tree records above.
biomass_points <- trees %>%
  group_by(station_id, sector) %>%
  summarise(
    n_trees = n(),
    mean_dbh_cm = mean(dbh_cm),
    mean_height_m = mean(height_m),
    total_biomass_kg = sum(total_biomass_kg, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  inner_join(biomass %>% distinct(station_id, lat, long), by = "station_id")

dir.create("data", showWarnings = FALSE)
write_json(trees, "data/dataset.json", auto_unbox = FALSE, na = "null", digits = 4)
write_json(sector_summary, "data/sector-summary.json", auto_unbox = FALSE, na = "null", digits = 4)
write_json(species_composition, "data/species-composition.json", auto_unbox = FALSE, na = "null", digits = 4)
write_json(biomass_points, "data/biomass-points.json", auto_unbox = FALSE, na = "null", digits = 6)

message(
  "Wrote data/dataset.json (", nrow(trees), " trees), ",
  "data/sector-summary.json (", nrow(sector_summary), " sectors), ",
  "data/species-composition.json (", nrow(species_composition), " rows), ",
  "data/biomass-points.json (", nrow(biomass_points), " points)."
)
