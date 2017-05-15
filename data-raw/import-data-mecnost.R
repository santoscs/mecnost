### Import data to package


dados <- read.csv2("data-raw/pib-setoriais-valores-de-95-encadeados.csv", dec = ",")
head(dados)

dados <- dados[ ,c("Periodo", "AGROPEC.",	"INDUST.", "Ext.Mineral",	"Transfor.",	"Eletricidade", "Construcao",	"SERVIC.", "Comercio",	"Transporte",	"Serv.infor.",	"Interm.finac.", 	"Ativ.imobili.",	"OutrosServ.",	"Adm.publica")]


pibsetor <- ts(dados[,-1], start = c(1996,1), frequency=4)

plot(log(pibsetor[,1:10]))

devtools::use_data(pibsetor, overwrite = TRUE)



