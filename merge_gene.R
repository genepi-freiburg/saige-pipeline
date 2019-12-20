args = commandArgs(trailingOnly=T)
gene_fn = args[1]
aux_fn = args[2]
out_fn = args[3]

aux_tab = read.table(aux_fn, sep="\t", h=F)
colnames(aux_tab) = c("GENE", "CHR", "START", "STOP", "STRAND", "SYMBOL")
aux_tab_2 = data.frame(Gene=aux_tab$GENE, Symbol=aux_tab$SYMBOL)
print(paste("Read", nrow(aux_tab), "genes."))

gene_tab = read.table(gene_fn, sep=" ", h=T)
gene_count = nrow(gene_tab)
print(paste("Read", nrow(gene_tab), "results."))

result = merge(gene_tab, aux_tab_2)
merge_count = nrow(result)
print(paste("Merge result:", merge_count, "rows."))

if (merge_count != gene_count) {
	print("Count does not match - annotation problem?")
	stop()
}

print(paste("Writing result to:", out_fn))
write.table(result, out_fn, col.names=T, row.names=F, sep="\t", quote=F)

