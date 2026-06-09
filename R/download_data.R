# Download Placencia mangrove field data from Google Sheets before rendering.
sheet_id <- "14LuCtodKnOIlNhZ7m3mE5Six7Qu6T-Sr"
export_url <- sprintf(
  "https://docs.google.com/spreadsheets/d/%s/export?format=xlsx",
  sheet_id
)

dest_dir <- "data"
dest_file <- file.path(dest_dir, "Placencia_mangroves_2025.xlsx")

dir.create(dest_dir, recursive = TRUE, showWarnings = FALSE)

message("Downloading mangrove data to ", dest_file, " ...")
download.file(export_url, destfile = dest_file, mode = "wb", quiet = TRUE)
message("Done (", file.info(dest_file)$size, " bytes).")
