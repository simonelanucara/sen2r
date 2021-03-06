#' @title Get information from S2 file name or metadata
#' @description The function `safe_getMetadata()` scans a Sentinel2 product 
#'  (main path, granule path, main / granule xml file or GDAL object) 
#'  to retrieve information about the product.
#'  
#'  The accessory function `rm_invalid_safe()` remove a SAFE archive in the case
#'  it is not recognised by `safe_getMetadata()`.
#' @param s2 A Sentinel-2 product, being both a `character` (path of an
#'  existing product, or simply product name) or python object of class
#'  `osgeo.gdal.Dataset`. This input parameter
#'  can be the main path of a S2 file, the path of the xml with metadata,
#'  the path of a single granule, the xml path of a single granule, or a
#'  'osgeo.gdal.Dataset' object (obtained reading the product with python).
#'  If the product does not exist locally, the function can run only with
#'  option `info = "nameinfo"` (see below).
#' @param info (optional) A character vector with the list of the metadata
#'  which should be provided.
#'  Accepted values are:
#'  * `"all"` (default): all the retrevable metadata are provided;
#'  * `"fileinfo"`: only the metadata obtained by scanning the file name
#'      and product structure (without opening it with GDAL) are provided.
#'  * `"nameinfo"`: only the metadata obtained by scanning the file name
#'      are provided (it is faster and there is no need to have downloaded
#'      yet the file).
#'  * a vector of single specific information (one or more from the
#'      followings):
#'      - `"prod_type"` ('singlegranule' or 'product');
#'      - `"version"` ('old' or 'compact');
#'      - `"tiles"` (vector with the tiles ID available in the product);
#'      - `"utm"` (vector with the UTM zones used in the product);
#'      - `"xml_main"` (name of the main XML file with metadata);
#'      - `"xml_granules"` (names of the XML with granule metadata);
#'      - `"level"` ('1C' or '2A');
#'      - `"creation_datetime"`, `"id_tile"`, `"mission"`, `"centre"`,
#'          `"file_class"`, `"id_orbit"`, `"orbit_number"`,
#'          `"sensing_datetime"`, `"id_baseline"`: metadata speficic of
#'          the product type and version (they are returned only if
#'          obtainable for the specified input);
#'      - `"clouds"`, `"direction"`, `"orbit_n"`, `"preview_url"`,
#'          `"proc_baseline"`, `"level"`, `"sensing_datetime"`,
#'          `"nodata_value"`, `"saturated_value"`:
#'          information retrieved from the metadata stored in the XML file.
#'
#'      In this version, querying for specific elements requires the product
#'      to be present in the filesystem; in future this will be changed
#'      (see the second example for a workaround to scan for specific
#'      elements without needing the file to have been downloaded).

#' @return `safe_getMetadata()` returns a list of the output metadata;
#' 
#'  `rm_invalid_safe()` returns TRUE if the `s2` product was removed, 
#'  FALSE elsewhere.
#'
#' @author Luigi Ranghetti, phD (2017, 2018) \email{ranghetti.l@@irea.cnr.it}
#' @note License: GPL 3.0
#' @export
#' @importFrom reticulate py_to_r
#' @importFrom methods is
#'
#' @examples
#' # Define product name
#' s2_examplename <-
#'   "/path/of/the/product/S2A_MSIL1C_20170603T101031_N0205_R022_T32TQQ_20170603T101026.SAFE"
#'
#' # Return only the information retrevable from the file names (files are not scanned)
#' safe_getMetadata(s2_examplename, info="nameinfo")
#'
#' # Return some specific information without scanning files
#' safe_getMetadata(s2_examplename, info="nameinfo")[c("level", "id_tile")]
#'
#' # Return a single information without scanning files
#' # (in this case, the output is a vector instead than a list)
#' safe_getMetadata(s2_examplename, info="nameinfo")[["level"]]
#'
#' \dontrun{
#'
#' # Return all the available information
#' safe_getMetadata(s2_examplename)
#'
#' # Return some specific information
#' safe_getMetadata(s2_examplename, info=c("tiles", "level", "id_tile"))
#'
#' # Return a single information
#' safe_getMetadata(s2_examplename, info="clouds")
#' 
#' # Delete it if it is not recognised
#' rm_invalid_safe(s2_examplename)
#' 
#' }

# TODO
# - make the output list uniform (es. level and tiles/id_tile)
# - add a parameter which provides the list of the available options
# - add check for format integrity


safe_getMetadata <- function(s2, info="all") {
  .safe_getMetadata(s2, info=info, action = "getmetadata")
}


#' @name rm_invalid_safe
#' @rdname safe_getMetadata
#' @export
rm_invalid_safe <- function(s2) {
  .safe_getMetadata(s2, info="fileinfo", action = "rm_invalid")
}


# internal function: action="getmetadata" causes the execution of safe_getMetadata(),
# action="rm_invalid" causes the execution of rm_invalid_safe().
.safe_getMetadata <- function(s2, info="all", action = "getmetadata") {
  
  # define regular expressions to identify products
  s2_regex <- list(
    "oldname_main_xml" = list("regex" = "^S(2[AB])\\_([A-Z]{4})\\_MTD\\_SAFL([12][AC])\\_(.{4})\\_([0-9]{8}T[0-9]{6})\\_R([0-9]{3})\\_V[0-9]{8}T[0-9]{6}\\_([0-9]{8}T[0-9]{6})\\.xml$",
                              "elements" = c("mission","file_class","level","centre","creation_datetime","id_orbit","sensing_datetime")),
    "oldname_main_path" = list("regex" = "^S(2[AB])\\_([A-Z]{4})\\_PRD\\_MSIL([12][AC])\\_(.{4})\\_([0-9]{8}T[0-9]{6})\\_R([0-9]{3})\\_V[0-9]{8}T[0-9]{6}\\_([0-9]{8}T[0-9]{6})\\.SAFE$",
                               "elements" = c("mission","file_class","level","centre","creation_datetime","id_orbit","sensing_datetime")),
    "compactname_main_xml" = list("regex" = "^MTD\\_MSIL([12][AC])\\.xml$", "elements" = c("level")),
    "compactname_main_path" = list("regex" = "^S(2[AB])\\_MSIL([12][AC])\\_([0-9]{8}T[0-9]{6})\\_N([0-9]{4})\\_R([0-9]{3})\\_T([A-Z0-9]{5})\\_([0-9]{8}T[0-9]{6})\\.SAFE$",
                                   "elements" = c("mission","level","sensing_datetime","id_baseline","id_orbit","id_tile","creation_datetime")),
    "oldname_granule_xml" = list("regex" = "^S(2[AB])\\_([A-Z]{4})\\_MTD\\_L([12][AC])\\_TL\\_(.{4})\\_([0-9]{8}T[0-9]{6})\\_A([0-9]{6})\\_T([A-Z0-9]{5})\\.xml$",
                                 "elements" = c("mission","file_class","level","centre","creation_datetime","orbit_number","id_tile")),
    "oldname_granule_path" = list("regex" = "^S(2[AB])\\_([A-Z]{4})\\_MSI\\_L([12][AC])\\_TL\\_(.{4})\\_([0-9]{8}T[0-9]{6})\\_A([0-9]{6})\\_T([A-Z0-9]{5})\\_N([0-9]{2})\\.([0-9]{2})$",
                                  "elements" = c("mission","file_class","level","centre","creation_datetime","orbit_number","id_tile","proc_baseline_x","proc_baseline_y")),
    "compactname_granule_xml" = list("regex" = "^MTD\\_TL\\.xml$", "elements" = character(0)),
    "compactname_granule_path" = list("regex" = "^L([12][AC])\\_T([A-Z0-9]{5})\\_A([0-9]{6})\\_([0-9]{8}T[0-9]{6})$",
                                      "elements" = c("level","id_tile","orbit_number","creation_datetime")),
    "oldname_L1C_jp2" = list("regex" = "^S(2[AB])\\_([A-Z]{4})\\_([A-Z]{3})\\_L1C\\_TL\\_(.{4})\\_([0-9]{8}T[0-9]{6})\\_A([0-9]{6})\\_T([A-Z0-9]{5})_(B[0-9A]{2})\\.jp2$",
                             "elements" = c("mission","file_class","additional_product","centre","creation_datetime","orbit_number","id_tile","bandname")),
    "oldname_L2A_jp2" = list("regex" = "^S(2[AB])\\_([A-Z]{4})\\_([A-Z]{3})\\_L2A\\_TL\\_(.{4})\\_([0-9]{8}T[0-9]{6})\\_A([0-9]{6})\\_T([A-Z0-9]{5})\\_?(B[0-9A]{2})?\\_([126]0m)\\.jp2$",
                             "elements" = c("mission","file_class","additional_product","centre","creation_datetime","orbit_number","id_tile","bandname","res")),
    "compactname_L1C_jp2" = list("regex" = "^T([A-Z0-9]{5})\\_([0-9]{8}T[0-9]{6})\\_(B[0-9A]{2})\\.jp2$",
                                 "elements" = c("id_tile","sensing_datetime","bandname")),
    "compactname_L2A_jp2" = list("regex" = "^(?:L2A\\_)?T([A-Z0-9]{5})\\_([0-9]{8}T[0-9]{6})\\_([0-9A-Z]{3})\\_([126]0m)\\.jp2$",
                                 "elements" = c("id_tile","sensing_datetime","bandname","res"))) # here bandname can be also additional_product
  
  # import python modules
  py <- init_python()
  
  # define all possible elements to scan
  info_base <- c("prod_type", "version") # information always retrieved
  info_general <- c("tiles", "utm", "xml_main", "xml_granules") # information retrieved if the product is scanned
  info_name <- c("level","creation_datetime", "id_tile", "mission", "centre", "file_class",
                 "id_orbit", "orbit_number", "sensing_datetime", "id_baseline") # information retrieved from name
  info_gdal <- c("clouds","direction","orbit_n","preview_url", # information retrieved by reading the file metadata
                 "proc_baseline","gdal_level","gdal_sensing_datetime",
                 "nodata_value","saturated_value")
  if (length(info)==1) {
    if (info=="all") {
      info <- c(info_base, info_general, info_name, info_gdal)
      scan_file <- TRUE
    } else if (info=="fileinfo") {
      info <- c(info_base, info_general, info_name)
      scan_file <- TRUE
    } else if (info=="nameinfo") {
      info <- c(info_base, info_name)
      scan_file <- FALSE
    } else {
      scan_file <- TRUE
    }
  } else {
    scan_file <- TRUE
  }
  
  metadata <- list() # output object, with requested metadata
  
  # If s2 is a string, check it and retrieve file metadata
  if (is(s2, "character")) {
    
    # if scan_file is FALSE, check the input as a product name without searching for files
    if (!scan_file) {
      
      s2_name <- basename(s2)
      
      # retrieve type and version
      nameinfo_target <- s2_name
      if (length(grep("\\.xml$",nameinfo_target))==1) {
        if (length(grep(s2_regex$compactname_main_xml$regex, s2_name))+length(grep(s2_regex$oldname_main_xml$regex, s2_name))==1) {
          s2_type <- "product"
          if(length(grep(s2_regex$compactname_main_xml$regex, s2_name))==1) {
            s2_version <- "compact"
            nameinfo_regex <- s2_regex$compactname_main_xml$regex
            nameinfo_elements <- list(s2_regex$compactname_main_xml$elements)
          } else if(length(grep(s2_regex$oldname_main_xml$regex, s2_name))==1) {
            nameinfo_regex <- s2_regex$oldname_main_xml$regex
            nameinfo_elements <- list(s2_regex$oldname_main_xml$elements)
            s2_version <- "old"
          }
        } else if (length(grep(s2_regex$compactname_granule_xml$regex, s2_name))+length(grep(s2_regex$oldname_granule_xml$regex, s2_name))==1) {
          s2_type <- "singlegranule"
          if(length(grep(s2_regex$compactname_granule_xml$regex, s2_name))==1) {
            s2_version <- "compact"
            nameinfo_regex <- s2_regex$compactname_granule_xml$regex
            nameinfo_elements <- list(s2_regex$compactname_granule_xml$elements)
          } else if(length(grep(s2_regex$oldname_granule_xml$regex, s2_name))==1) {
            s2_version <- "old"
            nameinfo_regex <- s2_regex$oldname_granule_xml$regex
            nameinfo_elements <- list(s2_regex$oldname_granule_xml$elements)
          }
        } else {
          if (action == "getmetadata") {
            print_message(
              type="error", 
              "This product (",s2,") is not in the right format (not recognised)."
            )
          } else if (action == "rm_invalid") {
            unlink(s2, recursive=TRUE)
            return(invisible(TRUE))
          }
        }
      } else {
        if (length(grep(s2_regex$compactname_main_path$regex, s2_name))+length(grep(s2_regex$oldname_main_path$regex, s2_name))==1) {
          s2_type <- "product"
          if(length(grep(s2_regex$compactname_main_path$regex, s2_name))==1) {
            s2_version <- "compact"
            nameinfo_regex <- s2_regex$compactname_main_path$regex
            nameinfo_elements <- list(s2_regex$compactname_main_path$elements)
          } else if(length(grep(s2_regex$oldname_main_path$regex, s2_name))==1) {
            nameinfo_regex <- s2_regex$oldname_main_path$regex
            nameinfo_elements <- list(s2_regex$oldname_main_path$elements)
            s2_version <- "old"
          }
        } else if (length(grep(s2_regex$compactname_granule_path$regex, s2_name))+length(grep(s2_regex$oldname_granule_path$regex, s2_name))==1) {
          s2_type <- "singlegranule"
          if(length(grep(s2_regex$compactname_granule_path$regex, s2_name))==1) {
            s2_version <- "compact"
            nameinfo_regex <- s2_regex$compactname_granule_path$regex
            nameinfo_elements <- list(s2_regex$compactname_granule_path$elements)
          } else if(length(grep(s2_regex$oldname_granule_path$regex, s2_name))==1) {
            s2_version <- "old"
            nameinfo_regex <- s2_regex$oldname_granule_path$regex
            nameinfo_elements <- list(s2_regex$oldname_granule_path$elements)
          }
        } else {
          if (action == "getmetadata") {
            print_message(
              type="error", 
              "This product (",s2,") is not in the right format (not recognised)."
            )
          } else if (action == "rm_invalid") {
            unlink(s2, recursive=TRUE)
            return(invisible(TRUE))
          }
        }
      }
      
      # if scan_file is TRUE, scan for file content
    } else {
      
      # If s2 is a path:
      # convert in absolute path (and check that file exists)
      s2_path <- normalizePath(s2, mustWork=TRUE)
      
      # retrieve the name of xml main file
      # if it is a directory, scan the content
      if (file.info(s2_path)$isdir) {
        compactname_main_xmlfile <- list.files(s2_path,s2_regex$compactname_main_xml$regex, full.names=TRUE)
        oldname_main_xmlfile <- list.files(s2_path,s2_regex$oldname_main_xml$regex, full.names=TRUE)
        compactname_granule_xmlfile <- list.files(s2_path,s2_regex$compactname_granule_xml$regex, full.names=TRUE)
        oldname_granule_xmlfile <- list.files(s2_path,s2_regex$oldname_granule_xml$regex, full.names=TRUE)
      } else {
        compactname_main_xmlfile <- s2_path[grep(s2_regex$compactname_main_xml$regex, basename(s2_path))]
        oldname_main_xmlfile <- s2_path[grep(s2_regex$oldname_main_xml$regex, basename(s2_path))]
        compactname_granule_xmlfile <- s2_path[grep(s2_regex$compactname_granule_xml$regex, basename(s2_path))]
        oldname_granule_xmlfile <- s2_path[grep(s2_regex$oldname_granule_xml$regex, basename(s2_path))]
        s2_path <- dirname(s2_path)
      }
      
      # check version (old / compact) and product type (product / singlegranule)
      if (length(oldname_main_xmlfile)+length(compactname_main_xmlfile)==1) {
        if (length(oldname_granule_xmlfile)+length(compactname_granule_xmlfile)==0) {
          s2_type <- "product"
          # Check product version
          if (length(compactname_main_xmlfile)==0) {
            if (length(oldname_main_xmlfile)==1) {
              s2_version <- "old"
              s2_main_xml <- s2_xml <- oldname_main_xmlfile
              s2_granules_xml <- unlist(sapply(list.dirs(file.path(s2_path,"GRANULE"), recursive=FALSE, full.names=TRUE),
                                               list.files, s2_regex$oldname_granule_xml$regex, full.names=TRUE))
            } else if (length(oldname_main_xmlfile)==0) {
              if (action == "getmetadata") {
                print_message(
                  type="error", 
                  "This product (",s2,") is not in the right format (not recognised)."
                )
              } else if (action == "rm_invalid") {
                unlink(s2, recursive=TRUE)
                return(invisible(TRUE))
              }
            } else {
              print_message(
                type="error", 
                "This product (",s2,") is not in the right format (not univocally recognised)."
              )
            }
          } else if (length(compactname_main_xmlfile)==1) {
            if (length(oldname_main_xmlfile)==0) {
              s2_version <- "compact"
              s2_main_xml <- s2_xml <- compactname_main_xmlfile
              s2_granules_xml <- unlist(sapply(list.dirs(file.path(s2_path,"GRANULE"), recursive=FALSE, full.names=TRUE),
                                               list.files, s2_regex$compactname_granule_xml$regex, full.names=TRUE))
            } else {
              print_message(
                type="error", 
                "This product (",s2,") is not in the right format (not univocally recognised)."
              )
            }
          }
        } else {
          print_message(
            type="error", 
            "This product (",s2,") is not in the right format (not univocally recognised)."
          )
        }
      } else if (length(oldname_main_xmlfile)+length(compactname_main_xmlfile)==0) {
        if (length(oldname_granule_xmlfile)+length(compactname_granule_xmlfile)==1) {
          s2_type <- "singlegranule"
          # Check product version
          if (length(compactname_granule_xmlfile)==0) {
            if (length(oldname_granule_xmlfile)==1) {
              s2_version <- "old"
              s2_main_xml <- list.files(dirname(dirname(s2_path)), s2_regex$oldname_main_xml$regex, full.names=TRUE)
              s2_granules_xml <- s2_xml <- oldname_granule_xmlfile
            } else if (length(oldname_granule_xmlfile)==0) {
              if (action == "getmetadata") {
                print_message(
                  type="error", 
                  "This product (",s2,") is not in the right format (not recognised)."
                )
              } else if (action == "rm_invalid") {
                unlink(s2, recursive=TRUE)
                return(invisible(TRUE))
              }
            }
          } else if (length(compactname_granule_xmlfile) == 1) {
            if (length(oldname_granule_xmlfile) == 0) {
              s2_version <- "compact"
              s2_main_xml <- list.files(dirname(dirname(s2_path)), s2_regex$compactname_main_xml$regex, full.names=TRUE)
              s2_granules_xml <- s2_xml <- compactname_granule_xmlfile
            } else if (length(oldname_granule_xmlfile) == 1) {
              print_message(
                type="error", 
                "This product (",s2,") is not in the right format (not univocally recognised)."
              )
            }
          }
        } else if (length(oldname_granule_xmlfile) + length(compactname_granule_xmlfile) == 0) {
          if (action == "getmetadata") {
            print_message(
              type="error", 
              "This product (",s2,") is not in the right format (not recognised)."
            )
          } else if (action == "rm_invalid") {
            unlink(s2, recursive=TRUE)
            return(invisible(TRUE))
          }
        } else {
          print_message(
            type="error", 
            "This product (",s2,") is not in the right format (not univocally recognised)."
          )
        }
      } else {
        if (action == "getmetadata") {
          print_message(
            type="error", 
            "This product (",s2,") is not in the right format (not recognised)."
          )
        } else if (action == "rm_invalid") {
          unlink(s2, recursive=TRUE)
          return(invisible(TRUE))
        }
      }
      
      # metadata from file name are read
      # decide target, regex and elements to scan
      if (s2_version=="old") {
        # for old names, retrieve from xml name
        if (s2_type=="product") {
          nameinfo_target <- basename(s2_xml)
          nameinfo_regex <- s2_regex$oldname_main_xml$regex
          nameinfo_elements <- list(s2_regex$oldname_main_xml$elements)
        } else if (s2_type=="singlegranule") {
          nameinfo_target <- c(basename(s2_xml), basename(s2_main_xml))
          nameinfo_regex <- c(s2_regex$oldname_granule_xml$regex, s2_regex$oldname_main_xml$regex)
          nameinfo_elements <- list(s2_regex$oldname_granule_xml$elements, s2_regex$oldname_main_xml$elements)
        }
      } else {
        # for compact names, retrieve from directory name
        if (s2_type=="product") {
          nameinfo_target <- basename(s2_path)
          nameinfo_regex <- s2_regex$compactname_main_path$regex
          nameinfo_elements <- list(s2_regex$compactname_main_path$elements)
        } else if (s2_type=="singlegranule") {
          nameinfo_target <- c(basename(s2_path), basename(dirname(s2_main_xml)))
          nameinfo_regex <- c(s2_regex$compactname_granule_path$regex, s2_regex$compactname_main_path$regex)
          nameinfo_elements <- list(s2_regex$compactname_granule_path$elements, s2_regex$compactname_main_path$elements)
        }
      }
      
    }
    
    if ("prod_type" %in% info) { # return the type if required
      metadata[["prod_type"]] <- s2_type
    }
    if ("version" %in% info) { # return the version if required
      metadata[["version"]] <- s2_version
    }
    if ("xml_main" %in% info) { # return the path of the main xml file, if required
      metadata[["xml_main"]] <- s2_main_xml
    }
    if ("xml_granules" %in% info) { # return the version if required
      metadata[["xml_granules"]] <- s2_granules_xml
    }
    
    
    # scan
    metadata_nameinfo <- list()
    for (i in seq_along(nameinfo_target)) {
      for (sel_el in nameinfo_elements[[i]]) {
        metadata_nameinfo[[sel_el]] <- gsub(
          nameinfo_regex[i],
          paste0("\\",which(nameinfo_elements[[i]]==sel_el)),
          nameinfo_target[i])
        # format if it is a date or a time
        if (length(grep("\\_datetime",sel_el))==1) {
          metadata_nameinfo[[sel_el]] <- as.POSIXct(metadata_nameinfo[[sel_el]], format="%Y%m%dT%H%M%S", tz="UTC")
        }
        # return if nameinfo is required
        if (sel_el %in% info) {
          metadata[[sel_el]] <- metadata_nameinfo[[sel_el]]
        }
      }
    }
    s2_level <- metadata_nameinfo[["level"]] # used as base info
    
    # info on tile[s]
    if (any(c("tiles","utm") %in% info)) {
      av_tiles <- gsub(
        s2_regex[[paste0(s2_version,"name_granule_path")]]$regex,
        paste0("\\",which(s2_regex[[paste0(s2_version,"name_granule_path")]]$elements=="id_tile")),
        basename(dirname(s2_granules_xml)))
      if ("tiles" %in% info) {
        metadata[["tiles"]] <- av_tiles
      }
      if ("utm" %in% info) {
        metadata[["utm"]] <- as.integer(unique(substr(av_tiles,1,2)))
      }
    }
    
    # if requested, give band names
    if ("jp2list" %in% info) {
      
      # compute elements
      jp2_listall <- list.files(s2_path, s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$regex, recursive=TRUE, full.names=FALSE)
      jp2_bandname <- gsub(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$regex,
                           paste0("\\",which(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$elements == "bandname")),
                           basename(jp2_listall))
      jp2_layertype <- gsub(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$regex,
                            paste0("\\",which(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$elements == "additional_product")),
                            basename(jp2_listall))
      jp2_res <- gsub(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$regex,
                      paste0("\\",which(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$elements == "res")),
                      basename(jp2_listall))
      jp2_tile <- gsub(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$regex,
                       paste0("\\",which(s2_regex[[paste0(s2_version,"name_L",s2_level,"_jp2")]]$elements == "id_tile")),
                       basename(jp2_listall))
      # corrections for compact names
      if (s2_version=="compact") {
        jp2_layertype[grep("^B[0-9A]{2}$",jp2_bandname)] <- "MSI"
        jp2_layertype[jp2_layertype!="MSI"] <- jp2_bandname[jp2_layertype!="MSI"]
        jp2_bandname[jp2_layertype!="MSI"] <- ""
      }
      
      # correction B8A -> B08 (only one between them is used)
      jp2_bandname[jp2_bandname=="B8A"] <- "B08"
      
      # output data.frame
      jp2_list <- data.frame("layer" = basename(jp2_listall),
                             "tile" = jp2_tile,
                             "type" = jp2_layertype,
                             "band" = jp2_bandname,
                             "res" = jp2_res,
                             "relpath" = jp2_listall,
                             stringsAsFactors=FALSE)
      metadata[["jp2list"]] <-jp2_list[with(jp2_list, order(band,type,res,tile)),]
      
    }
    
    # if necessary, read the file for further metadata
    if (any(info_gdal %in% info)) {
      
      s2_gdal <- py$gdal$Open(s2_xml)
      # in case of error (old names), try to read a single granule
      if (s2_type=="product" & is(s2_gdal,"python.builtin.NoneType")) {
        first_granule <- list.files(file.path(s2_path,"GRANULE"),full.names=TRUE)[1]
        first_granule_xml <- list.files(first_granule,s2_regex[[paste0(s2_version,"name_granule_xml")]]$regex,full.names=TRUE)
        s2_gdal <- py$gdal$Open(first_granule_xml)
      }
      
    }
    
  }
  
  # If s2 is a gdal object, read metadata directly
  if (is(s2, "osgeo.gdal.Dataset")) {
    s2_gdal <- s2
  }
  
  # retrieve metadata from file content
  if (exists("s2_gdal")) {
    
    # Read metadata
    if ("clouds" %in% info) {
      metadata[["clouds"]] <- py_to_r(s2_gdal$GetMetadata()[["CLOUDY_PIXEL_PERCENTAGE"]])
    }
    if ("direction" %in% info) {
      metadata[["direction"]] <- py_to_r(s2_gdal$GetMetadata()[["DATATAKE_1_SENSING_ORBIT_DIRECTION"]])
    }
    if ("orbit_n" %in% info) {
      metadata[["orbit_n"]] <- py_to_r(s2_gdal$GetMetadata()[["DATATAKE_1_SENSING_ORBIT_NUMBER"]])
    }
    if ("preview_url" %in% info) {
      metadata[["preview_url"]] <- py_to_r(s2_gdal$GetMetadata()[["PREVIEW_IMAGE_URL"]])
    }
    if ("proc_baseline" %in% info) {
      metadata[["proc_baseline"]] <- py_to_r(s2_gdal$GetMetadata()[["PROCESSING_BASELINE"]])
    }
    # if ("level" %in% info) {
    #   metadata[["level"]] <- py_to_r(s2_gdal$GetMetadata()[["PROCESSING_LEVEL"]])
    # }
    if ("sensing_datetime" %in% info) {
      start_time <- as.POSIXct(
        py_to_r(s2_gdal$GetMetadata()[["PRODUCT_START_TIME"]]), format="%Y-%m-%dT%H:%M:%S", tz="UTC")
      stop_time <- as.POSIXct(
        py_to_r(s2_gdal$GetMetadata()[["PRODUCT_STOP_TIME"]]), format="%Y-%m-%dT%H:%M:%S", tz="UTC")
      metadata[["sensing_datetime"]] <- if (start_time == stop_time) {
        start_time
      } else {
        c(start_time, stop_time)
      }
    }
    if ("nodata_value" %in% info) {
      metadata[["nodata_value"]] <- py_to_r(s2_gdal$GetMetadata()[["SPECIAL_VALUE_NODATA"]])
    }
    if ("saturated_value" %in% info) {
      metadata[["saturated_value"]] <- py_to_r(s2_gdal$GetMetadata()[["SPECIAL_VALUE_SATURATED"]])
    }
    
  }
  
  # return
  if (action == "rm_invalid") {
    return(invisible(FALSE))
  } else if (length(metadata)>1) {
    return(metadata)
  } else {
    return(unlist(metadata))
  }
  
}
