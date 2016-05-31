require(data.table)
require(dplyr)
require(readr)
require(maps)
require(mapdata)
require(sp)
#### load original positions ####
rl <- read.csv("release_locations.txt", header=FALSE)
rl$ID <- seq_len(nrow(rl))

mypath <- getwd() #paste0('D:/MPA_particles//output//',year,'//',day,'//',bin)
filenames <- list.files(path=mypath, pattern=glob2rx("*para*"), full.names=TRUE,recursive=T)
datalist <- lapply( filenames, read_csv, col_names = F )
dataset <- rbindlist(datalist)
setnames(dataset,names(dataset),c("long","lat","Z","Out","site"))
dataset$ID <- seq_len(nrow(rl))
dataset$filename <- rep(filenames,do.call(rbind, lapply(datalist, function(x) dim(x)[1])))

x <- matrix(unlist(sapply(dataset$filename,strsplit,"/")),nrow=length(dataset$filename),byrow=T)
dataset$time <- as.numeric(substr(x[,dim(x)[2]],10,12))
rm(x)

#### plot dispersal ####
xlim <- c(-75,-45)
ylim <- c(40,57)
proj <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
map('worldHires',fill=TRUE,col='lightgrey',border='transparent',xlim=xlim,ylim=ylim)
box()
settle_loc <- read.csv("release_locations.txt", header=FALSE)
coordinates(rl) <- ~ V1 + V2
proj4string(rl) <- CRS(proj)
points(rl,pch=21,bg="deepskyblue2",cex=0.8)
for(i in seq_len(nrow(rl))){
    lines(dataset$long[dataset$ID==i],dataset$lat[dataset$ID==i])
}

