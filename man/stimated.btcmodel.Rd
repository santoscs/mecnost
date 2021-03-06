% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/btcmodel.R
\name{stimated.btcmodel}
\alias{stimated.btcmodel}
\title{Components of btc model}
\usage{
stimated.btcmodel(object, discarding = 0.05)
}
\arguments{
\item{object}{Object of class "btcmodel"}

\item{discarding}{percent for first part of the simulated chain
as burn in}
}
\value{
an ts object with trend, cycle and grow components estimated
}
\description{
Extract trend, cycle and grow components estimated from an btcmodel.
}

