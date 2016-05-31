require(RNetCDF)
require(sp)
require(rgeos)

fid<-open.nc("MD4grd_fromOPA_240x120.nc")
dat<-read.nc(fid)
print.nc(fid)
close.nc(fid)


# r <- 1:240
# c <- 1:120
x <- dat$lon_rho#[r,c]
y <- dat$lat_rho#[r,c]
z <- dat$mask_rho#[r,c]

plot(x,y)
# points(x[z==1],y[z==1],pch=19,col='blue')
# points(x[z==0],y[z==0],pch=19,col='green')

#### calculate nodes ####
node.x <- x[,1:ncol(x)-1]+(x[,2:ncol(x)]-x[,1:ncol(x)-1])/2
node.y <- y[,1:ncol(y)-1]+(y[,2:ncol(y)]-y[,1:ncol(y)-1])/2
# points(node.x,node.y,pch=19,col='yellow')

node.x2 <- x[1:nrow(x)-1,]+(x[2:nrow(x),]-x[1:nrow(x)-1,])/2
node.y2 <- y[1:nrow(y)-1,]+(y[2:nrow(x),]-y[1:nrow(y)-1,])/2
# points(node.x2,node.y2,pch=19,col='yellow')

node.x3 <- node.x[1:nrow(node.x)-1,]+(node.x[2:nrow(node.x),]-node.x[1:nrow(node.x)-1,])/2
node.y3 <- node.y[1:nrow(node.y)-1,]+(node.y[2:nrow(x),]-node.y[1:nrow(node.y)-1,])/2
# points(node.x3,node.y3,pch=19,col='yellow')

#### make.grid function ####
make.poly <- function(xy,r,c,z,corner=0){
    p <- Polygon(xy)
    ID <- paste0("r=",r,",c=",c)
    df <- data.frame(mask=z[r,c])
    
    if(corner!=0){
        ID <- paste0("corner=",corner," r=",r,",c=",c)
        df <- data.frame(mask=abs(z[r,c]-1))
    }

    ps <- Polygons(list(p),ID=ID)
    sps <- SpatialPolygons(list(ps),proj4string = CRS("+proj=longlat"))
    row.names(df) <- ID
    spdf <- SpatialPolygonsDataFrame(sps,df)
    return(spdf)
}

make.grid <- function(node.x,node.y,node.x2,node.y2,node.x3,node.y3,r,c,z,diag=FALSE){

    # identify points
    xy <- data.frame(rbind(
        cbind(x=node.x[r,(c-1):c],y=node.y[r,(c-1):c]),
        cbind(x=node.x2[(r-1):r,c],y=node.y2[(r-1):r,c]),
        cbind(x=as.vector(node.x3[(r-1):r,(c-1):c]),y=as.vector(node.y3[(r-1):r,(c-1):c]))))[c(1,5,3,7,2,8,4,6,1),]
    
    # make polygon
    if(diag){
        if(length(ls(pattern='corner_c.'))>0) rm(list=ls(pattern='corner_c.'))
        spdf <- make.poly(xy,r,c,z)
        if(z[r,c+1]==z[r-1,c]&z[r,c]!=z[r-1,c]) {corner_c4 <- make.poly(xy[c(4,3,5,4),],r,c,z,corner=4)}
        if(z[r,c+1]==z[r+1,c]&z[r,c]!=z[r+1,c]) {corner_c6 <- make.poly(xy[c(6,7,5,6),],r,c,z,corner=6)}
        if(z[r,c-1]==z[r-1,c]&z[r,c]!=z[r-1,c]) {corner_c2 <- make.poly(xy[c(2,3,1,2),],r,c,z,corner=2)}
        if(z[r,c-1]==z[r+1,c]&z[r,c]!=z[r+1,c]) {corner_c8 <- make.poly(xy[c(8,9,7,8),],r,c,z,corner=8)}
        
        if(length(ls(pattern='corner_c.'))>0){
            for(i in ls(pattern='corner_c.')) spdf@polygons[1] <- gDifference(spdf,get(i),drop_lower_td =T)@polygons
            spdf <- spChFIDs(spdf,paste0("r=",r,",c=",c))
            for(i in ls(pattern='corner_c.')) spdf <- rbind(spdf,get(i))
        }
    } else {
        spdf <- make.poly(xy,r,c,z)
    }
    
    return(spdf)
}

# mask edges
z[c(1,nrow(z)),] <- 0
z[,c(1,ncol(z))] <- 0

# if(exists("domain.polygon")) rm(domain.polygon)
rm(list=ls(pattern="spdf_"))
for(r in 2:(nrow(z)-1)){
    print(paste0("row ",r))
    for(c in 2:(ncol(z)-1)){
        # spdf <- make.grid(node.x,node.y,node.x2,node.y2,node.x3,node.y3,r,c,z,diag=TRUE)
        sprintf("spdf_%03d", r)
        assign(paste0(sprintf("spdf_%03d", r),sprintf("_%03d", c)),
               make.grid(node.x,node.y,node.x2,node.y2,node.x3,node.y3,r,c,z,diag=TRUE)
               )
#         if(exists("domain.polygon")){
#             domain.polygon <- rbind(domain.polygon,spdf)
#         } else {
#             domain.polygon <- spdf
#         }
    }
}
d.polygon <- do.call(rbind,mget(ls(pattern="spdf_")))
rm(list=ls(pattern="spdf_"))
# spdf <- rbind(get(ls(pattern="spdf_")[1]),get(ls(pattern="spdf_")[2]))
# spdf <- do.call(rbind,list(mget(ls(pattern="spdf_"))));
# plot(d.polygon)

# d.polygon <- domain.polygon
# rm(domain.polygon)
require(rgdal)
writeOGR(d.polygon,dsn="shapefiles",layer="domain.polygon",driver = "ESRI Shapefile",overwrite_layer=T)
plot(d.polygon[d.polygon$mask==1,],add=T,col='blue')

bb <- bbox(d.polygon)
rl <- data.frame(cbind(x=runif(10000,min=bb[1,1],max=bb[1,2]),y=runif(10000,min=bb[2,1],max=bb[2,2]),a=0,b=0,c=1))

rl.sp <- rl
coordinates(rl.sp)=c("x","y")


plot(d.polygon,col='red')
index <- apply(gCovers(d.polygon[d.polygon$mask==1,],rl.sp,byid = T),1,any)
# |apply(gCovers(gBuffer(d.polygon[d.polygon$mask==0,],0.05),rl.sp,byid = T),1,any)==0
points(rl.sp[index,])
rl <- rl[index,]
write.table(rl,"release_locations.txt",sep=",",row.names=F,col.names=F)

# rl <- rl[order(rl$y),]

rlbad <- read.csv("release_locations_bad.txt",col.names = c("x","y","a","b","c"),header=F)
points(rlbad$x,rlbad$y,pch=19,col='blue')

# 
# trial <- locator();print(paste0(trial$x,",",trial$y,",0,0,1"))
# 
# # success
# points(trial,pch=19,col='green')
# # fail
# rl_bad <- read.csv("release_locations_bad.txt", header=FALSE)
# points(rl_bad[,1],rl_bad[,2],pch=19,col='blue')

points(-62.9737957021111,37.9153030849416,pch=19,col='green')
