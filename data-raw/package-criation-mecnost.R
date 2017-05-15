###############################
## Criando o pacote mecnost ###
###############################

#inicia o pacote
# install.packages("devtools")
devtools::setup(rstudio = FALSE)

#preencher o DESCRIPTION

# cria pasta para dados brutos
devtools::use_data_raw()

#salve este arquivo em data-raw

# Ignora Rproj do Rstudio
devtools::use_build_ignore("mecnost.Rproj")

#Escrevas as funcoes e salve em R

# documenta as funcoes
devtools::document()

# testa o pacote, provavelmente recebera um erro de 
# dependencia
devtools::check()

# coloca as dependencias no pacote
devtools::use_package("zoo")
devtools::use_package("ggplot2")
devtools::use_package("MARSS")
devtools::use_package("grid")
devtools::use_package("stats")
devtools::use_package("reshape2")
devtools::use_package("dplyr")


#Adding `data-raw` to `.Rbuildignore`
devtools::use_build_ignore(c("README.Rmd", "README_files", "README.docx", "README_cache"))




# verifica por erros
devtools::document()
devtools::check()



## instala o pacote 
# instala
devtools::install()
