#'@author  Miguel Angel Garcia Tito
#'Correo: garciatitomiguel@gmail.com


# EXTRA DE NDVI -----------------------------------------------------------

rm(list = ls())

library(sf)

library(rgee)

ee_Initialize('Miguel', drive = T)

# Cargando Asset  -------------------------------------------------

fromFT <- ee$FeatureCollection("users/garciatitomiguel/rimac")

Map$addLayer(fromFT, name = 'Rimac')

##Para cargar una geometria desde mapedit

library(mapedit)

roi.area <- editMap()

my.area <- sf_as_ee(roi.area$geometry)

Map$addLayer(my.area, name = 'area')

# DEMS --------------------------------------------------------------------

dem_catalogo <- ee$Image('USGS/SRTMGL1_003')

elevation <-  dem_catalogo$select('elevation')

dem <- elevation$clip(fromFT)

slope <- ee$Terrain$slope(dem)

aspect <-  ee$Terrain$aspect (dem)

# Create a custom elevation palette from hex strings.

elevationPalette <- c("006600", "002200", "fff700", "ab7634", "c4d0ff",
                      "ffffff")

# Use these visualization parameters, customized by location.

visParams <- list(min = -800, max = 9000, palette = elevationPalette)

Map$addLayer(dem, visParams, "DEM")

# Vamos a ponernos un poco mas serios -------------------------------------

start <- ee$Date("2020-01-01")

finish <- ee$Date("2020-12-31")

point <- ee$Geometry$Point(-76.70, -11.8)

filteredCollection <- ee$ImageCollection("LANDSAT/LC08/C01/T1_SR")$
  filterDate(start, finish)$
  filterMetadata('CLOUD_COVER', 'less_than', 20)

# Define visualization parameters in an object literal.

vizParams <- list(
  bands = c("B6", "B5", "B4"),
  min = 1000,
  max = 5000
)

mediana <- filteredCollection$median() 

Map$addLayer(mediana, vizParams, "Landsat 8")

area.estudio <- mediana$clip(fromFT)

imagen.area <- area.estudio$divide(10000)

vizParams2 <- list(
  bands = c("B6", "B5", "B4"),
  min = 0,
  max = 0.5
)

Map$setCenter(-76.70, -11.8, 10)

Map$addLayer(imagen.area, vizParams2, "Landsat 8")

ndvi <-  imagen.area$normalizedDifference(c('B5', 'B4'))$rename('NDVI')

ndviParams <- list(palette = c(
  "#d73027", "#f46d43", "#fdae61", "#fee08b",
  "#d9ef8b", "#a6d96a", "#66bd63", "#1a9850"
))

Map$addLayer(ndvi, ndviParams, "NDVI")

Map$addLayer(imagen.area, vizParams2, "Landsat 8")+
  Map$addLayer(ndvi)


# Descargando  ------------------------------------------------------------

setwd('D:/DIA_4/')

geometria <- ndvi$geometry()

ndvi_desc <- ee_as_raster(
  image = ndvi,
  dsn = 'Miguel2/',
  scale = 900,
  maxPixels = 1e13,
  via = 'drive'
)


library(raster)

dem <- raster('Miguel2-0001.tif')

plot(dem)

shp <- shapefile('Shp/Cuenca_rimac_wgs84.shp')

corte <- crop(dem, shp)

plot(corte)

cor2 <- mask(corte, shp)

plot(cor2)

imagen_desc <- ee_as_raster(
  image = imagen.area,
  crs = 'EPSG:32718',
  dsn = 'Miguel_L8/',
  scale = 30,
  maxPixels = 1e13,
  via = 'drive'
)

# Buenas noches :3 --------------------------------------------------------
