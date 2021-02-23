#Si tengo instalado RGEE 

#remove.packages('rgee')

library(remotes)

install_github("r-spatial/rgee")

rgee::ee_install()

library(rgee)

# library(reticulate)

ee_Initialize()
# ee_install_set_pyenv()
# ee_install()

rm(list=ls())

library(rgee)

library(googledrive)

ee_Initialize('Miguel', drive = T)

createTimeBand <-function(img) {
  year <- ee$Date(img$get('system:time_start'))$get('year')$subtract(1991L)
  ee$Image(year)$byte()$addBands(img)
}

collection <- ee$
  ImageCollection('NOAA/DMSP-OLS/NIGHTTIME_LIGHTS')$
  select('stable_lights')$
  map(createTimeBand)

col_reduce <- collection$reduce(ee$Reducer$linearFit())
col_reduce <- col_reduce$addBands(
  col_reduce$select('scale'))
ee_print(col_reduce)

Map$setCenter(-76.99, -12.10, 12)
Map$addLayer(
  eeObject = col_reduce,
  visParams = list(
    bands = c("scale", "offset", "scale"),
    min = 0,
    max = c(0.18, 20, -0.18)
  ),
  name = "stable lights trend"
)
