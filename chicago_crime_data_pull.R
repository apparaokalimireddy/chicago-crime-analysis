rm(list=ls())
#
# Download chicago crime data using API
# App Token: xmw2FSjR6mdgXpFsavAqVjhh8
# Secret Token: 7tgFLVqxXHv0KwhzBmAt4nHm3Fu8crm-58pc
#
# Chicago crime data API URL

##
## Step 1: Download Chicago crime data
##
base_url<-"https://data.cityofchicago.org/resource/6zsd-86xi.csv?$limit=10000&$offset="
offset=0
url<-paste(base_url, offset, sep = "")
df<-read.csv(url)
write.table(df, file = "chicago_crimes.csv", append = FALSE, quote = TRUE, sep = ",",
            eol = "\n", na = "", dec = ".", row.names = FALSE,
            col.names = TRUE, qmethod = c("escape", "double"),
            fileEncoding = "")
nrecs<-nrow(df)
pages<-1
while (nrecs == 10000) {
  offset<-offset+10000
  url<-paste(base_url, format(offset, scientific=FALSE), sep = "")
  df<-read.csv(url)

  write.table(df, file = "chicago_crimes.csv", append = TRUE, quote = TRUE, sep = ",",
              eol = "\n", na = "", dec = ".", row.names = FALSE,
              col.names = FALSE, qmethod = c("escape", "double"),
              fileEncoding = "")
  nrecs<-nrow(df)
}
