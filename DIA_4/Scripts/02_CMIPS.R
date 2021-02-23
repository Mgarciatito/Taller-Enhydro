#'@author  Miguel Angel Garcia Tito
#'Correo: garciatitomiguel@gmail.com


# Procesando CMIPS 5 ------------------------------------------------------

rm(list = ls())

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

ee_Initialize('Miguel', drive = T)

setwd('D:/DIA_4/Shp/')

roi.area <- editMap()

my.area <- sf_as_ee(roi.area$geometry) 

Map$addLayer(my.area, name = 'area')

rimac <- ee$FeatureCollection('users/garciatitomiguel/rimac')

Map$setCenter(-76.69, -11.78, 10)

Map$addLayer(rimac, name = 'Cuenca Rimac')


CMIP5 <- ee$ImageCollection('NASA/NEX-GDDP')$
  filterDate("2020-01-01", "2022-12-31")$
  filterMetadata('model', 'equals', 'ACCESS1-0')$
  filterMetadata('scenario', 'equals', 'rcp85')$
  map(function(img){
    date <- ee$Date(img$get('system:time_start'))$format('YYYY_MM_dd')
    name <- ee$String$cat('Rcp85_tmax_', date)
    img$select('tasmax')$reproject('EPSG:4326')$set('RGEE_NAME', name)
  })


# Extract values

ee_nc_rain <- ee_extract(
  x = CMIP5,
  y = my.area,
  scale = 25000,
  fun = ee$Reducer$mean(),
  sf = F
)


# Conversión --------------------------------------------------------------

var <- ee_nc_rain %>% as.tibble() %>% t()

View(var)

var = var[-c(1),]

View(var)

var <- as.numeric(var)

str(var)

celsius <- var - 273.15

view(celsius)

date <- seq(as.Date("2020-01-01"), as.Date("2022-12-30"), by = "day")

tmax <- data.frame(date,celsius)

View(tmax)

summary(tmax$celsius)

# Ploteando Series Chirps -------------------------------------------------

library(ggplot2)

summary(tmax$celsius)

p1 <- ggplot(tmax, aes(x=date, y = celsius))+
  geom_line(color = 'red')+
  geom_point(size = 0.4, colour = 'red')+
  ggtitle('CMIP 5')+
  theme_bw()+
  scale_x_date()+ 
  ylab('Tmax (°C)')+
  scale_y_continuous(breaks = seq(0,28, 2))

