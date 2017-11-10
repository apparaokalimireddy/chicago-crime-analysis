#
rm(list=ls())
library(ggplot2)
library(scales)
library(reshape2)
crimesByYear<-crimesByYear[order(crimesByYear[1]),]
library(maps)
library(ggmap)
sql("use bighawk")

# Get all crime data from partition by year and communities tables
chicagoCrimes<-sql("select c.*, month(crime_date) as month, date_format(crime_date, 'u') as day, hour(crime_date) as hour, a.community as community from chicago_crimes_part_year c left join chicago_communities a on (c.community_area = a.community_area)")

# Get all crime data from la_crimes_part_year tables
laCrimes<-sql("select *, int(substr(date_occurred, 1, 2)) as month from la_crimes_part_year")

##
## Function:compareCrimes
## Compares LA and Chicago crimes 2010-2017
compareCrimes<-function() {
  chicagoCrimeCounts<-as.data.frame(count(groupBy(where(chicagoCrimes, chicagoCrimes$part_year >= 2010), "part_year")))
  chicagoCrimeCounts<-chicagoCrimeCounts[order(chicagoCrimeCounts[1]),]
  colnames(chicagoCrimeCounts) <- c("Year", "Chicago")

  laCrimeCounts<-as.data.frame(count(groupBy(laCrimes, "part_year")))
  laCrimeCounts<-laCrimeCounts[order(laCrimeCounts[1]),]
  colnames(laCrimeCounts) <- c("Year", "Los Angeles")

  df<-data.frame(chicagoCrimeCounts$Year,chicagoCrimeCounts$Chicago,laCrimeCounts$'Los Angeles')
  colnames(df)<-c('Year', 'Chicago','Los Angeles')
  df <- melt(df, id=c('Year'))

  ggplot(df) +
  geom_bar(aes(x = Year, y = value, fill = variable),
           stat="identity", position = "dodge", width = 0.7) +
  scale_fill_manual("City\n", values = c("red","blue"),
                    labels = c(" Chicago", " Los Angeles")) +
  ggtitle("Chicago Vs Los Angeles") +
  scale_y_continuous(labels = comma) +
  labs(x="\nYear",y="Crimes\n") +
  theme_bw(base_size = 14)
  ggsave(file="chicago-la.png")
}

##
## Function: crimeTrendByMonth(years)
##
laCrimeTrendByMonth<-function(years) {
  # Draw a line chart of a crime
  p<-ggplot()
  p<-p+xlab("Month") + ylab("Crimes")
  p<-p+ggtitle("Trend of Crimes By Month in LA")
  p<-p+theme(plot.title = element_text(hjust = 0.5, face="bold"))
  p<-p+scale_y_continuous(labels = comma)
  p<-p+scale_x_continuous(breaks=seq(1,12,by=1))
  for (y in years) {
    df<-as.data.frame(count(groupBy(where(laCrimes,laCrimes$part_year==y),"part_year", "month")))
    colnames(df) <- c("Year","Month","Count")
    p<-p+geom_line(data=df, aes(color=factor(Year), group=factor(Year), x=Month,y=Count), size=1.5)
    p<-p+labs(color = "Year")
  }
  ggsave(file=paste("la_crime_trend_by_month", ".png", sep=""), plot=p)
}


# Run Analysis
compareCrimes()
laCrimeTrendByMonth(years=c(2014,2015,2016))
