args <- commandArgs(trailingOnly=TRUE)
t <- args[1]
i <- args[2]
year <- args[3]

fn <- paste0("/sb/project/uxb-461-aa/Cuke-MPA/runs/E",year,"/",t,"/",i,"/release_locations.txt")

base <- "1999-01-01"
x=paste0(t,"-",year)
dt <- as.numeric(difftime(strptime(x, "%j-%Y",tz="GMT"),strptime(base,"%Y-%m-%d",tz="GMT")))
file <- ceiling(dt/60)
lag <- (dt%%60)*24*60*60

rl <- read.csv(fn,header = F)
rl[,4] <- rl[,4]+lag

write.table(rl,fn,sep=",",row.names=F,col.names=F)


system(paste0('sed -i -e "s/filenum = 1/filenum = ',file,'/g" /sb/project/uxb-461-aa/Cuke-MPA/runs/E',year,'/',t,'/',i,'/LTRANS.data'))