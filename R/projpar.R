#' @title Return a parameter used in a WRT projection
#' @description Return the value of a parameter (or the name) present in
#'  the WKT of the given proj4string.
#' @param proj4string The proj4string to be named (a character or a [CRS]
#'  object).
#' @param par Character corresponding to the parameter name.
#' @param abort logical: if TRUE, the function aborts in case an invalid
#'  proj4string is passed; if FALSE (default), the function returns NA,
#'  and a warning is shown.
#' @return A character with the content of the parameter (NULL if the
#'  parameter is not recognised) or the name of the projection, and an
#'   attribute `proj4string` with the input projection checked using
#'  [sf::st_crs()].
#'
#' @author Luigi Ranghetti, phD (2017) \email{ranghetti.l@@irea.cnr.it}
#' @note Python is needed.
#' @export
#' @importFrom reticulate r_to_py py_to_r
#' @importFrom sf st_as_text st_crs
#' @importFrom magrittr "%>%"
#'
#' @examples \dontrun{
#' projpar("+init=epsg:4326", "Unit")
#' }

projpar <- function(proj4string, par, abort = FALSE) {
  
  # import python modules
  py <- init_python()
  
  crs_check <- tryCatch(
    st_crs2(proj4string), 
    error = function(e) {st_crs(NA)}
  )
  
  if (is.na(crs_check$proj4string)) {
    return(NA)
  }
  
  proj4_wkt <- st_as_text(crs_check) %>%
    r_to_py() %>%
    py$osr$SpatialReference()
  proj4_par <- proj4_wkt$GetAttrValue(par) %>%
    py_to_r()
  
  attr(proj4_par, "proj4string") <- crs_check$proj4string
  
  return(proj4_par)
  
}


#' @name projname
#' @rdname projpar
#' @export
#' @importFrom sp is.projected CRS
#' @examples \dontrun{
#' projname("+init=epsg:4326")
#' }

projname <- function(proj4string, abort = FALSE) {
  
  proj4_name <- projpar(proj4string, "geogcs")
  
  if (is.projected(CRS(attr(proj4_name, "proj4string")))) {
    proj4_name <- projpar(proj4string, "projcs")
  }
  proj4_name <- gsub("\\_"," ",proj4_name)
  
  return(proj4_name)
  
}
