#' @include GetMethods.R

#' @name cumulativeCTSSdistribution
#' 
#' @title Cumulative sums of CAGE counts along genomic regions
#' 
#' @description Calculates the cumulative sum of raw CAGE counts along each tag
#' cluster or consensus cluster in every sample within a CAGEr object.
#' 
#' @param object A [`CAGEr`] object
#' 
#' @param clusters `tagClusters` or `consensusClusters`.
#'        
#' @param useMulticore Logical, should multicore be used.
#'        `useMulticore = TRUE` has no effect on non-Unix-like platforms.
#' @param nrCores Number of cores to use when `useMulticore = TRUE`
#'        (set to `NULL` to use all detected cores).
#' 
#' @return For `CAGEset` objects, the slot `CTSScumulativesTagClusters`
#' (when `clusters = "tagClusters"`) or `CTSScumulativesConsensusClusters`
#' (when `clusters = "consensusClusters"`) of the will be occupied by the
#' list containing cumulative sum of the CAGE signal along genomic regions per
#' CAGE experiment.  In `CAGEexp` objects, cumulative sums are stored
#' in the metadata slot using the `RleList` class.
#' 
#' @author Vanja Haberle
#' 
#' @family CAGEr object modifiers
#' @family CAGEr clusters functions
#' 
#' @examples
#' CTSScumulativesTagClusters(exampleCAGEset)[[1]][1:6]
#' cumulativeCTSSdistribution(object = exampleCAGEset, clusters = "tagClusters")
#' CTSScumulativesTagClusters(exampleCAGEset)[[1]][1:6]
#' cumulativeCTSSdistribution(exampleCAGEset, clusters = "consensusClusters")
#' 
#' clusterCTSS( exampleCAGEexp, threshold = 50, thresholdIsTpm = TRUE
#'            , nrPassThreshold = 1, method = "distclu", maxDist = 20
#'            , removeSingletons = TRUE, keepSingletonsAbove = 100)
#' cumulativeCTSSdistribution(exampleCAGEexp, clusters = "tagClusters")
#' aggregateTagClusters( exampleCAGEexp, tpmThreshold = 50
#'                     , excludeSignalBelowThreshold = FALSE, maxDist = 100)
#' cumulativeCTSSdistribution(exampleCAGEexp, clusters = "consensusClusters")
#'            
#' @importFrom IRanges RleList
#' @export

setGeneric( "cumulativeCTSSdistribution"
          , function ( object, clusters = c("tagClusters", "consensusClusters")
                     , useMulticore = FALSE, nrCores = NULL)
              standardGeneric("cumulativeCTSSdistribution"))

#' @rdname cumulativeCTSSdistribution

setMethod( "cumulativeCTSSdistribution", "CAGEr"
         , function (object, clusters, useMulticore, nrCores) {
  objName <- deparse(substitute(object))
  message("\nCalculating cumulative sum of CAGE signal along clusters...")
  clusters <- match.arg(clusters)
  getClusters <- switch( clusters
                       , tagClusters       = tagClustersGR
                       , consensusClusters = consensusClustersGR)
  setClusters <- switch(clusters
                       , tagClusters       = `CTSScumulativesTagClusters<-`
                       , consensusClusters = `CTSScumulativesCC<-`)
  samples.cumsum.list <- lapply(sampleList(object), function(s) {
		message("\t-> ", s)
    ctss <- CTSSnormalizedTpmGR(object, s)
    if (!is.null(ctss$filteredCTSSidx))
      ctss <- ctss[ctss$filteredCTSSidx]
		.getCumsum( ctss         = ctss
              , clusters     = getClusters(object, s)
              , useMulticore = useMulticore, nrCores = nrCores)
	})
	if (inherits(object, "CAGEexp"))
    samples.cumsum.list <- lapply(samples.cumsum.list, RleList)
	object <- setClusters(object, samples.cumsum.list)
  assign(objName, object, envir = parent.frame())
  invisible(1)
})
