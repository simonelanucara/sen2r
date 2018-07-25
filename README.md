
-   PROVA CAMBIAMENTO
-   [An R toolbox to find, download and preprocess Sentinel-2 data](#an-r-toolbox-to-find-download-and-preprocess-sentinel-2-data)
    -   [Warning](#warning)
    -   [Installation](#installation)
    -   [Usage](#usage)
    -   [Credits](#credits)

<!-- README.md is generated from README.Rmd. Please edit that file -->
[![Travis-CI Build Status](https://travis-ci.org/ranghetti/sen2r.svg?branch=master)](https://travis-ci.org/ranghetti/sen2r) [![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1240384.svg)](https://doi.org/10.5281/zenodo.1240384) [![CRAN\_Status\_Badge](http://www.r-pkg.org/badges/version/sen2r)](https://cran.r-project.org/package=sen2r) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](http://www.gnu.org/licenses/gpl-3.0)

<img src="man/figures/sen2r_logo_200px.png" width="200" height="113" align="right" />

An R toolbox to find, download and preprocess Sentinel-2 data
=============================================================

<span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span> is an R library which helps to download and preprocess Sentinel-2 optical images. The purpose of the functions contained in the library is to provide the instruments required to easily perform (and eventually automate) all the steps necessary to build a complete Sentinel-2 processing chain, without the need of any manual intervention nor the needing to manually integrate any external tool.

In particular, <span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span> allows to:

-   retrieve the list of available products on a selected area (which can be provided by specifying a bounding box, by loading a vector file or by drawing it on a map) in a given time window;
-   download the required SAFE Level-1C products, or retrieve the required SAFE Level-2A products by downloading them (if available) or downloading the corresponding Level-1C and correcting them with **sen2cor**;
-   obtain the required products (Top of Atmosphere radiances, Bottom of Atmosphere reflectances, Surface Classification Maps, True Colour Images) clipped on the specified area (adjacent tiles belonging to the same frame are merged);
-   mask cloudy pixels (using the Surface Classification Map as masking layer);
-   computing spectral indices.

Setting the execution of this processing chain is particularly easy using the <span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span> GUI, which allows to set the parameters, to directly launch the main function or to save them in a JSON file which can be used to launch the processing at a later stage.

The possibility to launch the processing with a set of parameters saved in a JSON file (or directly passed as function arguments) makes easy to build scripts to automatically update an archive of Sentinel-2 products. Specific processing operations (i.e. applying **sen2cor** on Level-1c SAFE products, merging adjacent tiles, computing spectral indices from existing products) can also be performed using intermediate functions (see [usage](#usage)).

Warning
-------

This package is under construction (current version is [pre-release 0.3.3](https://github.com/ranghetti/sen2r/releases/tag/v0.3.3)). Please refer to the [crontab of release 0.4.0](https://github.com/ranghetti/sen2r/milestone/3) to know which implementations should already be performed.

Installation
------------

<span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span> is supported over Linux and Windows operating systems; the support for Mac will be added soon.

The package can be installed from GitHub with the R package **devtools**. To do it:

1.  install the package **devtools**, if missing:

    ``` r
    install.packages("devtools")
    ```

2.  load it and install <span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span>:

    ``` r
    library(devtools)
    install_github("ranghetti/sen2r")
    ```

This will install the R package along with its R dependences, containing all the functions necessary to preprocess data.

To run the functions correctly, some external dependences are required:

-   [**GDAL**](http://www.gdal.org) (with support for JP2OpenJPEG format): this is a mandatory dependency, needed for all the processing operations and to retrieve metadata from SAFE products;
-   [**sen2cor**](http://step.esa.int/main/third-party-plugins-2/sen2cor) is used to perform atmospheric correction of Sentinel-2 Level-1C products: it is required by the package, unless you choose not to correct products locally (using only Level-1C – TOA products or dowloading directly Level-2A products).
-   **Wget** is the downloader used by the package; it is required to work online.
-   [**aria2**](https://aria2.github.io) is an alternative downloader which can be used to faster the download of SAFE archives; it can be optionally installed and used.

These dependences can be graphically checked launching the function

``` r
library(sen2r)
check_sen2r_deps()
```

This function opens a GUI which help to check that they are satisfied; if some of them are missing, follow the instructions provided by the GUI to install them (on Windows, the GUI allows to install them directly).

<!-- Atmospheric correction is performed using [sen2cor](http://step.esa.int/main/third-party-plugins-2/sen2cor): 
the package will automatically download and install it at first use,
or by running function [`install_sen2cor()`](reference/install_sen2cor.md).
Please notice that the use of sen2cor algorythm was not yet possible under MAC.

Preprocessing functions make use of [GDAL](http://www.gdal.org), which must 
support JPEG2000 format. On Windows, it is strongly recommended to install it 
using the [OSGeo4W installer](http://download.osgeo.org/osgeo4w/osgeo4w-setup-x86_64.exe)
in advanced mode, and checking the installation of `openjpeg` library. -->
Usage
-----

The simplest way to use <span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span> is to execute it in interactive mode:

``` r
library(sen2r)
sen2r()
```

this opens a GUI which allows to set the required processing parameters, and then launches the main function.

<p style="text-align:center;">
<a href="https://raw.githubusercontent.com/ranghetti/sen2r/master/man/figures/sen2r_gui_sheet1.jpg" target="_blank"> <img src="man/figures/sen2r_gui_sheet1_small.png"> </a> <a href="https://raw.githubusercontent.com/ranghetti/sen2r/master/man/figures/sen2r_gui_sheet2.jpg" target="_blank"> <img src="man/figures/sen2r_gui_sheet2_small.png"> </a> <a href="https://raw.githubusercontent.com/ranghetti/sen2r/master/man/figures/sen2r_gui_sheet3.jpg" target="_blank"> <img src="man/figures/sen2r_gui_sheet3_small.png"> </a> <a href="https://raw.githubusercontent.com/ranghetti/sen2r/master/man/figures/sen2r_gui_sheet4.jpg" target="_blank"> <img src="man/figures/sen2r_gui_sheet4_small.png"> </a>
</p>
Alternatively, [`sen2r()`](reference/sen2r.md) can be launched with a list of parameters (created with [`s2_gui()`](reference/s2_gui.md)) or passing manually the parameters as arguments of the function (see [the documentation of the function](reference/sen2r.md) for further details).

Other specific functions can be used to run single steps separately:

-   [`s2_list()`](reference/s2_list.md) to retrieve the list of available Sentinel-2 products basing on input parameters;
-   [`s2_download()`](reference/s2_download.md) to download Sentinel-2 products;
-   [`sen2cor()`](reference/sen2cor.html) to correct level-1C products using [sen2cor](http://step.esa.int/main/third-party-plugins-2/sen2cor);
-   [`s2_translate()`](reference/s2_translate.md) to convert Sentinel-2 products from SAFE format to a format managed by GDAL;
-   [`s2_merge()`](reference/s2_merge.md) to merge Sentinel-2 tiles which have the same date and orbit;
-   [`gdal_warp()`](reference/gdal_warp.md) to clip, reproject and warp raster files (this is a wrapper to call [gdal\_translate](http://www.gdal.org/gdal_translate.html) or [gdalwarp](http://www.gdal.org/gdalwarp.html) basing on input parameters);
-   [`s2_mask()`](reference/s2_mask.md) to apply a cloud mask to Sentinel-2 products;
-   [`s2_calcindices()`](reference/s2_calcindices.md) to compute maps of spectral indices from Sentinel-2 Surface Reflectance multiband raster files;
-   [`s2_thumbnails()`](reference/s2_thumbnails.md) to generate RGB thumbnails (JPEG or PNG) of the products.

Credits
-------

<a href="http://www.irea.cnr.it" ref="_blank"> <img src="man/figures/irea_logo_200px.png" height="100" align="left" /></a> <span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span> is being developed by Luigi Ranghetti and Lorenzo Busetto ([IREA-CNR](http://www.irea.cnr.it)), and it is released under the [GNU General Public License version 3](https://www.gnu.org/licenses/gpl-3.0.html) (GPL‑3).

The [<span style="color:#5793dd;vertical-align:top;font-size:90%;font-weight:normal;">sen</span><span style="color:#6a7077;vertical-align:baseline;font-size:115%;font-weight:bolder;">2</span><span style="color:#2f66d5;vertical-align:baseline;font-size:90%;font-weight:bold;">r</span> logo](https://raw.githubusercontent.com/ranghetti/sen2r/master/man/figures/sen2r_logo_200px.png), partially derived from the [R logo](https://www.r-project.org/logo), is released under the [Creative Commons Attribution-ShareAlike 4.0 International license](https://creativecommons.org/licenses/by-sa/4.0) (CC-BY-SA 4.0).

To cite this library, please use the following entry:

Ranghetti, L. and Busetto, L. (2018). *sen2r: an R toolbox to find, download and preprocess Sentinel-2 data*. R package version 0.3.3. DOI: [10.5281/zenodo.1240384](https://ranghetti.github.io/sen2r).

``` bibtex
@Manual{sen2r,
  title  = {sen2r: an R toolbox to find, download and preprocess Sentinel-2 data},
  author = {Luigi Ranghetti and Lorenzo Busetto},
  year   = {2018},
  note   = {R package version 0.3.3},
  doi    = {10.5281/zenodo.1240384},
  url    = {https://ranghetti.github.io/sen2r},
}
```
