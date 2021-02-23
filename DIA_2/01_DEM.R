#'@author  Miguel Angel Garcia Tito
#'Correo: garciatitomiguel@gmail.com
#'
rm(list = ls())

# Instalando librerias ----------------------------------------------------

# install.packages('mapedit', dependencies = T)
# install.packages('ggplot2', dependencies = T)
# install.packages('tidyverse', dependencies = T)
# install.packages('dplyr', dependencies = T)
# install.packages('raster', dependencies = T)
# install.packages('sf', dependencies = T)
# install.packages('xts', dependencies = T)
# install.packages('ggpubr', dependencies = T)
# install.packages('ncdf4', dependencies = T)

# Cargando Librerias ------------------------------------------------------

library(rgee)
library(mapedit)
library(ggplot2)
library(tidyverse)
library(dplyr)
library(raster)
library(sf)
library(xts)
library(ggpubr)
library(ncdf4)


# Inicializando GEE -------------------------------------------------------

ee_Initialize('Miguel', drive = T)

#remove.packages('mapedit')

setwd('D:/RGEE/shp/')

roi.area <- editMap()

my.area <- sf_as_ee(roi.area$geometry)

Map$setCenter(-76.99, -12.10, 6)

Map$addLayer(my.area, name = 'area')


# Cargando el Snippet de GEE ----------------------------------------------

# Cargando el DEM SRTM 30m (USGS/SRTMGL1_003) 
# Cargando el DEM MERIT 90m (MERIT/DEM/v1_0_3) 
# Cargando el DEM ALOS DSM 30m (JAXA/ALOS/AW3D30/V3_2) 

dataset <- ee$Image("USGS/SRTMGL1_003")$
  select('elevation')


# Cargando Paletas en R ---------------------------------------------------

Palette <- c('000000', '478FCD', '86C58E', 'AFC35E', '8F7131',
             'B78D4F', 'E2B8A6', 'FFFFFF')

visParams <- list(min = 0, max = 6000, palette = Palette)

Map$addLayer(dataset, visParams, "Elevation")

dem_clip = dataset$clip(my.area)

Map$addLayer(dem_clip, visParams, "Elevation")

## drive - Method 01

img_02 <- ee_as_raster(
  image = dem_clip,
  crs = 'EPSG:32718',
  dsn = 'Miguel/',
  scale = 30,
  maxPixels = 1e13,
  via = 'drive'
)

dem <- raster('Miguel.tif')

plot(dem)


