#!/usr/bin/Rscript

filename <- commandArgs(TRUE)

x <- read.csv(filename[1])

y <- data.frame(mean(as.numeric(as.character(x[-1,]))))

colnames(y) <- colnames(x)

write.table(y, paste0(substr(filename, 1, nchar(filename)-4), '_mean.csv'), row.names = F)
