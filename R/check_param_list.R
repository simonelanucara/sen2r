#' @title Check a fidolasen parameter list
#' @description Check that the parameter list (or JSON parameter file)
#'  is in the correct format, and then speficied values are coherent with 
#'  parameters.
#' @param type Type of the output (see [print_message] for details).
#' @return Depending on `type` argument, output can be a vector of errors 
#'  (if `type = "string"`), the first error occurred (if `type = "error"`)
#'  or a set of warnings (if `type = "warning"`). If no errors occur,
#'  output is NULL.
#'  
#' @importFrom jsonlite fromJSON
#' @importFrom methods is
#' @author Luigi Ranghetti, phD (2017) \email{ranghetti.l@@irea.cnr.it}
#' @note License: GPL 3.0


check_param_list <- function(pm, type = "string") {
  
  # check the output type
  
  # check the format of pm object
  if (is(pm, "character")) {
    if (file.exists(pm)) {
      # load json parameter file
      pm <- jsonlite::fromJSON(pm)
    } else {
      print_message(
        type = "error",
        "The file ",pm," does not exist."
      )
    }
  } else if (!is(pm, "list")) {
    print_message(
      type = "error",
      "\"",deparse(substitute(pm)),"\"",
      "must be a list or a path of a JSON parameter file."
    )
  }
  
  # TODO check the names of the content of the list

  # TODO check package version and parameter names
  
  # check timewindow
  if (!any(is.na(pm$timewindow))) {
    if (length(pm$timewindow)==1) {
      pm$timewindow <- rep(pm$timewindow, 2)
    } else if (length(pm$timewindow)>2) {
      print_message(
        type = type,
        "Parameter 'timewindow' must be of length 1 or 2."
      )
    }
    if (is(pm$timewindow, "character")) {
      tryCatch(pm$timewindow <- as.Date(pm$timewindow), error = print)
    } else if (is(pm$timewindow, "POSIXt")) {
      pm$timewindow <- as.Date(pm$timewindow)
    }
    if (!is(pm$timewindow, "Date")) {
      print_message(
        type = type,
        "Parameter 'timewindow' must be a Date object."
      )
    }
  }
  
  # example of check
  if (!any(is.na(pm$res)) & any(pm$res <= 0)) {
    print_message(
      type = type,
      "Output resolution (parameter \"res\" ) must be positive."
    )
  }
  
  
  # WIP 
  
  
}