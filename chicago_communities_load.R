# Create chicago_communities table and load the data
# Shapefiles downlaoded from:
# https://data.cityofchicago.org/Facilities-Geographic-Boundaries/Boundaries-Community-Areas-current-/cauq-8yn6
# And calculated cetroids of communities using service from:
# http://shpescape.com/ft/upload/
# output of which is saved as chicago_communities.csv file.
# Clean up communities csv file and load to Hive

df<-read.csv("chicago_communities_full.csv")
x<-df$geometry_pos
x <- df$geometry_pos
y <- regexpr('-{1,50}.{1,50}', x, TRUE)
z <- regexpr(',', x, TRUE)-1
longitude <- substr(x,y, z)

a <- df$geometry_pos
b <- regexpr(',{1,50}.{1,50}', a, TRUE)+1
c <- regexpr(',0', a, TRUE)-1
latitude <- substr(a,b,c)

df <- as.data.frame(cbind(df, latitude, longitude))
df<-df[, colnames(df) %in% c('community', 'area_numbe', 'latitude', 'longitude')]
colnames(df)[2]<-'community_area'

# Read demographics
# File obtained from https://fusiontables.google.com/DataSource?dsrcid=1647341
dem<-read.csv("Chicago Neighborhood Demographics.csv")
colnames(dem)[2]<-'community_area'
dem<-dem[, colnames(dem) %in% c('community_area', 'Percent.Black', 'Percent.Hispanic','Median.Income','Poverty.Rate','Unemployment.Rate','Total.Population')]

# Now merge into one dataframe
comb<-merge(x = df, y = dem, by = "community_area", all.x = TRUE)

# Read socio economics
soc<-read.csv("chicago_socio_economics.csv")
colnames(soc)[1]<-'community_area'
soc<-soc[, !(colnames(soc) %in% c('COMMUNITY.AREA.NAME'))]
colnames(soc)<-tolower(colnames(soc))

# Now merge
comb<-merge(x = comb, y = soc, by = "community_area", all.x = TRUE)

#Convert to Spark DataFrame and save to Hive table
sql("use bighawk")
rdf<-as.DataFrame(comb)
saveAsTable(rdf, "chicago_communities", mode="overwrite")
