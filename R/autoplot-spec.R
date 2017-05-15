#' Autoplotting Spectral Densities
#' 
#' Plotting method for objects of class "spec". For multivariate 
#' time series it plots the marginal spectra of the series or 
#' pairs plots of the coherency and phase of the cross-spectra.
#' 
#' 
#' @param x an object of class "spec"
#' @param ci coverage probability for confidence interval. 
#' Plotting of the confidence bar/limits is omitted unless ci
#' is strictly positive.
#' @param xlab the x label of the plot
#' @param ylab the y label of the plot   
#' @param main overall title for the plot. 
#' If missing, a suitable title is constructed
#' @param log use conventional log scale or linear scale. The default is TRUE.
#' @param plot.type For multivariate time series, the type of plot required.
#' 
#' @importFrom reshape2 melt
#' @importFrom dplyr mutate
#' @import ggplot2
#' 
#' @export

autoplot.spec <- function (x, ci = 0.95, log = TRUE, 
            xlab = "frequency", ylab = NULL, main = NULL, plot.type = c("spectrum", 
                                                               "coherency", "phase"))
  {
  
  plot.type <- match.arg(plot.type)
  if (plot.type == "coherency") {
    g <- autoplot.spec.coherency(x, ci, xlab, ylab, main)
    return(g)
  }
  if (plot.type == "phase") {
    g <- autoplot.spec.phase(x, ci, xlab, ylab, main)
    return(g)
  }
  
  # calcula  phase
  if(log){
    spectrum <- log(x$spec)
  }else spectrum <- x$spec
  
  colnames(spectrum) <- x$snames
  rownames(spectrum) <- x$freq
  if (is.null(ylab)) 
    ylab <- "spectrum"
  if (is.null(main)) 
    main <- paste(paste("Series:", x$series), "Spectrum", 
                  sep = " --  ")
  
  df.spec <- melt(spectrum)
  colnames(df.spec) <- c("frequency", "id", "spectrum")
  
  requireNamespace("ggplot2")
  g <- ggplot(df.spec, aes(frequency, spectrum, colour=id, linetype=id)) +
    geom_line() +
    labs(title = main, x=xlab, y=ylab)
  return(g)
}



#' Autoplotting Spectral Densities
#' 
#' Plotting method for objects of class "spec". For multivariate 
#' time series it plots the marginal spectra of the series or 
#' pairs plots of the coherency and phase of the cross-spectra.
#' 
#' 
#' @param x an object of class "spec"
#' @param ci coverage probability for confidence interval. 
#' Plotting of the confidence bar/limits is omitted unless ci
#' is strictly positive.
#' @param xlab the x label of the plot
#' @param ylab the y label of the plot   
#' @param main overall title for the plot. 
#' If missing, a suitable title is constructed
#' 
#' @import ggplot2
#' @importFrom stats qnorm qf
#' @importFrom reshape2 melt
#' @importFrom dplyr mutate
#' 
#' @export


autoplot.spec.coherency <- 
  function (x, ci = 0.95, xlab = "frequency", ylab = "squared coherency", 
            main = NULL){
    
    if (is.null(main)) 
      main <- paste(paste("Series:", x$series), "Squared Coherency", 
                    sep = " --  ")
    
    nser <- NCOL(x$spec)
    gg <- 2/x$df
    se <- sqrt(gg/2)
    z <- -qnorm((1 - ci)/2)
    # nome das combinacoes
    snames <- x$snames
    id <- vector()
    for(i in 1:(length(snames)-1)){
      for(j in 2:length(snames)){
        if(i<j)
          id[i + (j - 1) * (j - 2)/2] <- paste(snames[i], "&", snames[j])
      }
    }
    
    # nomiea a coherence 
    coherence <- x$coh
    colnames(coherence) <- id
    rownames(coherence) <- x$freq
    if (is.null(ylab)) 
      ylab <- "coherence"
    
    # we may reject the hypothesis of no coherence for values of
    # coherence that exceed C at the significance level alpha=0.01
    f = qf(.99, 2, x$df-2) 
    C = f/(3*(length(x$kernel$coef)-1)+f)
    # 
    df.coh <- reshape2::melt(coherence)
    colnames(df.coh) <- c("frequency", "id", "coherence")
    # adiciona intervalo confianca
    df.coh <- dplyr::mutate(df.coh, lower.coh=(pmax(0, tanh(atanh(pmin(0.99999, sqrt(coherence))) - z * se)))^2)
    df.coh <- dplyr::mutate(df.coh, upper.coh=(tanh(atanh(pmin(0.99999, sqrt(coherence))) + z * se))^2)
    
    requireNamespace("ggplot2")
    g <- ggplot(df.coh, aes(frequency, coherence)) +
      geom_line(colour = "blue") +
      geom_ribbon(aes(ymin=lower.coh, ymax=upper.coh),
                  alpha=0.2) +
      geom_hline(yintercept = C, linetype="dotted") +
      labs(title = main, x=xlab, y=ylab) +
      facet_wrap(~ id)
    g
  }

#' Autoplotting Spectral Densities
#' 
#' Plotting method for objects of class "spec". For multivariate 
#' time series it plots the marginal spectra of the series or 
#' pairs plots of the coherency and phase of the cross-spectra.
#' 
#' 
#' @param x an object of class "spec"
#' @param ci coverage probability for confidence interval. 
#' Plotting of the confidence bar/limits is omitted unless ci
#' is strictly positive.
#' @param xlab the x label of the plot
#' @param ylab the y label of the plot   
#' @param main overall title for the plot. 
#' If missing, a suitable title is constructed
#' 
#' @import ggplot2
#' @importFrom stats qt
#' @importFrom reshape2 melt
#' @importFrom dplyr mutate
#' 
#' @export


autoplot.spec.phase <- 
  function (x, ci = 0.95, xlab = "frequency", ylab = "phase", 
            main = NULL){
    
    if (is.null(main)) 
      main <- paste(paste("Series:", x$series), "Phase spectrum", 
                    sep = " --  ")
    
    nser <- NCOL(x$spec)
    gg <- 2/x$df
    # ic phase
    cl <- asin(pmin(0.9999, qt(ci, 2/gg - 2) * sqrt(gg * 
                                                      (sqrt(x$coh)^{
                                                        -2
                                                      } - 1)/(2 * (1 - gg)))))
    # nome das combinacoes
    snames <- x$snames
    id <- vector()
    for(i in 1:(length(snames)-1)){
      for(j in 2:length(snames)){
        if(i<j)
          id[i + (j - 1) * (j - 2)/2] <- paste(snames[i], "&", snames[j])
      }
    }
     
    # calcula  phase
    phase <- x$phase
    colnames(phase) <- id
    rownames(phase) <- x$freq
    if (is.null(ylab)) 
      ylab <- "phase"
    
    df.pha <- melt(phase)
    colnames(df.pha) <- c("frequency", "id", "phase")
    
    df.pha <- dplyr::mutate(df.pha, lower.pha=phase + cl)
    df.pha <- dplyr::mutate(df.pha, upper.pha=phase - cl)
    
    
    requireNamespace("ggplot2")
    g <- ggplot(df.pha, aes(frequency, phase)) +
      geom_line(colour = "blue") +
      geom_ribbon(aes(ymin=lower.pha, ymax=upper.pha),
                  alpha=0.2) +
      geom_hline(yintercept = 0) +
      labs(title = main, x=xlab, y=ylab) +
      facet_wrap(~ id)
    g
  }