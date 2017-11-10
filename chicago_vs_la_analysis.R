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
laCrimes<-sql("select * from la_crimes_part_year")

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
