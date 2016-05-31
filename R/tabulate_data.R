# uncomment to use, very time consuming
#!/usr/bin/env Rscript
require(data.table)
require(dplyr)
require(readr)
require(tidyr)

### Choose PLD ###
for(pld in seq(1,120,7)){

    #### load original positions ####
    rl <- read_csv("data/release_locations.txt", col_names=FALSE)
    memory.limit(32000)
    #### loop for each year #####
    # this is where the raw data from figshare was decompressed
    mypath='F:/East_coast/Raw'
    year_dir <- list.dirs(mypath,recursive=F)
    # if(pld==1) year_dir <- year_dir[c(5:10)]
    # year_dir <- year_dir[c(23)]
    for(mypath_y in year_dir){
        type=substr(mypath_y,nchar(mypath)+2,nchar(mypath)+2)
        print(paste(pld,substr(mypath_y,nchar(mypath)+3,nchar(mypath)+7)))
        #### tabulate output ####
        filenames <- list.files(path=mypath_y, pattern=glob2rx(paste0("*para    1",formatC(pld+1, width = 3, format = "d", flag = "0"),"*")), full.names=TRUE,recursive=T)
        datalist <- lapply( filenames, read_csv, col_names = F )
        dataset <- rbindlist(datalist)
        setnames(dataset,names(dataset),c("long","lat","Z","Out","site"))
        dataset$filename <- rep(filenames,do.call(rbind, lapply(datalist, function(x) dim(x)[1])))

        # x <- matrix(unlist(sapply(dataset$filename,strsplit,"/")),nrow=length(dataset$filename),ncol=7,byrow=T)
        # dataset$type <- substr(x[,4],1,1)
        # dataset$year <- as.numeric(substr(x[,4],2,5))
        # dataset$rday <- as.numeric(x[,5])
        # dataset$bin <- as.numeric(x[,6])
        # dataset$time <- as.numeric(substr(x[,7],10,12))
        # rm(x)
        dataset <- dataset %>%
            mutate(temp=substr(filename,nchar(mypath)+2,nchar(filename))) %>% 
            separate(temp,c("temp_type_year","rday","bin","time"),"/",convert=TRUE) %>% 
            separate(temp_type_year,c("type","year"),sep=1,convert=TRUE) %>% 
            mutate(time=as.integer(substr(time,9,12)))
            


        #### link release data to output ####
        filenames <- list.files(path="guillimin/EastCoast", pattern="rl.", full.names=TRUE,recursive=T)
        rllist <- lapply( filenames, read_csv, col_names = F )
        rl <- rbindlist(rllist)
        setnames(rl,names(rl),c("long0","lat0","Z0","delay","Site"))
        rl$Site <- rep(1:length(filenames),each=10000)[1:length(rl$Site)]
        for(i in 1:max(dataset$bin)){
                x <- rl$Site==i
                y <- dataset$bin==i
                dataset$long0[y] <- rl$long0[x]
                dataset$lat0[y] <- rl$lat0[x]
                dataset$Z0[y] <- rl$Z0[x]
                dataset$delay[y] <- rl$delay[x]
                dataset$Site[y] <- rl$Site[x]
        }
        write.csv(dataset,paste0("F:/East_coast/processed/",type,"_data_",dataset$year[1],"_pld_",pld,".csv"))
        
    }
}