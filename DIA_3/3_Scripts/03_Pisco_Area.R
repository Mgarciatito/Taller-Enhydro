rm(list = ls())
setwd("D:/DIA_3/DIA 3/Datos Grillados/7_Pisco_Area/")

#install.packages("ncdf4") 
#install.packages("raster") 

library(ncdf4)# library(raster)
library(raster)

Pisco.prec.brick <- brick("Prec.nc")# leer netcdf con brick 

#Pisco.prec.brick # Enero de 1981 hasta dic 2016
nlayers(Pisco.prec.brick)
spplot(Pisco.prec.brick[[1:12]]) 

# Extraer los valores prec. promedio areal para el Mantaro
###Leemos el shape de mantaro
#install.packages("rgdal")

library(rgdal)

cuenca.wgs <- readOGR(dsn=".", layer="Santa")

plot(cuenca.wgs)

pp.cuenca.mensual <- extract(Pisco.prec.brick, cuenca.wgs, fun=mean) 

row.names(pp.cuenca.mensual) <- cuenca.wgs@data$NOMB_UH_N4

View(pp.cuenca.mensual)

range(pp.cuenca.mensual)#minimo y maximo

plot(pp.cuenca.mensual[1,], type="l", col="blue", ylim=c(0,250), ylab="Prec. [mm]",
     xlab = "Meses", main="Prec. prom areal - santa [mm]")

write.csv(t(pp.cuenca.mensual),'santa.csv')
