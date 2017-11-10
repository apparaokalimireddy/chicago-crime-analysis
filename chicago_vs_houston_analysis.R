rm(list=ls())
library(ggplot2)
library(scales)
library(reshape2)
library(maps)
library(ggmap)
sql("use bighawk")

# Get all chicago crime data from partition by year table
chicagoCrimes<-sql("select c.*, month(crime_date) as month, date_format(crime_date, 'u') as day, hour(crime_date) as hour from chicago_crimes_part_year c")

# Get all houston crime data from partition by year table
houstonCrimes<-sql("select h.*, month(crime_date) as month, date_format(crime_date, 'u') as day from houston_crimes_part_year h")

##
## Function: trendOfCrimes
## For a given vector of crime types - Shows trend(s) over the years
##
trendOfCrimesCvsH <- function(years) {
  # Get the crime counts by crime types as R dataframe
  chicagoCrimeCounts<-as.data.frame(count(groupBy(chicagoCrimes,"part_year")))
  chicagoCrimeCounts<-chicagoCrimeCounts[chicagoCrimeCounts$part_year %in% years, ]
  colnames(chicagoCrimeCounts) <- c("Year","Count")

  # Get the crime counts by crime types as R dataframe
  houstonCrimeCounts<-as.data.frame(count(groupBy(houstonCrimes,"part_year")))
  houstonCrimeCounts<-houstonCrimeCounts[houstonCrimeCounts$part_year %in% years, ]
  colnames(houstonCrimeCounts) <- c("Year","Count")

  # Draw a line chart of a crime
  p<-ggplot()
  p<-p+xlab("Year") + ylab("Crimes")
  p<-p+ggtitle("Chicago vs Houston Over the Years")
  p<-p+theme(plot.title = element_text(hjust = 0.5, face="bold"))
  p<-p+scale_y_continuous(labels = comma)
  p<-p+expand_limits(y=0, x=years[1])

  chicagoCrimeCounts<-chicagoCrimeCounts[order(chicagoCrimeCounts[1]),]
  p<-p+geom_line(data=chicagoCrimeCounts, aes(color="red", x=Year,y=Count))

  houstonCrimeCounts<-houstonCrimeCounts[order(houstonCrimeCounts[1]),]
  p<-p+geom_line(data=houstonCrimeCounts, aes(color="blue", x=Year,y=Count))
  ggsave(file=paste("chi_vs_hou_trend", ".png", sep=""), plot=p)
}
