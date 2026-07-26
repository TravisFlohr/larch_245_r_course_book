#########################################################################
# Project: Larch 245
# Script: 00_classroom_map.r
# Author: Travis Flohr, Ph.D.
# Date: 2026-07-06
# Version: v1.0
#
# Purpose:
#   Create an interactive map for the classroom location 
#
# Inputs:
#   - df_buildings
#       Create a dataframe a the top of the code.
#
# Outputs:
#   - map_classroom
#       Outputs an interactive map that shows the classroom and Stuckeman.
#
# Dependencies:
#   - R version: 4.5.1
#   - Packages:
#       * leaflet
#       * leaflet.providers
#       * leaflet.extras
#       * leafletem
#
# Notes:
#   - This script uses base R pipe syntax (|>).
#
#########################################################################

# 0. load libraries
library(leaflet)           # is one of the most popular open-source JavaScript libraries for interactive maps.
library(leaflet.providers) # provides updates on third-party tile providers supported by leaflet.
library(leaflet.extras)    # extra Functionality for 'leaflet' Package.
library(leafem)            # uses the leaflet plugin 'georaster-layer-for-leaflet' to render raster data.

# 1 Create a data frame with the coordinates and names
df_buildings <- data.frame(
  name = c("Stuckeman Family Building", "Chemical and Biomedical Engineering"),
  lat = c(40.801212, 40.801073235820574),
  lng = c(-77.866481, -77.86268833309923))

# create map
map_classroom <- leaflet(df_buildings,
                        height = 500,
                        width = 1000) |>
  
  #basetiles
  addTiles(group = "Positron (default)") |>
  addProviderTiles(providers$CartoDB.Positron, group = "Positron (default)") |>
  setView(lng= -77.8646, lat = 40.801197, zoom = 17) |>
  addResetMapButton() |>

  addProviderTiles(providers$Esri.WorldImagery, group = "ESRI World Imagery") |> 
  addProviderTiles(providers$Esri.WorldStreetMap, group = "ESRI Street Map") |> 

  addMarkers(
    lng = ~lng, 
    lat = ~lat, 
    label = ~name, # Hover text
    popup = ~name ) |>  # Click text 

# layer controls
  addLayersControl(
    baseGroups = c("Positron (default)", "ESRI World Imagery", "ESRI Street Map"),
    options = layersControlOptions(collapsed = TRUE)
  )
# print map
map_classroom