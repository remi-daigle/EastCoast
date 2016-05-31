library(marmap)
library(rgdal)
library(raster)
library(rgeos)

# load master grid
grid <- readOGR("shapefiles","big_grid")
proj <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
grid <- spTransform(grid,CRS(proj))

# download bathy data
bb <- bbox(grid)
bathy <- getNOAA.bathy(lon1 = bb[1,1], lon2 = bb[1,2], lat1 = bb[2,1], lat2 = bb[2,2],resolution = 1,keep = TRUE)


# convert to raster and trim
r1 <- marmap::as.raster(bathy)
r1[r1<(-250)] <- 0
r1[r1!=0] <- 1


p <- rasterToPolygons(r1, dissolve=T,fun=function(x){x==1})
p <- spTransform(p, CRS(proj))
plot(p)

index <- apply(gIntersects(grid,p,byid=TRUE),2,any)
grid250 <- grid[index,]

rlbad <- read.csv("release_locations_bad.txt",col.names = c("x","y","a","b","c"),header=F)
x <- SpatialPoints(rlbad[,1:2],CRS("+proj=longlat +ellps=WGS84 +no_defs"))
x <- spTransform(x,CRS(proj4string(grid250)))

y <- apply(gContains(grid250,x,byid=T),2,any)
grid250 <- grid250[as.vector(!y),]

plot(x)
plot(grid250,add=T)
writeOGR(grid250,dsn = "shapefiles",layer = "grid250",driver = "ESRI Shapefile",overwrite_layer = TRUE)


### test release locations ###
x <- SpatialPoints(coordinates(grid250),CRS(proj4string(grid250)))
x <- spTransform(x,CRS("+proj=longlat +ellps=WGS84 +no_defs"))
rl <- data.frame(cbind(x=x@coords[,1],y=x@coords[,2],a=0,b=0,c=1))
write.table(rl,"release_locations.txt",sep=",",row.names=F,col.names=F)

#### segment release_locations.txt ####
rl <- read.csv("release_locations.txt",header = F)
n <- ceiling(nrow(rl)/10000)
for(i in 1:n) write.table(rl[((i-1)*10000+1):(i*10000),],paste0("rl_",i,".txt"),sep=",",row.names=F,col.names=F)
