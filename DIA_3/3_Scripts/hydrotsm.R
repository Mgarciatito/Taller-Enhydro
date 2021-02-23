rm(list = ls())
setwd('D:/DIA_3/DIA 3/Datos Grillados/')
library(xts) #para manejar series de tiempo

data <- as.xts(read.zoo("6_Insumos/Pre_practica/Pp_practica.csv", header = TRUE 
                        ,sep = ",",
                        format = "%d/%m/%Y",check.names = FALSE))

library(hydroTSM)

hydroplot(as.zoo(data[,6]), var.type="Precipitation", pfreq = "dma", ylab = "Prec")
