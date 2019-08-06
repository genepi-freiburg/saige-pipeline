library(gqq)
source("R/manhattan.R")
source("R/calc_lambda.R")

#' Performs box plots, histograms, Manhattan and QQ plot 
#' (unfiltered, MAF >1\%/INF >0.4 and MAF >5\%/INF >0.8.
#'
#' @param file_pattern file name of results (\%CHR\% spaceholder)
#' @param out_pdf output PDF file name
#' @param file_sep field separator
#' @export
#' @importFrom grDevices dev.off pdf
#' @importFrom graphics title boxplot hist par
#' @importFrom stats median qchisq
#' @importFrom gqq qq_plot
#' @importFrom utils head modifyList read.table
perform_qc_plots <- function(file_pattern, out_pdf, file_sep=" ") 
{
  print(paste("File name pattern: ", file_pattern, sep=""))
  print(paste("Output PDF: ", out_pdf, sep=""))
  
  overall = data.frame()
  for (chr in 1:22) {
  	chr_fn = gsub("%CHR%", as.character(chr), file_pattern)
  	if (!file.exists(chr_fn)) {
  		print(paste("Skipping non-existing file: ", chr_fn, sep=""))
  	} else {
  		print(paste("Reading in chromosome #", chr, " from file: ", chr_fn, sep=""))
  
  		data = read.table(chr_fn, header=T, sep=file_sep)
  		print(paste("Read ", nrow(data), " variants.", sep=""))
  		if (nrow(overall) == 0) {
  			overall = data
  		} else {
  			overall = rbind(overall, data)
  		}
  		print(paste("Current overall variant count: ", nrow(overall), sep=""))
  	}
  }
  
  if (nrow(overall) == 0) {
  	stop("don't have any data!")
  }
  
  print(summary(overall))
  
  
  do_plots <- function (overall, label) {
    lambda_overall = calc_lambda(overall$p.value)
    print(paste("Lambda (", label, "): ", lambda_overall, sep=""))
  
    par(mfcol=c(6,2))
    
    boxplot(overall$BETA, 
            horizontal = T, 
            xlab = paste("Effect size (", label, "), n=", nrow(overall), sep=""))
    
    boxplot(overall$SE, 
            horizontal = T, 
            xlab = paste("Standard error (", label, "), n=", nrow(overall), sep=""))
    
    boxplot(overall$p.value, 
            horizontal = T, 
            xlab = paste("P-value (", label, "), n=", nrow(overall), sep=""))
    
    boxplot(overall$imputationInfo, 
            horizontal = T, 
            xlab = paste("Imputation quality (", label, "), n=", nrow(overall), sep=""))
    
    boxplot(overall$AF_Allele2, 
            horizontal = T, 
            xlab = paste("Allele 2 frequency (", label, "), n=", nrow(overall), sep=""))
      
    boxplot(overall$N, 
            horizontal = T, 
            xlab = paste("Sample size (", label, "), n=", nrow(overall), sep=""))
    
    hist(overall$BETA, 
         xlab = paste("Effect size (", label, ")", sep = ""),
         breaks = 100,
         main = "", ylab = "")
    
    hist(overall$SE, 
         xlab = paste("Standard error (", label, ")", sep = ""),
         breaks = 100,
         main = "", ylab = "")
    
    hist(overall$p.value, 
         xlab = paste("P-value (", label, ")", sep = ""),
         breaks = 100,
         main = "", ylab = "")
    
    hist(overall$imputationInfo, 
         xlab = paste("Imputation quality (", label, ")", sep = ""),
         breaks = 100,
         main = "", ylab = "")
    
    hist(overall$AF_Allele2, 
         xlab = paste("Allele 2 frequency (", label, ")", sep = ""),
         breaks = 100,
         main = "", ylab = "")
    
    hist(overall$N, 
         xlab = paste("Sample size (", label, ")", sep = ""),
         breaks = 100,
         main = "", ylab = "")
    
    par(mfrow=c(1,1))
    
    mh_title = paste("Manhattan plot (", label, "), n=", nrow(overall), 
                     ", lambda=", round(lambda_overall, 3), sep="")
    manhattan.plot(overall$CHR, overall$POS, overall$p.value, main=mh_title)
    
    qq_plot(overall$p.value, highlight=-log10(5e-8))
    title(main=paste("QQ plot (", label, "), n=", nrow(overall), 
                     ", lambda=", round(lambda_overall, 3), sep=""))
  }
  
  pdf(out_pdf)
  
  do_plots(overall, "overall")
  
  print("Filtering for: MAF >1%, IMP >0.4")
  overall = overall[which(overall$AF_Allele2 > 0.01 & overall$AF_Allele2 < 0.99 & 
                            overall$imputationInfo > 0.4),]
  print(paste("Variants remaining: ", nrow(overall), sep=""))
  
  do_plots(overall, "MAF >1%, IMP >0.4")
  
  print("Filtering for: MAF >5%, IMP >0.8")
  overall = overall[which(overall$AF_Allele2 > 0.05 & overall$AF_Allele2 < 0.95 & 
                            overall$imputationInfo > 0.8),]
  print(paste("Variants remaining: ", nrow(overall), sep=""))
  
  do_plots(overall, "MAF >5%, IMP >0.8")
  
  dev.off()  
}
