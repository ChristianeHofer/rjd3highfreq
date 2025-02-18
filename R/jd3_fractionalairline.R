#' @include utils.R
NULL

ucm_extract<-function(jrslt, cmp){
  path<-paste0("ucarima.component(", cmp,")")
  return (arima_extract(jrslt, path))
}

arima_extract<-function(jrslt, path){
  str<-rjd3toolkit::.proc_str(jrslt, paste0(path, ".name"))
  ar<-rjd3toolkit::.proc_vector(jrslt, paste0(path, ".ar"))
  delta<-rjd3toolkit::.proc_vector(jrslt, paste0(path, ".delta"))
  ma<-rjd3toolkit::.proc_vector(jrslt, paste0(path, ".ma"))
  var<-rjd3toolkit::.proc_numeric(jrslt, paste0(path, ".var"))
  return (rjd3toolkit::arima_model(str, ar,delta,ma,var))
}



#' Perform an Arima Model Based (AMB) decomposition
#'
#' @param y input time series.
#' @param period period of the seasonal component, any positive real number.
#' @param adjust Boolean: TRUE: actual fractional airline model is to be used, FALSE: the period is rounded to the nearest integer.
#' @param sn decomposition into signal and noise (2 components only). The signal is the seasonally adjusted series and the noise the seasonal component.
#' @param stde Boolean: TRUE: compute standard deviations of the components. In some cases (memory limits), it is currently not possible to compute them
#' @param nbcasts number of backcasts.
#' @param nfcasts number of forecasts.
#'
#' @return
#' @export
#'
#' @examples
fractionalAirlineDecomposition <- function(y, period, sn = F, stde = F, nbcasts = 0, nfcasts = 0) 
{
  checkmate::assertNumeric(y, null.ok = F)
  checkmate::assertNumeric(period, len = 1, null.ok = F)
  checkmate::assertLogical(sn, len = 1, null.ok = F)
  jrslt <- .jcall("jdplus/highfreq/base/r/FractionalAirlineProcessor", 
                  "Ljdplus/highfreq/base/core/extendedairline/decomposition/LightExtendedAirlineDecomposition;", 
                  "decompose", as.numeric(y), period, sn, stde, as.integer(nbcasts), 
                  as.integer(nfcasts))
  return(jd2r_fractionalAirlineDecomposition(jrslt, sn, stde, period))
}


#' Perform an Arima Model Based (AMB) decomposition on several periodcities at once
#'
#' @param y input time series.
#' @param periods vector of periods values of the seasonal component, any positive real numbers.
#' @param adjust Boolean: TRUE: actual fractional airline model is to be used, FALSE: the period is rounded to the nearest integer.
#' @param sn decomposition into signal and noise (2 components only). The signal is the seasonally adjusted series and the noise the seasonal component.
#' @param stde Boolean: TRUE: compute standard deviations of the components. In some cases (memory limits), it is currently not possible to compute them
#' @param nbcasts number of backcasts.
#' @param nfcasts number of forecasts.
#'
#' @return
#' @export
#'
#' @examples
multiAirlineDecomposition <- function(y, periods, ndiff = 2, ar = F, stde = F, nbcasts = 0, 
                                      nfcasts = 0) 
{
  if (length(periods) == 1) {
    return(fractionalAirlineDecomposition(y, periods, stde = stde, 
                                          nbcasts = nbcasts, nfcasts = nfcasts))
  }
  checkmate::assertNumeric(y, null.ok = F)
  jrslt <- .jcall("jdplus/highfreq/base/r/FractionalAirlineProcessor", 
                  "Ljdplus/highfreq/base/core/extendedairline/decomposition/LightExtendedAirlineDecomposition;", 
                  "decompose", as.numeric(y), .jarray(periods), as.integer(ndiff), 
                  ar, stde, as.integer(nbcasts), as.integer(nfcasts))
  if (length(periods) == 1) {
    return(jd2r_fractionalAirlineDecomposition(jrslt, F, 
                                               stde, periods))
  }
  else {
    return(jd2r_multiAirlineDecomposition(jrslt, stde, periods))
  }
}


#' Linearize the series with a fractional airline model
#'
#' @param y input time series.
#' @param periods vector of periods values of the seasonal component, any positive real numbers.
#' @param x matrix of user-defined regression variables (see rjd3toolkit for building calendar regressors).
#' @param mean add constant mean to y after differencing.
#' @param outliers type of outliers sub vector of c("AO","LS","WO")
#' @param criticalValue Critical value for automatic outlier detection
#' @param precision Precision of the likelihood 
#' @param approximateHessian Compute approximate hessian (based on the optimizing procedure)
#' @param nfcasts Number of forecasts
#'
#' @return
#' @export
#'
#' @examples
fractionalAirlineEstimation <- function(
    y, periods, x = NULL, ndiff = 2, ar = F, mean = FALSE, 
    outliers = NULL, criticalValue = 6, precision = 1e-12, approximateHessian = F, nfcasts=0) 
{
  checkmate::assertNumeric(y, null.ok = F)
  checkmate::assertNumeric(criticalValue, len = 1, null.ok = F)
  checkmate::assertNumeric(precision, len = 1, null.ok = F)
  checkmate::assertLogical(mean, len = 1, null.ok = F)
  if (is.null(outliers)) 
    joutliers <- .jnull("[Ljava/lang/String;")
  else joutliers = .jarray(outliers, "java.lang.String")
  jrslt <- .jcall("jdplus/highfreq/base/r/FractionalAirlineProcessor", 
                  "Ljdplus/highfreq/base/core/extendedairline/ExtendedAirlineEstimation;", "estimate", 
                  as.numeric(y), rjd3toolkit::.r2jd_matrix(x), mean, .jarray(periods), 
                  as.integer(ndiff), ar, joutliers, criticalValue, precision, 
                  approximateHessian, as.integer(nfcasts))
  model <- list(
    y = as.numeric(y), 
    periods = periods, 
    variables = rjd3toolkit::.proc_vector(jrslt, "variables"), 
    xreg = rjd3toolkit::.proc_matrix(jrslt, "regressors"), 
    b = rjd3toolkit::.proc_vector(jrslt, "b"), 
    bcov = rjd3toolkit::.proc_matrix(jrslt, "bvar"), 
    linearized = rjd3toolkit::.proc_vector(jrslt, "lin"), 
    component_wo = rjd3toolkit::.proc_vector(jrslt, "component_wo"), 
    component_ao = rjd3toolkit::.proc_vector(jrslt, "component_ao"), 
    component_ls = rjd3toolkit::.proc_vector(jrslt, "component_ls"), 
    component_outliers = rjd3toolkit::.proc_vector(jrslt, "component_outliers"), 
    component_userdef_reg_variables = rjd3toolkit::.proc_vector(jrslt, "component_userdef_reg_variables"), 
    component_mean = rjd3toolkit::.proc_vector(jrslt, "component_mean"))
  
  estimation <- list(parameters = rjd3toolkit::.proc_vector(jrslt, "parameters"), 
                     score = rjd3toolkit::.proc_vector(jrslt, "score"), 
                     covariance = rjd3toolkit::.proc_matrix(jrslt, "pcov"))
  
  likelihood <- rjd3toolkit::.proc_likelihood(jrslt, "likelihood.")
  
  return(structure(list(model = model, 
                        estimation = estimation, 
                        likelihood = likelihood), 
                   class = "JDFractionalAirlineEstimation"))
}

#' Title
#'
#' @param y 
#' @param periods 
#' @param ndiff 
#' @param stde 
#' @param nbcasts 
#' @param nfcasts 
#'
#' @return
#' @export
#'
#' @examples
multiAirlineDecomposition_raw<-function(y, periods, ndiff=2, ar=F, stde=F, nbcasts=0, nfcasts=0){
  checkmate::assertNumeric(y, null.ok = F)
  
  jrslt<-.jcall("jdplus/highfreq/base/r/FractionalAirlineProcessor", 
                "Ljdplus/highfreq/base/core/extendedairline/decomposition/LightExtendedAirlineDecomposition;", 
                "decompose", as.numeric(y), 
                .jarray(periods), as.integer(ndiff), ar, stde, as.integer(nbcasts), as.integer(nfcasts))
  
  return (jrslt)
}

#' Title
#'
#' @param jdecomp 
#'
#' @return
#' @export
#'
#' @examples
multiAirlineDecomposition_ssf<-function(jdecomp){
  jssf<-.jcall("jdplus/highfreq/base/r/FractionalAirlineProcessor", 
               "Ljdplus/highfreq/base/core/ssf/extractors/SsfUcarimaEstimation;", "ssfDetails", jdecomp)
  return (rjd3toolkit::.jd3_object(jssf, result=T))
}

#' Title
#'
#' @param y 
#' @param period 
#' @param sn 
#' @param stde 
#' @param nbcasts 
#' @param nfcasts 
#'
#' @return
#' @export
#'
#' @examples
fractionalAirlineDecomposition_raw<-function(y, period, sn=F, stde=F, nbcasts=0, nfcasts=0){
  checkmate::assertNumeric(y, null.ok = F)
  checkmate::assertNumeric(period, len = 1, null.ok = F)
  checkmate::assertLogical(sn, len = 1, null.ok = F)
  jrslt<-.jcall("jdplus/highfreq/base/r/FractionalAirlineProcessor", 
                "Ljdplus/highfreq/base/core/extendedairline/decomposition/LightExtendedAirlineDecomposition;", 
                "decompose", as.numeric(y), 
                period, sn, stde, as.integer(nbcasts), as.integer(nfcasts))
  return (jrslt)
}

#' Title
#'
#' @param jdecomp 
#'
#' @return
#' @export
#'
#' @examples
fractionalAirlineDecomposition_ssf<-function(jdecomp){
  jssf<-.jcall("jdplus/highfreq/base/r/FractionalAirlineProcessor", "Ljdplus/highfreq/base/core/ssf/extractors/SsfUcarimaEstimation;", "ssfDetails", jdecomp)
  return (rjd3toolkit::.jd3_object(jssf, result=T))
}


#' Title
#'
#' @param jrslt 
#' @param stde 
#'
#' @return
#' @export
#'
#' @examples
jd2r_multiAirlineDecomposition <- function (jrslt, stde = F, periods) 
{
  ncmps <- rjd3toolkit::.proc_int(jrslt, "ucarima.size")
  model <- rjd3highfreq:::arima_extract(jrslt, "ucarima_model")
  cmps <- lapply(1:ncmps, function(cmp) {
    return(rjd3highfreq:::ucm_extract(jrslt, cmp))
  })
  ucarima <- rjd3toolkit::ucarima_model(model, cmps)
  yc <- rjd3toolkit::.proc_vector(jrslt, "y")
  estimation <- list(
    parameters = rjd3toolkit::.proc_vector(jrslt, "parameters"), 
    score = rjd3toolkit::.proc_vector(jrslt, "score"), 
    covariance = rjd3toolkit::.proc_matrix(jrslt, "pcov"), 
    periods = periods)
  likelihood <- rjd3toolkit::.proc_likelihood(jrslt, "likelihood.")
  ncmps <- rjd3toolkit::.proc_int(jrslt, "ncmps")
  if (stde) {
    decomposition <- lapply((1:ncmps), function(j) {
      return(cbind(
        rjd3toolkit::.proc_vector(jrslt, paste0("cmp(", j, ")")), 
        rjd3toolkit::.proc_vector(jrslt, paste0("cmp_stde(", j, ")"))))
    })
  }
  else {
    decomposition <- lapply((1:ncmps), function(j) {
      return(rjd3toolkit::.proc_vector(jrslt, paste0("cmp(", j, ")")))
    })
  }
  return(structure(list(ucarima = ucarima, 
                        decomposition = decomposition, 
                        estimation = estimation, 
                        likelihood = likelihood), 
                   class = "JDFractionalAirlineDecomposition"))
}


#' Title
#'
#' @param jrslt 
#' @param sn 
#' @param stde 
#'
#' @return
#' @export
#'
#' @examples
jd2r_fractionalAirlineDecomposition <- function (jrslt, sn = F, stde = F, period) 
{
  ncmps <- rjd3toolkit::.proc_int(jrslt, "ucarima.size")
  model <- rjd3highfreq:::arima_extract(jrslt, "ucarima_model")
  cmps <- lapply(1:ncmps, function(cmp) {
    return(rjd3highfreq:::ucm_extract(jrslt, cmp))
  })
  ucarima <- rjd3toolkit::ucarima_model(model, cmps)
  yc <- rjd3toolkit::.proc_vector(jrslt, "y")
  sa <- rjd3toolkit::.proc_vector(jrslt, "sa")
  s <- rjd3toolkit::.proc_vector(jrslt, "s")
  if (sn) {
    if (stde) {
      decomposition <- list(
        y = yc, 
        sa = sa, 
        s = s, 
        s.stde = rjd3toolkit::.proc_vector(jrslt, "s_stde"))
    }
    else {
      decomposition <- list(y = yc, sa = sa, s = s)
    }
  }
  else {
    t <- rjd3toolkit::.proc_vector(jrslt, "t")
    i <- rjd3toolkit::.proc_vector(jrslt, "i")
    if (stde) {
      decomposition <- list(
        y = yc, 
        t = t, 
        sa = sa, 
        s = s, 
        i = i, 
        t.stde = rjd3toolkit::.proc_vector(jrslt, "t_stde"), 
        s.stde = rjd3toolkit::.proc_vector(jrslt, "s_stde"), 
        i.stde = rjd3toolkit::.proc_vector(jrslt, "i_stde"))
    }
    else {
      decomposition <- list(y = yc, t = t, sa = sa, s = s, i = i)
    }
  }
  estimation <- list(
    parameters = rjd3toolkit::.proc_vector(jrslt, "parameters"), 
    score = rjd3toolkit::.proc_vector(jrslt, "score"), 
    covariance = rjd3toolkit::.proc_matrix(jrslt, "pcov"), 
    periods = period)
  
  likelihood <- rjd3toolkit::.proc_likelihood(jrslt, "likelihood.")
  
  return(structure(list(ucarima = ucarima, 
                        decomposition = decomposition, 
                        estimation = estimation, 
                        likelihood = likelihood), 
                   class = "JDFractionalAirlineDecomposition"))
}


