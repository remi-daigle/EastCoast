require(rgdal)
require(rgeos)
require(maptools)

grid <- readOGR(dsn = "shapefiles",layer = "Hxg45ths")
# grid <- readOGR(dsn = "shapefiles",layer = "big_grid")
d.polygon <- readOGR(dsn = "shapefiles",layer = "domain.polygon")
d.polygon <- spTransform(d.polygon,CRS(proj4string(grid)))
# bbox(grid)
# bbox(d.polygon)

# plot(d.polygon[d.polygon$mask==1,],col='blue')
# 
# plot(grid,add=T,col='green')

# bb <- bbox(grid[c(1:10),])
# bb[1,1] <- bb
# plot(grid@polygons[[1]]@Polygons[[1]]@coords,xlim=bb[1,],ylim=bb[2,])
# points(grid@polygons[[6]]@Polygons[[1]]@coords,col='blue',pch=19)

dx <- (grid@polygons[[2]]@Polygons[[1]]@coords[,2]-grid@polygons[[1]]@Polygons[[1]]@coords[,2])[1]
dy <- (grid@polygons[[5]]@Polygons[[1]]@coords[,1]-grid@polygons[[1]]@Polygons[[1]]@coords[,1])[1]


# test <- which(gTouches(grid[5,],grid,byid=T))
# plot((grid[1:100,])[test,],col='yellow')
# plot(grid[5,],add=T,col="blue")
# plot(grid[1:100,],add=T)

# make.spatial.poly <- function(coords,IDs,proj){
#     SpatialPolygons(list(
#         Polygons(
#             list(Polygon(coords)),
#             ID=IDs)
#     ),proj4string = proj)
# }
d.outline <- gBuffer(gUnionCascaded(d.polygon[d.polygon@data$mask==1,]),0,byid=T)
# plot(d.outline,lwd=4,xlim=c(305894.1,750853.0),ylim=c(4997762,5238281))
# plot(gBuffer(d.outline,0,byid=T),add=T,border='blue',lwd=4)

# d.outline <- gUnionCascaded(d.polygon[d.polygon@data$mask==1,])
proj4string(d.outline) <- proj4string(d.polygon)
# rm(list=ls(pattern="spdf"))
# plot(gDifference(gBuffer(grid,1000,byid=T),d.outline))
# d.outline <- gDifference(d.outline,grid)

x <- gWithin(grid,d.outline,byid=T)
grid <- grid[as.vector(x),]

i.done <- 1
block <- 499
while(max(i.done)<(length(grid)+2709)){
    
#     ptm <- proc.time()
#     
#     test <- gTouches(grid[i:(i+block),],grid,byid=T)
#     proc.time() - ptm
    
    for(i in seq(max(i.done),length(grid),block+1)){
        # ptm <- proc.time()
        count <- length(grid)+2709
        print(paste0("done = ",max(i.done)," and grid = ",count))
        spdf1 <- elide(grid[i:(i+block),],shift=c(0,dx))      # plus dx
        spdf2 <- elide(grid[i:(i+block),],shift=c(0,-dx))     # minus dx
        spdf3 <- elide(grid[i:(i+block),],shift=c(dy,-dx/2))  # plus dy minus dx/2
        spdf4 <- elide(grid[i:(i+block),],shift=c(dy,dx/2))   # plus dy plus dx/2
        spdf5 <- elide(grid[i:(i+block),],shift=c(-dy,-dx/2)) # minus dy minus dx/2
        spdf6 <- elide(grid[i:(i+block),],shift=c(-dy,dx/2))  # minus dy plus dx/2
        
        for(j in 2:6) {
            index <- apply(gCovers(gBuffer(spdf1,width=100,byid=T),get(paste0("spdf",j)),byid = TRUE),1,any)
            spdf1 <- rbind(spdf1,spChFIDs(get(paste0("spdf",j)),paste0("spdf",j,sprintf("%03d", 1:(block+1))))[!index,])
        }
        proj4string(spdf1) <- proj4string(grid)
        index <- !(apply(gCovers(gBuffer(spdf1,width=100,byid=T),grid,byid = TRUE),2,any))&
            apply(gCovers(d.outline,spdf1,byid = TRUE),1,any)
        if(sum(index)>0){
            grid <- rbind(grid,spChFIDs(spdf1[index,],as.character(count:(count+sum(index)-1))))
        }
        count <- length(grid)+2709
        i.done <- c(i.done,i+block)
        # proc.time() - ptm

    }
}


rlbad <- read.csv("release_locations_bad.txt",col.names = c("x","y","a","b","c"),header=F)
x <- SpatialPoints(rlbad[,1:2],CRS("+proj=longlat +ellps=WGS84 +no_defs"))
x <- spTransform(x,CRS(proj4string(grid)))

y <- apply(gContains(grid,x,byid=T),2,any)
grid <- grid[as.vector(!y),]

writeOGR(grid,dsn = "shapefiles",layer = "big_grid",driver = "ESRI Shapefile",overwrite_layer = TRUE)

### test release locations ###
x <- SpatialPoints(coordinates(grid),CRS(proj4string(grid)))
x <- spTransform(x,CRS("+proj=longlat +ellps=WGS84 +no_defs"))
rl <- data.frame(cbind(x=x@coords[,1],y=x@coords[,2],a=0,b=0,c=1))
write.table(rl,"release_locations.txt",sep=",",row.names=F,col.names=F)
