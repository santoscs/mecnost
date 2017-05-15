#' Modelo estrutural tendencia e ciclo bayesiano
#' 
#' 
#' Estima o modelo estutrural de componentes nao observados para
#' a tendencia estocastica e ciclo (gap) estacionario de forma 
#' bayesiana com MCMC e Gibbs sample. Para detalhes ver secao 4.6.1 
#' de Petris e Petrone (2009).
#' 
#' @param y data vector or univariate time series
#' @param a.theta prior mean of system precisions (recycled, if needed)
#' @param b.theta prior variance of system precisions (recycled, if needed)
#' @param dV the variance, or the diagonal elements of the variance 
#' matrix in the multivariate case, of the observation noise. 
#' V is assumed to be diagonal and it defaults to zero
#' @param m0 the expected value of the pre-sample state vector
#' @param C0 the variance matrix of the pre-sample state vector
#' @param n.sample requested number of Gibbs iterations
#' @param thin discard thin iterations for every saved iteration
#' @param save.states should the simulated states be included in the output?
#' 
#' @return a list of Markov chain Monte Carlo (MCMC) simulated values.
#'  \item{phi}{simulated values of the AR parameter}
#'  \item{vars}{simulated values of the unknown variance}
#'  \item{theta}{simulated values of the state vectors}
#'   
#' @references PETRIS, G.; PETRONE, S.; CAMPAGNOLI, P. 
#' Dynamic Linear Models with R. New York: Springer Science, 2009. 
#' 
#' @importFrom dlm arms dlmFilter dlmBSample dlmModPoly dlmModARMA dlmLL
#' @importFrom stats rgamma dnorm
#' @export
#' 

btcmodel <- function(y, a.theta, b.theta, dV = 1e-7, m0 = rep(0,4),
                     C0 = diag(x=c(rep(1e7,2), rep(1,2))),
                     n.sample = 1, thin = 0, save.states = FALSE)
{
  mod <- dlmModPoly(2, dV = dV, dW = rep(1,2)) +
    dlmModARMA(ar = rep(0,2), sigma2 = 1)
  #mod$m0 <- m0
  level0 <- y[1]
  slope0 <- mean(diff(y))
  mod$m0 <- c(level0, slope0, slope0, slope0)
  mod$C0 <- C0
  p <- 4 # dim of state space
  r <- 3 # number of unknown variances
  nobs <- NROW(y)
  if ( is.numeric(thin) && (thin <- as.integer(thin)) >= 0 )
  {
    every <- thin + 1
    mcmc <- n.sample * every
  }
  else
    stop("\"thin\" must be a nonnegative integer")
  ## check hyperpriors for precision(s) of 'theta'
  msg4 <- paste("Either \"a.theta\" and \"b.theta\" or \"shape.theta\"",
                "and \"rate.theta\" must be specified")
  msg5 <- "Unexpected length of \"shape.theta\" and/or \"rate.theta\""
  msg6 <- "Unexpected length of \"a.theta\" and/or \"b.theta\""
  if (is.null(a.theta))
    if (is.null(shape.theta)) stop(msg4)
  else
    if (is.null(rate.theta)) stop(msg4)
  else
  {
    ## check length of shape.theta and rate.theta
    if (!all(c(length(shape.theta), length(rate.theta)) %in% c(1,r)))
      warning(msg5)
  }
  else
    if (is.null(b.theta)) stop(msg4)
  else
  {
    if (!all(c(length(a.theta), length(b.theta)) %in% c(1,r)))
      warning(msg6)
    shape.theta <- a.theta^2 / b.theta
    rate.theta <- a.theta / b.theta
  }
  shape.theta <- shape.theta + 0.5 * nobs
  theta <- matrix(0, nobs + 1, p)
  if ( save.states )
    gibbsTheta <- array(0, dim = c(nobs + 1, p, n.sample))
  gibbsPhi <- matrix(0, nrow = n.sample, ncol = 2)
  gibbsVars <- matrix(0, nrow = n.sample, ncol = r)
  AR2support <- function(u)
  {
    ## stationarity region for AR(2) parameters
    (sum(u) < 1) && (diff(u) < 1) && (abs(u[2]) < 1)
  }
  ARfullCond <- function(u)
  {
    ## log full conditional density for AR(2) parameters
    mod$GG[3:4,3] <- u
    -dlmLL(y, mod) + sum(dnorm(u, sd = c(2,1) * 0.33, log=TRUE))
  }
  it.save <- 0
  for (it in 1:mcmc)
  {
    ## generate AR parameters
    mod$GG[3:4,3] <- arms(mod$GG[3:4,3],
                          ARfullCond, AR2support, 1)
    ## generate states - FFBS
    modFilt <- dlmFilter(y, mod, simplify=TRUE)
    theta[] <- dlmBSample(modFilt)
    ## generate W
    theta.center <- theta[-1,-4,drop=FALSE] -
      (theta[-(nobs + 1),,drop=FALSE] %*% t(mod$GG))[,-4]
    SStheta <- drop(sapply( 1 : 3, function(i)
      crossprod(theta.center[,i])))
    diag(mod$W)[1:3] <-
      1 / rgamma(3, shape = shape.theta,
                 rate = rate.theta + 0.5 * SStheta)
    ## save current iteration, if appropriate
    if ( !(it %% every) )
    {
      it.save <- it.save + 1
      if ( save.states )
        gibbsTheta[,,it.save] <- theta
      gibbsPhi[it.save,] <- mod$GG[3:4,3]
      gibbsVars[it.save,] <- diag(mod$W)[1:3]
    }
  }
  if(save.states){
    btcmodel <- list(n.sample=n.sample, y=y, phi = gibbsPhi, 
                     vars = gibbsVars, theta = gibbsTheta)
  }else{
    btcmodel <- list(n.sample=n.sample, y=y, phi = gibbsPhi, 
         vars = gibbsVars)
  }
  class(btcmodel)<-"btcmodel"
  return(btcmodel)
}


# retorna a tendencia , ciclo e crescimento estimados


#' Components of btc model
#' 
#' Extract trend, cycle and grow components estimated from an btcmodel.
#' 
#' @param object Object of class "btcmodel"
#' @param discarding percent for first part of the simulated chain
#' as burn in
#' 
#' @return an ts object with trend, cycle and grow components estimated
#' 
#' @importFrom stats ts tsp
#' 
#' @export
#' 

stimated.btcmodel <- function(object, discarding = 0.05){
  burn <- 1:ceiling(discarding*object$n.sample)
  x <- apply(object$theta[, ,-burn ], 1:2, mean)[-1,1:3]
  y <- object$y
  x <- ts(x, start=tsp(y)[1], frequency = tsp(y)[3])
  colnames(x) <- c("Tendencia", "Tx. de Cresc.", "Ciclo (gap)")
  return(x)
}

# funcao diagnostico
# media egortica e acf





# funcao plot estatos
#' Plot components for btc model
#' 
#' Produces a plot of the trend, cycle 
#' and grow components from an btcmodel.
#' 
#' @param object Object of class "btcmodel"
#' @param discarding percent for first part of the simulated chain
#' as burn in
#' @param title The main title (on top) 
#' 
#' @return None. Function produces a plot
#' 
#' @importFrom stats ts tsp
#' @importFrom ggplot2 autoplot
#' 
#' @export
#' 


autoplot.btcmodel <- function(object, discarding=0.05, title=NULL){
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("ggplot2 is needed for this function to work. Install it via install.packages(\"ggplot2\")", 
         call. = TRUE)
  }else {
    if (!inherits(object, "btcmodel")){
      stop("autoplot.btcmodel requires an btcmodel object")
    }
  }
  y <- object$y
  x <- stimated.btcmodel(object, discarding)
  g <- tsplot(x = x[, c("Tendencia", "Ciclo (gap)", "Tx. de Cresc.")],
         y=cbind(y,NA,NA), title = title)
  return(g)
}


# funcao tabela parametros

#' Tabela resumo  btcmodel 
#' 
#' Fornece a tabela resumo do coeficientes estimados por \link[mecnost]{btcmodel}
#' 
#' @param x An object of class \link[mecnost]{btcmodel}
#' @param discarding percent for first part of the simulated chain
#' as burn in
#' 
#' @return Uma tabela com as colunas
#' \item{Estimativas}{means of a matrix of simulated values}
#' \item{Desvio padrao}{estimate of the Monte Carlo standard deviation, obtained
#' using Sokal’s method}
#' \item{quantil 5}{0.05 quantiles of simulated values}
#' \item{quantil 95}{0.95 quantiles of simulated values}
#' 
#' @importFrom dlm mcmcMeans 
#' @importFrom stats quantile 
#'  
#' @export

tab.btcmodel <- function(x, discarding=0.05){
  burn <- 1:ceiling(discarding*x$n.sample)
  pars <- cbind(mcmcMeans(x$phi[-burn,]), 
                mcmcMeans(sqrt(x$vars[-burn,])))
  ic <- cbind(apply(x$phi[-burn,], 2, quantile, probs = c(.05,.95)),
              apply(sqrt(x$vars[-burn,]), 2, quantile, probs = c(.05,.95)))
  pars <- apply(pars, 2, num2tab, dig = 3)
  ic <- apply(ic, 2, num2tab, dig = 3)
  tab <- cbind(paste(pars[1,]," (", pars[2,], ")", sep = ""), 
               paste("[", ic[1,], " ; ", ic[2,], "]", sep=""))
  colnames(tab)<-c("Estimativas (dp)", "quantil [5% ; 95%]")
  rownames(tab) <- c("phi1", "phi2", "sigma-trend", "sigma-txcresc", "sigma-ciclo")
  return(tab)
}





