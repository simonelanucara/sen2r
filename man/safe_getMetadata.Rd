% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/safe_getMetadata.R
\name{safe_getMetadata}
\alias{safe_getMetadata}
\alias{rm_invalid_safe}
\title{Get information from S2 file name or metadata}
\usage{
safe_getMetadata(s2, info = "all")

rm_invalid_safe(s2)
}
\arguments{
\item{s2}{A Sentinel-2 product, being both a \code{character} (path of an
existing product, or simply product name) or python object of class
\code{osgeo.gdal.Dataset}. This input parameter
can be the main path of a S2 file, the path of the xml with metadata,
the path of a single granule, the xml path of a single granule, or a
'osgeo.gdal.Dataset' object (obtained reading the product with python).
If the product does not exist locally, the function can run only with
option \code{info = "nameinfo"} (see below).}

\item{info}{(optional) A character vector with the list of the metadata
which should be provided.
Accepted values are:
\itemize{
\item \code{"all"} (default): all the retrevable metadata are provided;
\item \code{"fileinfo"}: only the metadata obtained by scanning the file name
and product structure (without opening it with GDAL) are provided.
\item \code{"nameinfo"}: only the metadata obtained by scanning the file name
are provided (it is faster and there is no need to have downloaded
yet the file).
\item a vector of single specific information (one or more from the
followings):
\itemize{
\item \code{"prod_type"} ('singlegranule' or 'product');
\item \code{"version"} ('old' or 'compact');
\item \code{"tiles"} (vector with the tiles ID available in the product);
\item \code{"utm"} (vector with the UTM zones used in the product);
\item \code{"xml_main"} (name of the main XML file with metadata);
\item \code{"xml_granules"} (names of the XML with granule metadata);
\item \code{"level"} ('1C' or '2A');
\item \code{"creation_datetime"}, \code{"id_tile"}, \code{"mission"}, \code{"centre"},
\code{"file_class"}, \code{"id_orbit"}, \code{"orbit_number"},
\code{"sensing_datetime"}, \code{"id_baseline"}: metadata speficic of
the product type and version (they are returned only if
obtainable for the specified input);
\item \code{"clouds"}, \code{"direction"}, \code{"orbit_n"}, \code{"preview_url"},
\code{"proc_baseline"}, \code{"level"}, \code{"sensing_datetime"},
\code{"nodata_value"}, \code{"saturated_value"}:
information retrieved from the metadata stored in the XML file.
}

In this version, querying for specific elements requires the product
to be present in the filesystem; in future this will be changed
(see the second example for a workaround to scan for specific
elements without needing the file to have been downloaded).
}}
}
\value{
\code{safe_getMetadata()} returns a list of the output metadata;

\code{rm_invalid_safe()} returns TRUE if the \code{s2} product was removed,
FALSE elsewhere.
}
\description{
The function \code{safe_getMetadata()} scans a Sentinel2 product
(main path, granule path, main / granule xml file or GDAL object)
to retrieve information about the product.

The accessory function \code{rm_invalid_safe()} remove a SAFE archive in the case
it is not recognised by \code{safe_getMetadata()}.
}
\note{
License: GPL 3.0
}
\examples{
# Define product name
s2_examplename <-
  "/path/of/the/product/S2A_MSIL1C_20170603T101031_N0205_R022_T32TQQ_20170603T101026.SAFE"

# Return only the information retrevable from the file names (files are not scanned)
safe_getMetadata(s2_examplename, info="nameinfo")

# Return some specific information without scanning files
safe_getMetadata(s2_examplename, info="nameinfo")[c("level", "id_tile")]

# Return a single information without scanning files
# (in this case, the output is a vector instead than a list)
safe_getMetadata(s2_examplename, info="nameinfo")[["level"]]

\dontrun{

# Return all the available information
safe_getMetadata(s2_examplename)

# Return some specific information
safe_getMetadata(s2_examplename, info=c("tiles", "level", "id_tile"))

# Return a single information
safe_getMetadata(s2_examplename, info="clouds")

# Delete it if it is not recognised
rm_invalid_safe(s2_examplename)

}
}
\author{
Luigi Ranghetti, phD (2017, 2018) \email{ranghetti.l@irea.cnr.it}
}
