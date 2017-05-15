#' Significancia de um teste
#' 
#' Fornece o valor da estatistica de um teste junto com a indicacao
#' da significancia para valores 10\%, 5\% e 1\%.
#' 
#' @param stat valor da estatistica do teste
#' @param cval vetor com os valores criticos do teste para 10\%, 5\% e 1\%
#' @param comp logical. If TRUE the statistics is print too. FALSE is the default
#' 
#' @return um objeto "character" com valor da estatistica do teste formatado
#' junto com "***" para 1\%, "**" para 5\%, "*" para 10\% e " " nao significativo
#' 
#' @export
#'

sig <- function(stat, cval, comp = FALSE){
  x <- sum(abs(stat)>abs(cval))
  if(x==3) sig <- "***"
  if(x==2) sig <- "** "
  if(x==1) sig <- "*  "
  if(x==0) sig <- "   "
  if(comp){
    return(c(paste(format(round(stat,3), digits = 3, nsmall = 3, decimal.mark=","), sig, sep = "")))
  }else{
    return(sig)
  }
}

#' Formata numeros para tabelas
#' 
#' Formata numeros para tabelas e transforma para notacao centifica caso
#' as seja menor que tres casas decimais
#' 
#' @param num vetor de numeros a serem formatados
#' @param dig quantidade de casas decimais (digitos usados apos a virgula)
#' 
#' @return vetor dos numeros formatos em character
#' 
#' @export
#' 


num2tab<- function(num, dig = 3){
  tab <-apply(as.matrix(num), 1, function(x){
    if(abs(round(x, digits = dig))<1/(10^dig)){
      format(x, nsmall = 2, digits=1, scientific=TRUE, 
             decimal.mark =",", justify = "right")
    }else{
      format(round(x, digits = dig), nsmall = dig, digits=dig, 
             scientific=FALSE, decimal.mark =",", justify = "right")
    }
  })
return(tab)
}

