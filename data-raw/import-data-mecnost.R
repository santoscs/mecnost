### Import data to package


dados <- read.csv2("data-raw/pib-setoriais.csv")
head(dados)

colnames(dados) <- c("Periodo", "Agropec.",	"Ext.Mineral",	"Transfor.",	"Eletricidade", "Construção",	"Comércio",	"Transporte",	"Serv.infor.",	"Interm.finac.", 	"Ativ.imobili.",	"OutrosServ.",	"Adm.pública")

pibsetor <- ts(dados[,-1], start = c(1996,1), frequency=4)

devtools::use_data(pibsetor, overwrite = TRUE)



