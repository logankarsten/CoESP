ReadChrtout <- function(pathOutdir, 
                        idList=NULL,
                        gageList=NULL, rtlinkFile=NULL,
                        parallel=FALSE,
                        useDatatable=TRUE) {
    # Get files
    filesList <- list.files(path=pathOutdir, 
                                    pattern=glob2rx('*.CHRTOUT_DOMAIN*'), 
                                    full.names=TRUE)
    if (length(filesList)==0) stop("No matching files in specified directory.")
    # Compile link list
    if (!is.null(rtlinkFile)) {
        rtLink <- ReadRouteLink(rtlinkFile)
        if (useDatatable) rtLink <- data.table(rtLink)
    }
    if (is.null(idList)) {
        if (exists("rtLink")) {
            if (is.null(gageList)) {
                if (useDatatable) {
                    rtLink <- rtLink[site_no != '',]
                } else {
                    rtLink <- subset(rtLink, rtLink$site_no != '')
                    }
            } else {
                if (useDatatable) {
                    rtLink <- rtLink[site_no %in% gageList,]
                } else {
                    rtLink <- subset(rtLink, rtLink$site_no %in% gageList)
                }
            }
            idList <- unique(rtLink$link)
        }
    }
    
    # Single file read function
    ReadFile4Loop <- function(file., useDatatable.=TRUE) {
        out <- GetNcdfFile(file., variables=c("time"), exclude=TRUE, quiet=TRUE)
        dtstr <- basename(file.)
        dtstr <- unlist(strsplit(dtstr, "[.]"))[1]
        dtstr <- as.POSIXct(dtstr, format="%Y%m%d%H%M", tz="UTC")
        out$POSIXct <- dtstr
        if (useDatatable.) out<-data.table(out)
        out
    }
    
    # Loop through all files
    outList <- list()
    if (parallel) {
        packageList <- ifelse(useDatatable, c("ncdf4","data.table"), c("ncdf4"))
        outList <- foreach(file=filesList, .packages = packageList, 
                           .combine=c) %dopar% {
            out <- ReadFile4Loop(file)
            if (!is.null(idList)) {
                if (useDatatable) {
                    out <- out[station_id %in% idList,]
                } else {
                    out <- subset(out, out$station_id %in% idList)
                }
            }
            list(out)
        }
    } else {
        for (file in filesList) {
            out <- ReadFile4Loop(file)
            if (!is.null(idList)) {
                if (useDatatable) {
                    out <- out[station_id %in% idList,]
                } else {
                    out <- subset(out, out$station_id %in% idList)
                }
            }
            outList <- c(outList, list(out))
        }
    }
    if (useDatatable) {
        outDT <- data.table::rbindlist(outList)
    } else {
        outDT <- do.call("rbind", outList)
    }
    names(outDT)[names(outDT)=="streamflow"]<-"q_cms"
    names(outDT)[names(outDT)=="velocity"]<-"vel_ms"
    if (exists("rtLink")) {
        names(outDT)[names(outDT)=="station_id"]<-"link"
        if (useDatatable) {
            data.table::setkey(rtLink, "link")
            data.table::setkey(outDT, "link")
            outDT <- merge(outDT, rtLink[, c("link", "site_no"), with=FALSE], all.x=TRUE)
        } else {
            outDT <- plyr::join(outDT, rtLink[, c("link", "site_no")], by="link", type="left")
        }
    }
    outDT
}

ReadChFile <- function(file, idList, dwrIds){
    nc <- ncdf4::nc_open(file)
    output <- data.frame(q_cms = ncdf4::ncvar_get(nc, varid = "streamflow")[idList],
                         POSIXct = as.POSIXct(strsplit(basename(file),"[.]")[[1]][1], format = "%Y%m%d%H%M", tz = "UTC"),
                         DWR_ID = dwrIds)
    ncdf4::nc_close(nc)
    return(output)
}
