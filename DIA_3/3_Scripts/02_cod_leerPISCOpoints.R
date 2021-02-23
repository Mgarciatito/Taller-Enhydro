## Leer puntos de estaciones de datos PISCO de prec a partir de 
# puntos de estaciones que estan almacenados en un archivo *.csv
setwd("D:/DIA_3/DIA 3/Datos Grillados/")# Esta es la ruta de la carpeta donde esta Pisco 
# y deben estar el archivo *.csv con los puntos a extraer
# ojo que es  /   no \
# Descargar datos PISCO de: http://www.senamhi.gob.pe/?p=observacion-de-inundaciones
# En la parte inferior ir a la carpeta Datos SONICS (DESCARGAS)
# bajar de preferencia los datos de la carpeta PISCO_v2.0
#ftp://ftp.senamhi.gob.pe/PISCO_v2.0/ ## PISCO_Pd_v2.0 son diarios y
# PISCO_Pm_v2.0 son mensuales
# Este ejemplo es para los datos mensuales PISCOpm.nc
rm(list = ls())
#install.packages("raster")#Instalar el paquete comentar # si ya esta instalado
#install.packages("ncdf4")#Instalar el paquete comentar # si ya esta instalado
library(raster)#cargar el paquete
library(ncdf4)#cargar el paquete
## Leer el archivo long_lat.csv (ver el archivo ejemplo)
## para agregar solo dismnuya o incremente las coordenadas de las filas 
## XX Longitud e YY Latitud
long_lat <- read.csv("6_Insumos/Long_Lat/long_lat.csv", header = T)
### Ensamblamos los datos *.nc
raster_pp   <- raster::brick("1_Datos_Grillados/Precipitacion/Mensual/Prec.nc")
raster_tmax <- raster::brick("1_Datos_Grillados/Temperatura/Mensual/Tmax.nc")
raster_tmin <- raster::brick("1_Datos_Grillados/Temperatura/Mensual/Tmin.nc")
raster_etp  <- raster::brick("1_Datos_Grillados/Evapotranspiracion_odan/Mensual/Evapo.nc")
## Asignamos las coordenadas 
sp::coordinates(long_lat) <- ~XX+YY
# Igualamos las proyecciones del raster y de laos puntos a extraer
raster::projection(long_lat) <- raster::projection(raster_pp)
raster::projection(long_lat) <- raster::projection(raster_tmax)
raster::projection(long_lat) <- raster::projection(raster_tmin)
raster::projection(long_lat) <- raster::projection(raster_etp )
# PRECIPITACION
points_long_lat_pp <- raster::extract(raster_pp[[1]], long_lat, cellnumbers = T)[,1]
data_long_lat_pp <- t(raster_pp[points_long_lat_pp])
colnames(data_long_lat_pp) <- as.character(long_lat$NN)
write.csv(data_long_lat_pp, "2_Resultados/Salida_Pp/Pp.csv", quote = F)
#TEMPERATURA MAXIMA
points_long_lat_tmax <- raster::extract(raster_tmax[[1]], long_lat, cellnumbers = T)[,1]
data_long_lat_tmax <- t(raster_tmax[points_long_lat_tmax])
colnames(data_long_lat_tmax) <- as.character(long_lat$NN)
write.csv(data_long_lat_tmax, "2_Resultados/Salida_Tmax/tmax.csv", quote = F)
#TEMPERATURA MINIMA
points_long_lat_tmin <- raster::extract(raster_tmin[[1]], long_lat, cellnumbers = T)[,1]
data_long_lat_tmin <- t(raster_tmin[points_long_lat_tmin])
colnames(data_long_lat_tmin) <- as.character(long_lat$NN)
write.csv(data_long_lat_tmin, "2_Resultados/Salida_Tmin/tmin.csv", quote = F)
#TEMPERATURA MEDIA
tmedia <- (data_long_lat_tmax+data_long_lat_tmin)/2
write.csv(tmedia, "2_Resultados/Salida_Tmedia/tmedia.csv", quote = F)
#EVAPOTRANSPIRACION
points_long_lat_etp <- raster::extract(raster_etp[[1]], long_lat, cellnumbers = T)[,1]
data_long_lat_etp <- t(raster_etp[points_long_lat_etp])
colnames(data_long_lat_etp) <- as.character(long_lat$NN)
write.csv(data_long_lat_etp, "2_Resultados/Salida_Etp/etp.csv", quote = F)






