
#' Estima a tendencia e o ciclo com modelo estrutural de componentes nao observados
#' 
#' Estima o modelo de componentes nao observaveis de Wang(2010) para obter a tendencia
#' e ciclo por maxima expectancia (EM) usando o pacote "MARSS"
#' 
#' @param x um objeto ts com a serie temporal 
#' @param init valores iniciais da matriz de variancia dos estados, tendencia, ar1, ar2, tx crescimento.
#' @param model Model 0 general model, Model 1 where restrictions gc=0 and lambda=1 are imposed,
#' In Model 2, the mean value of the growth rate is simply gc. 
#' @param ... Optional arguments passed to function MARSS by control 
#' 
#'
#' @return objeto da classe ucwang uma lista contendo o objeto retornado 
#' pela funcao (\link[MARSS]{MARSS}) e os dados x
#' 
#' @references WANG, P. An examination of business cycle features in UK Sectoral Output. Applied Economics, v. 42, n. 25, p. 3241–3252, 2010. 
#' 
#' @import MARSS
#' @importFrom stats time
#' 
#' @export
#'       


ucwang <- function(x, init = c(1, 0.5, 0.2, 0.1, 0.1), model = 0, ...){
  requireNamespace("MARSS")
  Z=matrix(c(1, 1, 0, 0),1,4)
  A=matrix(0,1,1)
  R=matrix(0,1,1)
  if(model ==0){
    U=matrix(list(0,0,0,"gc"),4,1)
    B=matrix(list(1, 0, 0, 1, 
                  0, "phi1", "phi2", 0, 
                  0, 1, 0, 0, 
                  0, 0, 0, "lambda"),4,4, byrow = T)
    Q=matrix(list(0),4,4); diag(Q)=list("sigma2u","sigma2v", 0, "sigma2w")
  }
  if(model == 1){
    U=matrix(list(0,0,0, 0),4,1)
    B=matrix(list(1, 0, 0, 1,
                  0, "phi1","phi2", 0, 
                  0, 1, 0, 0, 
                  0, 0, 0, 1),4,4, byrow = T)
    Q=matrix(list(0),4,4); diag(Q)=list("sigma2u","sigma2v", 0, "sigma2w")
  }
  if(model == 2){
    U=matrix(list(0,0,0,"gc"),4,1)
    B=matrix(list(1, 0, 0, 1, 
                  0, "phi1","phi2", 0, 
                  0, 1, 0, 0,
                  0, 0, 0, 0),4,4, byrow = T)
    Q=matrix(list(0),4,4); diag(Q)=list("sigma2u","sigma2v", 0, 0)
  }
  x.init <- c(median(x[1:5]), x[2:1], mean(diff(x)))
  x0=matrix(x.init,4,1)
  V0=diag(init, 4)
  model.gen=list(Z=Z,A=A,R=R,B=B,U=U,Q=Q,x0=x0,V0=V0,tinitx=1)
  # dados no formato aceito
  dat=t(as.matrix(x))
  colnames(dat) <- time(x)
  cntl.list=list(safe=TRUE, ...)
  TT <- length(x)
  
  kemfit = MARSS(dat[2:TT], model=model.gen, control=cntl.list, method="kem")
  y <- list(kemfit=kemfit, data=x)
  class(y) <- "ucwang"
  return(y)
}

#' Tabela resumo do modelo ucwang estimado 
#' 
#' Fornece a tabela resumo do coeficientes estimados por \link[mecnost]{ucwang}
#' 
#' @param x An object of class \link[mecnost]{ucwang}
#' 
#' @return Uma tabela com os coeficientes estimados
#' 
#' @import MARSS
#' @importFrom stats qt
#'  
#' @export
#'   

tab.ucwang <- function(x){
  requireNamespace("MARSS")
  pars <- MARSSparamCIs(x$kemfit)
  coefi <- rbind(pars$par$Z, pars$par$A, pars$par$R, pars$par$B, 
                pars$par$U, pars$par$Q, pars$par$x0, pars$par$V0)
  se <- cbind(unlist(pars$par.se))
  
  stat <- coefi/se
  cval <- qt(c(0.90, 0.95, 0.99), df=pars$samp.size)
  id <- apply(stat, 1, sig, cval=cval)
  coefi <- num2tab(coefi)
  se <- num2tab(se)
  tab <- cbind(names(coefi),paste0(coefi, " (", se, ")", id))
  tab <- rbind(tab, 
               c("Log-verossimilhanca", num2tab(pars$logLik, dig = 2)))
  colnames(tab)<-c("Coeficientes", "Estimativas")
  return(tab)
}

#' Plot components from ucwang model
#' 
#' Produces a plot of the trend, cycle 
#' and grow components from an uc wang model.
#' 
#' @param object Object of class "ucwanf"
#' 
#' @return None. Function produces a plot
#' 
#' @import zoo
#' 
#' @export
#' 


autoplot.ucwang <- function(object){
  requireNamespace("zoo")
  x <- object$kemfit
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is needed for this function to work. Install it via install.packages(\"ggplot2\")", 
         call. = FALSE)
  }else {
    if (!inherits(object, "ucwang")){
      stop("autoplot.ucwang requires an ucwang object, use object=object")
    }
  }
  idtime <- as.numeric(colnames(x$marss$data))
  y <- zoo(t(x$marss$data), order.by = idtime)
  states <- zoo(t(x$states[c(1,2,4),]), order.by = idtime)
  colnames(states) <- c("Tendencia", "Ciclo", "Taxa de Cresc.")
  tsplot(x = states, y=cbind(y,NA,NA))
}


