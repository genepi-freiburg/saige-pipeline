calc_lambda <- function(pval) {
	pval2 <- pval[!is.na(pval)]
	if (length(pval2) == 0) {
		return(NA)
	} else {
		chisq <- qchisq(1 - pval2, 1)
		lambda <- median(chisq) / qchisq(0.5, 1)
		return(lambda)
	}
}

