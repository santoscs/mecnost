### Import data to package


dados <- read.csv2("data-raw/pib-setoriais-valores-de-95-encadeados.csv", dec = ",")
head(dados)

dados <- dados[ ,c("Periodo", "AGROPEC.",	"INDUST.", "Ext.Mineral",	"Transfor.",	"Eletricidade", "Construcao",	"SERVIC.", "Comercio",	"Transporte",	"Serv.infor.",	"Interm.finac.", 	"Ativ.imobili.",	"OutrosServ.",	"Adm.publica")]


pibsetores <- ts(dados[,-1], start = c(1996,1), frequency=4)

plot(log(pibsetores[,1:10]))

devtools::use_data(pibsetores, overwrite = TRUE)



dados <- read.csv2("data-raw/pib-setoriais-valores-de-95-encadeadoos-ajuste-sazonal.csv", dec = ",")
head(dados)

dados <- dados[ ,c("Periodo", "AGROPEC.",	"INDUST.", "Ext.Mineral",	"Transfor.",	"Eletricidade", "Construcao",	"SERVIC.", "Comercio",	"Transporte",	"Serv.infor.",	"Interm.finac.", 	"Ativ.imobili.",	"OutrosServ.",	"Adm.publica")]

pibsetores <- ts(dados[,-1], start = c(1996,1), frequency=4)

plot(log(pibsetores[,1:10]))

devtools::use_data(pibsetores, overwrite = TRUE)


