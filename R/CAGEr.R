#' @include AllClasses.R CAGEexp.R CTSS.R
NULL

#' Analysis of CAGE (Cap Analysis of Gene Expression) sequencing data for
#' precise mapping of transcription start sites and promoterome mining
#' 
#' The _CAGEr_ package performs identification of transcription start sites and
#' frequency of their usage from input CAGE sequencing data, normalization of
#' raw CAGE tag count, clustering of TSSs into tag clusters (TC) and their
#' aggregation across multiple CAGE experiments to construct the promoterome.
#' It manipulates multiple CAGE experiments at once, performs expression
#' profiling across experiments both at level of individual TSSs and clusters of
#' TSSs, exports several different types of track files for visualization in the
#' UCSC Genome Browser, performs analysis of promoter width and detects
#' differential usage of TSSs (promoter shifting) between samples.  Multicore
#' option for parallel processing is supported on Unix-like platforms.
#' 
#' @author Vanja Haberle
#' 
#' @docType package
#' @name CAGEr-package
NULL
 
#' CAGEr objects
#' 
#' The _CAGEr_ package provides two classes of objects to load, contain and
#' process CAGE data:
#' 
#' * The [`CAGEset`] class is the original object format in _CAGEr_, as when
#'   published in Haberle _et al._, 2015. 
#'   
#' * The [`CAGEexp`] class is a new class format in 2017, which is based on the
#'   [`MultiAssayExperiment`] class.  In comparison with `CAGEset`, objects,
#'   `CAGEexp` objects benefit from a a more efficient data storage, using
#'   `DataFrame`s of run-length-encoded (`Rle`) integers, allowing for the
#'   loading and use of much larger transcriptome datasets.
#'  
#' Most _CAGEr_ functions support both classes interchangabely, and the `CAGEr`
#' class was created for methods that support both classes identically.
#' 
#' @references Haberle V, Forrest ARR, Hayashizaki Y, Carninci P and Lenhard B
#' (**2015**). \dQuote{CAGEr: precise TSS data retrieval and high-resolution
#' promoterome mining for integrative analyses.} _Nucleic Acids Research_,
#' 43, pp. e51., <http://nar.oxfordjournals.org/content/43/8/e51>
#' 
#' @aliases CAGEr
#' @import methods
#' @import BiocGenerics
#' @exportClass CAGEr

setClassUnion("CAGEr", c("CAGEset", "CAGEexp"))


#' @name getRefGenome
#' 
#' @title Attempt to load a BSgenome
#' 
#' @details Internal function that retreives a BSgenome object or throws an error if not available.
#' 
#' @return A BSgenome object
#' 
#' @param reference.genome
#' 
#' @author Charles Plessy
#' @importFrom utils installed.packages
#' 
#' @noRd

getRefGenome <- function(reference.genome) {
  if (is.null(reference.genome))
    stop("Can not run this function with a NULL genome; see ", sQuote('help("genomeName")'), ".")
  if(reference.genome %in% rownames(installed.packages()) == FALSE)
    stop("Requested genome is not installed! Please install required BSgenome package before running CAGEr.")
  requireNamespace(reference.genome)
  getExportedValue(reference.genome, reference.genome)
}

#' @name sampleLabels
#' 
#' @title Get and set sample labels
#' 
#' @description \code{sampleLabels} gets or sets the labels and colors of CAGE datasets
#' (samples) from \code{\link{CAGEr}} objects.
#' 
#' @param object A CAGEr object.
#' 
#' @return \code{sampleLabels} returns a named character vector representing labels of all
#' CAGE datasets present in the CAGEr object.  The vector values are the labels and the
#' vector names are the colors.
#' 
#' @note If no colors are supplied, then default colors will be assigned
#' usign the \code{rainbow} function.  Assigned colors are not guaranteed
#' to be stable.
#' 
#' @details In \code{CAGEexp} objects, renaming samples is possible only before
#' data is loaded.
#' 
#' @author Vanja Haberle
#' 
#' @examples 
#' sampleLabels(exampleCAGEset)
#' 
#' @family CAGEr accessor methods
#' @seealso \code{\link{setColors}}
#' 
#' @importFrom grDevices rainbow
#' @export

setGeneric("sampleLabels", function(object) standardGeneric("sampleLabels"))

#' @rdname sampleLabels

setMethod("sampleLabels", "CAGEset", function (object)
  object@sampleLabels)

#' @rdname sampleLabels

setMethod("sampleLabels", "CAGEexp", function (object) {
  sl <- object$sampleLabels
  if (! is.null(object$Colors)) {
    names(sl) <- object$Colors }
  else {
    names(sl) <- rainbow(length(sl))
  }
  sl
})

#' @rdname sampleLabels

setMethod("sampleLabels", "CTSS", function (object)
  object@metadata$sampleLabels)

#' @description \code{sampleList} is an accessory function for convenience
#' iteration in functions such as \code{\link{lapply}} or \code{\link{mapply}}.
#' There is no set method for \code{sampleList}.
#' 
#' @return \code{sampleList} returns a named list where elements and their
#' names are the sample names, for instance: \code{list(sampleA = "sampleA",
#' sampleB = "sampleB")}. Thus, after iterating on it with \code{lapply}, the
#' element names will be sample names.
#' 
#' @examples 
#' sampleList(exampleCAGEset)
#' 
#' @export
#' @rdname sampleLabels

setGeneric("sampleList", function(object) standardGeneric("sampleList"))

#' @rdname sampleLabels

setMethod("sampleList", "CAGEr", function (object) {
  l <- sampleLabels(object)
  names(l) <- l
  l
})

#' @name validSamples
#' @noRd
#' @title Private function
#' @details Check if a vector of strings or numbers can be used to identify a sample.

setGeneric("validSamples", function(object, x) standardGeneric("validSamples"))

setMethod("validSamples", "CAGEr", function (object, x){
  objName <- deparse(substitute(object))
  if(is.null(x))
      return(TRUE)
  if(inherits(x, "character"))
    if (all(x %in% sampleLabels(object)))
      return(TRUE)
  if(inherits(x, "integer") | inherits(x, "numeric"))
    if (all(x %in% seq_along(sampleLabels(object))))
      return(TRUE)
  stop("Sample(s) not found! Check ", sQuote(paste0("sampleLabels(", objName, ")")), ".")
})


#' @name .filterCtss
#' @noRd
#' @param threshold,nrPassThreshold Only CTSSs with signal \code{>= threshold} in
#'        \code{>= nrPassThreshold} experiments will be used for clustering and will
#'        contribute towards total signal of the cluster.
#' @param thresholdIsTpm Logical, is threshold raw tag count value (FALSE) or
#'        normalized signal (TRUE).
#' @title Private function
#' @details Check if a vector of strings or numbers can be used to identify a sample.

setGeneric(".filterCtss", function( object
                                  , threshold       = 0
                                  , nrPassThreshold = 1
                                  , thresholdIsTpm  = TRUE)
  standardGeneric(".filterCtss"))

setMethod(".filterCtss", "CAGEr", function (object, threshold, nrPassThreshold, thresholdIsTpm) {
	if (threshold == 0) return(Rle(TRUE))
  .filterCtss(CTSStagCountSE(object), threshold, nrPassThreshold, thresholdIsTpm)
})

setMethod(".filterCtss", "RangedSummarizedExperiment", function (object, threshold, nrPassThreshold, thresholdIsTpm) {
	if (threshold == 0) return(Rle(TRUE))
  assay <- ifelse(thresholdIsTpm, "normalizedTpmMatrix", "counts")
  if(assay == "normalizedTpmMatrix" & is.null(assays(object)[[assay]]))
    stop("Normalise the CAGEr object first with ", sQuote("normalizeTagCount()"), ".")
  nr.pass.threshold <- rowSums(DelayedArray(assays(object)[[assay]]) >= threshold)
  Rle(nr.pass.threshold >= min(nrPassThreshold, ncol(object)))
})
