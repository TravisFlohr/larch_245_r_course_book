#########################################################################
# Project: Larch 245
# Script: 03_plant_walk_info.r
# Author: Travis Flohr, Ph.D.
# Date: 2026-07-07
# Version: v1.2
#
# Purpose:
#   Create an interactive map and plant list for each plant walk location
#   and save them for use in a Quarto HTML eBook.
#
# Inputs:
#   - Larch_245_list
#   - Larch_245_locations
#   - .env file containing PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE
#
# Outputs:
#   - data/processed/plant_walk_assets.rds
#########################################################################

# 0. packages ------------------------------------------------------------
required_packages <- c(
  "tidyverse", "stringr", "writexl", "readxl", "sessioninfo",
  "citation", "grateful", "DT", "htmltools", "quarto", "here",
  "DataEditR", "DBI", "RPostgres", "dotenv", "leaflet",
  "leaflet.providers", "leaflet.extras", "leafem", "gt"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, installed)
if (length(to_install) > 0) install.packages(to_install)
invisible(lapply(required_packages, library, character.only = TRUE))

dotenv::load_dot_env()

# 1. load data ------------------------------------------------------------
con <- dbConnect(
  RPostgres::Postgres(),
  host = Sys.getenv("PGHOST"),
  port = as.integer(Sys.getenv("PGPORT")),
  dbname = Sys.getenv("PGDATABASE"),
  user = Sys.getenv("PGUSER"),
  password = Sys.getenv("PGPASSWORD")
)

df_larch_245_walk_list <- dbReadTable(con, "Larch_245_list")
df_larch_245_plant_locations <- dbReadTable(con, "Larch_245_locations")
df_larch_245_common_names <- dbReadTable(con, "Plants4ES_data")
dbDisconnect(con)

# 2. clean / join data ----------------------------------------------------
df_larch_245_common_names <- df_larch_245_common_names |>
  select(GD_Common_name, GD_Scientific_Name) |>
  rename(
    common_name = GD_Common_name,
    scientific_name = GD_Scientific_Name
  ) |>
  mutate(scientific_name = str_squish(scientific_name)) |>
  distinct(scientific_name, .keep_all = TRUE)

# Make sure the coordinate fields are named exactly latitude/longitude
# If your source table already uses these names, this does nothing.
df_larch_245_plant_locations <- df_larch_245_plant_locations |>
  rename(
    latitude = any_of(c("latitude", "Latitude")),
    longitude = any_of(c("longitude", "Longitude"))
  )

df_larch_245 <- df_larch_245_walk_list |>
  mutate(scientific_name = str_squish(scientific_name)) |>
  left_join(df_larch_245_common_names, by = "scientific_name") |>
  left_join(df_larch_245_plant_locations, by = "scientific_name") |>
  filter(Quiz != "None") |>
  mutate(
    Campus_Area = as.character(Campus_Area),
    scientific_name = str_squish(scientific_name)
  ) |>
  arrange(Campus_Area, Plant_Walk_no, scientific_name)

walk_locations <- df_larch_245 |>
  distinct(Campus_Area, Quiz) |>
  filter(!is.na(Campus_Area)) |>
  arrange(Quiz, Campus_Area) |>
  pull(Campus_Area) |>
  unique()

# 3. helper functions -----------------------------------------------------
make_plant_table <- function(dat) {
  dat |>
    mutate(Plant_Walk_no = as.integer(Plant_Walk_no)) |>
    select(scientific_name, common_name, Plant_Walk_no) |>
    distinct() |>
    arrange(Plant_Walk_no, scientific_name) |>
    gt() |>
    tab_header(title = md("**Plant list**")) |>
    cols_label(
      scientific_name = "Scientific name",
      common_name = "Common name",
      Plant_Walk_no = "Walk #"
    ) |>
    fmt_missing(everything(), missing_text = "") |>
    tab_options(table.font.size = px(14),
  table.width = pct(100))
}

# begin map code
make_plant_map <- function(dat) {
  pts <- dat |>
    mutate(latitude = as.numeric(latitude), longitude = as.numeric(longitude)) |>
    filter(!is.na(latitude), !is.na(longitude))

  if (nrow(pts) == 0) {
    return(leaflet(width = "100%", height = 450) |>
             addControl("No coordinates found", position = "topright"))
  }

  leaflet(pts, width = "100%", height = 450) |>
    addTiles(group = "ESRI Street Map (default)") |>
    addProviderTiles(providers$providers$Esri.WorldStreetMap, group = "ESRI Street Map (default)") |>
    setView(
      lng = mean(pts$longitude, na.rm = TRUE),
      lat = mean(pts$latitude, na.rm = TRUE),
      zoom = 18
    ) |>
    addCircleMarkers(
      lng = ~longitude, lat = ~latitude,
      radius = 6, color = "#2c7fb8", fillColor = "#41b6c4",
      fillOpacity = 0.9, popup = ~scientific_name
    ) |>
    addResetMapButton() |>
    addProviderTiles(providers$Esri.WorldImagery, group = "ESRI World Imagery") |> 
  addLayersControl(
    baseGroups = c("ESRI Street Map (default)", "ESRI World Imagery"),
    options = layersControlOptions(collapsed = TRUE)
  )    
}
# end map code

build_walk_assets <- function(loc_name, dat) {
  loc_dat <- dat |> filter(Campus_Area == loc_name)
  list(
    location = loc_name,
    map = make_plant_map(loc_dat),
    table = make_plant_table(loc_dat),
    data = loc_dat
  )
}

# 4. build all location assets -------------------------------------------
walk_assets <- setNames(
  lapply(walk_locations, build_walk_assets, dat = df_larch_245),
  walk_locations
)

# 5. save outputs for Quarto ---------------------------------------------
out_dir <- file.path("data", "processed")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
saveRDS(walk_assets, file.path(out_dir, "plant_walk_assets.rds"))

walk_assets
