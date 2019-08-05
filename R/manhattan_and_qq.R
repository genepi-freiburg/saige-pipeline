library(gqq)
source("manhattan.R")
source("lambda.R")

args = commandArgs(trailingOnly=T)
if (length(args) < 2) {
	stop("need fileNamePattern and outputPdf as arguments!")
}

file_pattern = args[1]
out_pdf = args[2]

file_sep = " "
if (length(args) > 2) {
	file_sep = args[3]
	print(paste("Using separator: '", sep, "'", sep=""))
}

print(paste("File name pattern: ", file_pattern, sep=""))
print(paste("Output PDF: ", out_pdf, sep=""))

overall = data.frame()
for (chr in 1:22) {
	chr_fn = gsub("%CHR%", as.character(chr), file_pattern)
	if (!file.exists(chr_fn)) {
		print(paste("Skipping non-existing file: ", chr_fn, sep=""))
	} else {
		print(paste("Reading in chromosome #", chr, " from file: ", chr_fn, sep=""))

		data = read.table(chr_fn, h=T, sep=file_sep)
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

lambda_overall = calc_lambda(overall$p.value)
print(paste("Lambda (unfiltered): ", lambda_overall, sep=""))

pdf(out_pdf)


mh_title = paste("Manhattan plot (unfiltered), n=", nrow(overall), ", lambda=", round(lambda_overall, 3), sep="")
manhattan.plot(overall$CHR, overall$POS, overall$p.value, main=mh_title)

qq_plot(overall$p.value, highlight=-log10(5e-8))
title(main=paste("QQ plot (unfiltered), n=", nrow(overall), ", lambda=", round(lambda_overall, 3), sep=""))

print("Filtering for: MAF >1%, IMP >0.4")
overall = overall[which(overall$AF_Allele2 > 0.01 & overall$AF_Allele2 < 0.99 & overall$imputationInfo > 0.4),]
print(paste("Variants remaining: ", nrow(overall), sep=""))

lambda_filter1 = calc_lambda(overall$p.value)
print(paste("Lambda (MAF >1%, IMP >0.4): ", lambda_filter1, sep=""))

mh_title = paste("Manhattan plot (MAF >1%, IMP >0.4), n=", nrow(overall), ", lambda=", round(lambda_filter1, 3), sep="")
manhattan.plot(overall$CHR, overall$POS, overall$p.value, main =mh_title)

qq_plot(overall$p.value, highlight=-log10(5e-8))
title(main=paste("QQ plot (MAF >1%, IMP >0.4), n=", nrow(overall), ", lambda=", round(lambda_filter1, 3), sep=""))

print("Filtering for: MAF >5%, IMP >0.8")
overall = overall[which(overall$AF_Allele2 > 0.05 & overall$AF_Allele2 < 0.95 & overall$imputationInfo > 0.8),]
print(paste("Variants remaining: ", nrow(overall), sep=""))

lambda_filter2 = calc_lambda(overall$p.value)
print(paste("Lambda (MAF >5%, IMP >0.8): ", lambda_filter2, sep=""))

mh_title = paste("Manhattan plot (MAF >5%, IMP >0.8), n=", nrow(overall), ", lambda=", round(lambda_filter2, 3), sep="")
manhattan.plot(overall$CHR, overall$POS, overall$p.value, main=mh_title)

qq_plot(overall$p.value, highlight=-log10(5e-8))
title(main=paste("QQ plot (MAF >5%, IMP >0.8), n=", nrow(overall), ", lambda=", round(lambda_filter2, 3), sep=""))

dev.off()
