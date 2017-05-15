#' Plota series temporais com ggplot2
#' 
#' @param x objeto ts ou mts com as series temporais
#' @param y (opicional) objeto ts ou mts com dimensao de x para ser
#' plotado junto com x no mesmo grafico 
#' @param escala Are scales shared across all facets
#'  ("fixed"), or do they vary across 
#'  rows ("free_x"), columns (the default, "free_y"), or both 
#'  rows and columns ("free")
#' @param facet as series sao plotadas em graficos diferente (facet = TRUE, the default),
#' ou no mesmo grafico (facet = FALSE)
#' @param name optional name for ts univariate
#' @param title The main title (on top) 
#' 
#' @return ggplot das series
#' 
#' @import ggplot2 zoo
#' 
#' @export
#' 

tsplot <- function(x, y = NULL, escala = 'free_y', facet = TRUE,
                   name = NULL, title = NULL){
  nseries <- NCOL(x)
  ntime <- NROW(x)
  x <- zoo::as.zoo(x)
  df.x <- zoo::fortify.zoo(x, melt = TRUE)
  if(nseries==1 & !is.null(name)){
    df.x[,"Series"] <- rep(name, ntime)
  }
  if(!is.null(y)){
    y <- zoo::as.zoo(y)
    df.y <- zoo::fortify.zoo(y, melt = TRUE)
    if(facet){
      df <- ggplot2::fortify(cbind(df.x, Value2=df.y[,3]), index.name = "Index")
      p <- ggplot2::ggplot(data = df, ggplot2::aes(x = Index, y = Value))
      p <- p + ggplot2::geom_line(data = df, ggplot2::aes(x = Index, y = Value2),
                                  linetype=2, colour="red", size = 1/2, alpha = 1)
      p <- p + ggplot2::geom_line(size = 1/2, alpha = 1, colour="blue")  
      p <- p + ggplot2::facet_grid(Series ~ ., scales = "free_y") 
      #p <- p + ggplot2::facet_wrap(~ Series, scales = "free_y")
    }else{
      p <- ggplot(df.x, aes(x = Index, y = Value))
      p <- p + geom_line(data = df.y, aes(x = Index, y = Value, group = Series), size = 1/2, alpha = 1, colour="blue")
      p <- p + geom_line(linetype=2, size = 1/2, alpha = 1, colour="blue")  # Drawing the "overlayer"
    }
  }else{
    if(!facet){
      p <- ggplot2::ggplot(data = df.x, ggplot2::aes(x = Index, y = Value, color=Series, linetype=Series))
      p <- p + ggplot2::geom_line(size = 3/4)  
    }else{
      p <-ggplot2::ggplot(df.x, ggplot2::aes(x=Index, y=Value, group_by())) +
        ggplot2::geom_line(size = 1/2, alpha = 1, colour="blue") +
        ggplot2::facet_grid(Series ~ ., scales = escala)
    }
  }
  if(!is.null(title)){
    p <- p + ggtitle(title)
  }
  p <- p + ggplot2::labs(y="", x="")
  p <- p + ggplot2::theme_bw(base_size=14)
  return(p)
}


#' Multiple plot function
#' 
#' ggplot objects can be passed in ..., or to plotlist (as a list of ggplot objects)
#' 
#' @param ... ggplot objects
#' @param plotlist a list of ggplot objects
#' @param cols Number of columns in layout
#' @param layout A matrix specifying the layout. If present, 'cols' is ignored.
#'
#' 
#' @details If the layout is something like matrix(c(1,2,3,3), nrow=2, byrow=TRUE),
#' then plot 1 will go in the upper left, 2 will go in the upper right, and
#' 3 will go all the way across the bottom.
#' 
#' @return multiple plot 
#' 
#' @import ggplot2 grid
#' 
#' @export
#'

multiplot <- function(..., plotlist=NULL, cols=1, layout=NULL) {
  requireNamespace("grid")
  
  # Make a list from the ... arguments and plotlist
  plots <- c(list(...), plotlist)
  
  numPlots = length(plots)
  
  # If layout is NULL, then use 'cols' to determine layout
  if (is.null(layout)) {
    # Make the panel
    # ncol: Number of columns of plots
    # nrow: Number of rows needed, calculated from # of cols
    layout <- matrix(seq(1, cols * ceiling(numPlots/cols)),
                     ncol = cols, nrow = ceiling(numPlots/cols))
  }
  
  if (numPlots==1) {
    print(plots[[1]])
    
  } else {
    # Set up the page
    grid.newpage()
    pushViewport(viewport(layout = grid.layout(nrow(layout), ncol(layout))))
    
    # Make each plot, in the correct location
    for (i in 1:numPlots) {
      # Get the i,j matrix positions of the regions that contain this subplot
      matchidx <- as.data.frame(which(layout == i, arr.ind = TRUE))
      
      print(plots[[i]], vp = viewport(layout.pos.row = matchidx$row,
                                      layout.pos.col = matchidx$col))
    }
  }
}