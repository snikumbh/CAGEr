% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/Annotations.R
\name{ranges2names}
\alias{ranges2names}
\title{ranges2names}
\usage{
ranges2names(rangesA, rangesB)
}
\arguments{
\item{rangesA}{A \code{\link{GRanges}} object.}

\item{rangesB}{A second GRanges object.}
}
\value{
A \code{\link{Rle}} character vector of same length as the \code{rangesA}
GRanges object, indicating one name or a semicolon-separated list of names from
the each \code{rangesB} object.
}
\description{
Intersection of genomic ranges
}
\details{
This private (non-exported) function intersects two genomic ranges and
for each element of the first object returns the name of the elements of
the second object that it intersects with.
}
\examples{
names(exampleZv9_annot) <- exampleZv9_annot$gene_name
CAGEr:::ranges2names(CTSScoordinatesGR(exampleCAGEexp), exampleZv9_annot)

}
\seealso{
Other CAGEr annotation functions: \code{\link{annotateCTSS}},
  \code{\link{plotAnnot}}, \code{\link{ranges2annot}},
  \code{\link{ranges2genes}}
}
\author{
Charles Plessy
}
