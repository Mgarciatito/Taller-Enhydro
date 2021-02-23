#'@author  Miguel Angel Garcia Tito
#'Correo: garciatitomiguel@gmail.com


# Extraccion de series CHIRPS ---------------------------------------------

rm(list = ls())

library(rgee)
library(mapedit)
library(tidyverse)
library(dplyr)
library(raster)
library(sf)
library(xts)
library(ggpubr)
library(ncdf4)

setwd('D:/DIA_4/Shp/')

ee_Initialize('Miguel', drive =T)

# Definiendo serie

Chirps <- ee$ImageCollection("UCSB-CHG/CHIRPS/DAILY") %>%
  ee$ImageCollection$filterDate("1981-01-02", "1985-01-01") %>%
  ee$ImageCollection$map(
    function(x) {
      date <- ee$Date(x$get("system:time_start"))$format('YYYY_MM_dd')
      name <- ee$String$cat("Chirps_pp_", date)
      x$select("precipitation")$reproject('EPSG:4326')$rename(name)
    }
  )


nc <- st_read("Cuenca_Chancay_Huaral_wgs84.shp")

nc <- st_read("Cuenca_Santa_Eulalia_wgs84.shp")

plot(nc, axes =T)

# Extract values

ee_nc_rain <- ee_extract(
  x = Chirps,
  y = nc,
  scale = 5000,
  fun = ee$Reducer$mean(),
  sf = F
)


# Conversión --------------------------------------------------------------

var_pp <- ee_nc_rain %>% as.tibble() %>% t()

View(var_pp)

var_pp = var_pp[-c(1:3),]

View(var_pp)

date <- seq(as.Date("1981-01-02"), as.Date("1984-12-31"), by = "day")

Pp <- data.frame(date,var_pp)

View(Pp)

summary(Pp$var_pp)

Pp$var_pp <- as.numeric(Pp$var_pp)

str(Pp)

view(Pp)


# Ploteando Series Chirps -------------------------------------------------

library(ggplot2)

summary(Pp$var_pp)

p1 <- ggplot(Pp, aes(x=date, y = var_pp))+
  geom_line(color = 'blue')+
  geom_point(size = 0.4, colour = 'blue')+
  ggtitle('Serie Chirps (1981-1985)')+
  theme_bw()+
  scale_x_date()+ 
  ylab('Precipitación (mm)')+
  scale_y_continuous(breaks = seq(0,50, 5))


plot(Pp$var_pp, type = 'l', col = 'Blue', main = 'Time series Chirps',
     xlab = 'dates', ylab = 'pp (mm)')


# Extrayendo series de Terraclimate ---------------------------------------

terraclimate <- ee$ImageCollection("IDAHO_EPSCOR/TERRACLIMATE") %>%
  ee$ImageCollection$filterDate("1970-01-02", "2019-01-01") %>%
  ee$ImageCollection$map(
    function(x) {
      date <- ee$Date(x$get("system:time_start"))$format('YYYY_MM_dd')
      name <- ee$String$cat("Terraclimate_pp", date)
      x$select("pr")$reproject('EPSG:4326')$rename(name)
    }
  )


nc <- st_read("Cuenca_Mantaro_wgs84.shp")

plot(nc, axes =T)

ee_nc_rain <- ee_extract(
  x = terraclimate,
  y = nc,
  scale = 5000,
  fun = ee$Reducer$mean(),
  sf = F
)

# Conversión --------------------------------------------------------------

var_pp <- ee_nc_rain %>% as.tibble() %>% t()

View(var_pp)

var_pp = var_pp[-c(1:2),]

View(var_pp)

head(var_pp)

tail(var_pp)

date <- seq(as.Date("1970-02-01"), as.Date("2018-12-01"), by = "month")

Pp <- data.frame(date,var_pp)

View(Pp)

summary(Pp$var_pp)

Pp$var_pp <- as.numeric(Pp$var_pp)

str(Pp)

view(Pp)


# Ploteando Series Terraclimate --------------------------------------------

library(ggplot2)

summary(Pp$var_pp)

p2 <- ggplot(Pp, aes(x=date, y = var_pp))+
  geom_line(color = 'blue')+
  geom_point(size = 0.4, colour = 'blue')+
  ggtitle('Serie Terraclimate (1970-2019)')+
  theme_bw()+
  scale_x_date()+ 
  ylab('Precipitación (mm)')+
  scale_y_continuous(breaks = seq(0,1200, 100))


plot(Pp$var_pp, type = 'l', col = 'Blue', main = 'Time series',
     xlab = 'dates', ylab = 'pp (mm)')


# Visualizando Chirps -----------------------------------------------------

roi.area <- editMap()

my.area <- sf_as_ee(roi.area$geometry)

Map$addLayer(my.area, name = 'area')


collection <- ee$ImageCollection('UCSB-CHG/CHIRPS/DAILY')$
  select('precipitation')$
  filterBounds(my.area)$
  filterDate('2020-01-01', '2020-10-30')

mediana <- collection$sum()

area.estudio <- mediana$clip(my.area)

Palette <- c('#ffffcc','#a1dab4','#41b6c4','#2c7fb8','#253494')

visParams <- list(min = 0, max = 3000, palette = Palette)

Map$addLayer(area.estudio, visParams, "Chirps")


# Muchas gracias por su atención :3 ---------------------------------------
