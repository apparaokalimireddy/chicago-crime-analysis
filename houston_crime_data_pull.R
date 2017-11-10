rm(list=ls())
library(gdata)
downloadXlsFiles<-function(years=c(12, 13, 14, 15, 16, 17),months=c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"), first=TRUE, max_yr=17, max_mt='aug') {
  base_url<-"http://www.houstontx.gov/police/cs/xls/NNNNN.xls"
  for(y in years) {
    for(m in months) {
      if (y == max_yr && m == max_mt)
        break;
      url<-gsub("NNNNN", paste(m,y,sep=""), base_url,fixed=TRUE)
      df<-read.xls(url)
      if (first) {
        write.table(df, file="houston_crimes.csv", row.names=FALSE, col.names=TRUE,append=FALSE, sep=",")
        first<-FALSE
      } else {
        write.table(df, file="houston_crimes.csv", row.names=FALSE, col.names=FALSE,append=TRUE, sep=",")
      }
    }
  }
}
# Run download XLS files and save to csv file.
downloadXlsFiles(years=c(12, 13, 14, 15, 16, 17),months=c("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec"), first=TRUE, max_yr=17, max_mt='aug')
