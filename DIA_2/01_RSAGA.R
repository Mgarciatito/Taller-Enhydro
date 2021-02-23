
# RSAGA -------------------------------------------------------------------

#'@author  Miguel Angel Garcia Tito
#'Correo: garciatitomiguel@gmail.com

library(raster)
library(RSAGA)
library(sf)
library(latticeExtra)
library(sp)
library(tidyverse)
library(dplyr)
library(rgdal)
rm(list = ls())

setwd('D:/RGEE/ENHYDRO/Taller/')

# Iniciando ---------------------------------------------------------------

dem <- raster("DEM_LURIN.tif")

projection(dem)

cuencas <- shapefile('Cuencas_hidrograficas.shp')

view(cuencas)

shp <- cuencas[cuencas$NOMBRE %in% c("Cuenca Rímac", "Cuenca Lurín",
                                     "Cuenca Chillón"), ]

repro <- sp::spTransform(shp, crs(dem))

plot(repro, axes =T, col = 'blue', main = 'CHIRILU')

sp::spplot(repro[1:6],colorkey = FALSE, main =' Cuencas')

writeOGR(repro, '.', layer = 'chirulu', driver="ESRI Shapefile") 

zona_estudio <- st_read("chirulu.shp") 

plot(dem)

spplot(dem, col.regions=terrain.colors(255))

spplot(as(zona_estudio[1], "Spatial"), fill="transparent", col="black",
       under = FALSE)+ as.layer(spplot(dem, col.regions=terrain.colors(255)))


# Explorando SAGA desde R -------------------------------------------------


# tener instalado saga 2.3.1 de preferencia#

env <- rsaga.env(path = 'C:/Program Files (x86)/SAGA-GIS2.3.1/')

env

libs <- rsaga.get.libraries(path = env$modules)

libs

mod <- rsaga.get.modules(libs = 'ta_channels', env = env)

rsaga_mod <- rsaga.get.modules(libs = libs, env = env) %>% 
  bind_rows(.id = 'librerias') %>% as_tibble()

# Solo visualizamos las 10 primeras filas de toda la tabla

head(rsaga_mod,10)

rsaga.fill.sinks(in.dem = 'DEM_LURIN.tif',
                 out.dem = 'Salida/DEM_fill', env = env)

rsaga.slope.asp.curv(in.dem = 'Salida/DEM_fill.sdat',
                     out.slope = 'Salida/pendiente',
                     out.aspect = 'Salida/aspecto',
                     out.cgene = 'Salida/curvatura',
                     unit.slope = 1,
                     unit.aspect = 1,
                     method = 'maxslope', env = env)


raster('Salida/pendiente.sdat') %>% spplot()

raster('Salida/aspecto.sdat') %>% spplot()

raster('Salida/curvatura.sdat') %>% spplot()

rsaga.hillshade(in.dem="Salida/DEM_fill.sdat",
                out.grid="Salida/hillshade",env = env )

raster('Salida/hillshade.sdat') %>% spplot( )


# Delimitacion de cuencas -------------------------------------------------

rsaga.get.modules("ta_hydrology",env = env)

rsaga.get.usage("ta_hydrology",0,env = env) 

rsaga.get.usage("ta_hydrology","Catchment Area (Parallel)",env = env)

# Delimitando el flujo de direccion

rsaga.topdown.processing(in.dem = "Salida/DEM_fill.sdat", out.carea = "carea",  
                         method="mfd",env = env)

raster('carea.sdat') %>% spplot()

rsaga.get.modules("ta_channels",env = env)

rsaga.get.usage("ta_channels","Channel Network",env = env)

#El init value define la red de drenaje que se usara para delimitar las cuencas
#800000000 para lurin
#Recomiendo 5000000 para unidades menores

rsaga.geoprocessor("ta_channels",0,list(ELEVATION="Salida/DEM_fill.sgrd",
                                        CHNLNTWRK="Salida/channel_net.sdat",
                                        CHNLROUTE="Salida/route.sdat",
                                        SHAPES='Salida/channel_net.shp',
                                        INIT_GRID="carea.sgrd",
                                        INIT_METHOD= 2,INIT_VALUE=5000000),
                   env = env)


channel <- st_read("Salida/channel_net.shp")

spplot(as(channel, "Spatial"), "Order")


rsaga.get.usage("ta_channels","Watershed Basins",env = env)

rsaga.geoprocessor("ta_channels",1,list(ELEVATION="Salida/DEM_fill.sgrd", 
                                        CHANNELS="Salida/channel_net.sgrd", 
                                        BASINS="Salida/basin.sgrd",
                                        MINSIZE=100),env = env)

raster("Salida/basin.sdat") %>% spplot()

rsaga.get.usage('ta_hydrology', 4,env = env)

rsaga.geoprocessor(lib = 'shapes_grid', 6,
                   param = list(GRID = 'Salida/basin.sgrd',
                                POLYGONS = 'Salida/boundary.shp')
                   ,env = env)

basin <- shapefile("Salida/boundary.shp")
plot(basin)

proj4string(basin) <- CRS("+proj=utm +zone=18 +south 
                          +datum=WGS84 +units=m +no_defs")

writeOGR(basin, '.', layer = 'microcuencas', driver="ESRI Shapefile") 

spplot(basin[1])


# Delimitando solo la Cuenca en base a un punto ---------------------------

rsaga.geoprocessor(lib = 'ta_hydrology',module = 4,
                   param = list(ELEVATION = 'Salida/DEM_fill.sdat',
                                TARGET_PT_X = 293505,
                                TARGET_PT_Y = 8642175,
                                AREA = 'Salida/CH_area',
                                METHOD = 0),
                   env = env)

raster('Salida/CH_area.sdat') %>% spplot()

rsaga.geoprocessor(lib = 'shapes_grid',module = 6,
                   list(GRID = 'Salida/CH_area.sdat',
                        POLYGONS = 'Salida/Cuenca_Lurin'), env = env
)


basin <- shapefile("Salida/Cuenca_Lurin.shp")

proj4string(basin) <- CRS("+proj=utm +zone=18 +south +datum=WGS84 
                          +units=m +no_defs")

writeOGR(basin, '.', layer = 'Cuenca_lurin_UTM',
         driver="ESRI Shapefile") 

lurin <- basin[basin$ID %in% c("1"), ]

plot(lurin, axes =T)

writeOGR(lurin, '.', layer = 'Cuenca_lurin_UTM2',
         driver="ESRI Shapefile") 

plot(dem)

plot(basin, add=T) 

rsaga.geoprocessor(lib = 'ta_channels',module = 5,
                   param = list(DEM = 'Salida/DEM_fill.sdat',
                                ORDER = 'Salida/Strahler_order',
                                SEGMENTS = 'Salida/red_drenaje'),
                   env = env)

rios <- shapefile("Salida/red_drenaje.shp")

proj4string(rios) <- CRS("+proj=utm +zone=18 +south 
                         +datum=WGS84 +units=m +no_defs")

writeOGR(rios, '.', layer = 'rios_UTM_final', driver="ESRI Shapefile") 

plot(rios, add = T, col = 'blue')

dem_corregido <- raster('Salida/DEM_fill.sdat') 

proj4string(dem_corregido) <- proj4string(lurin)

corte <- mask(dem_corregido, lurin)

spplot(corte)

plot(corte, axes =T)


# Creando curvas de nivel

rsaga.contour(in.grid = "Salida/DEM_fill.sdat",
              out.shapefile = "Salida/contour",
              zstep = 500 , env = env)

curvas <- shapefile("Salida/contour.shp")

proj4string(curvas) <- CRS("+proj=utm +zone=18 +south 
                         +datum=WGS84 +units=m +no_defs")

writeOGR(curvas, '.', layer = 'Curvas_nivel', driver="ESRI Shapefile") 


spplot(curvas[2])

area(lurin)/1000000

library(rgeos)
library(ggspatial)

map <- sf::st_read('Cuenca_lurin_UTM.shp')


rios <- sf::st_read('rios_UTM_final.shp')

var <- sf::st_crop(rios, map)

?st_crop

st_write(var, 'rios_cortados.shp', delete_layer = T)

shapefile('rios_cortados.shp') %>% plot(col = 'blue') 

plot(var)
plogis(map)
spplot(var[1])

plot(map)
plot(rios)

ggplot(map) + geom_sf()+
  xlab("Este") + ylab("Norte") +
  ggtitle("Cuenca Lurín") +
  theme_bw() 


# Mapas Interactivos ------------------------------------------------------

sheed <- read_sf("Cuenca_lurin_UTM2.shp")

colnames(sheed)

library(leaflet)

sheed <- sheed %>% st_transform (crs = 4326)

leaflet(sheed) %>% addTiles() %>% addPolygons()

nc <- st_read("Salida2_Cuenca_lurin_UTM.shp")

plot(nc)

library(mapedit)

library(rgee)

ee_Initialize('Miguel', drive = T)

my.area <- sf_as_ee(nc$geometry)

Map$addLayer(my.area, name = 'area')

 
# Graficando Curva Hipsometrica -------------------------------------------

pross <- as(corte, 'SpatialGridDataFrame')

library(hydroTSM)

hypsometric(pross, main = 'Curva Hipsometrica Lurin')

# Visualización en 3D -----------------------------------------------------

#install.packages("rasterVis", dependencies = T)

library(rasterVis)

plot3D(corte, zfac = 0.5, useLegend =T, adjust = T)


# Buenas Noches :3 --------------------------------------------------------


