# Dissolve sector polygons by region and reproject to WGS84 for the web map.
# Takes data/placencia-sectors.geojson (1115 small polygons), merges them into 3 regions (upper, lower, main creek), reprojects to lat/lon, and writes data/placencia-sectors-map.geojson.
src <- "data/placencia-sectors.geojson"
dest <- "data/placencia-sectors-map.geojson"

if (!file.exists(src)) {
  stop("Missing ", src, ". Add placencia-sectors.geojson to data/ before rendering.")
}

unlink(dest)
status <- system(
  paste(
    "ogr2ogr -f GeoJSON -t_srs EPSG:4326",
    shQuote(dest),
    shQuote(src),
    "-dialect sqlite -sql",
    shQuote('SELECT region, ST_Union(geometry) AS geometry FROM "placencia-sectors" GROUP BY region')
  ),
  ignore.stdout = TRUE,
  ignore.stderr = TRUE
)

if (status != 0 || !file.exists(dest)) {
  stop("ogr2ogr failed while preparing ", dest, ". Is GDAL installed?")
}

message("Wrote ", dest, " (", file.info(dest)$size, " bytes).")
