library(tidyverse)
library(sf)

# 1. Download data from here:
#  https://github.com/microsoft/USBuildingFootprints
# 2. Crop data with GDAL (https://gdal.org/programs/ogr2ogr.html) so that it runs faster on my slow computer:
#  > ogr2ogr -f 'GeoJSON' NC_clip.geojson NorthCarolina.geojson -clipsrc -79 35.8 -78.8 36.1

# Read and transform data
houses <- st_read("~/Downloads/NC_clip.geojson") %>%
  st_transform(5070) # Lambers equal area

# Create clipping circle
clip_circle <- c(lng=-78.9, lat=35.9) %>%
  st_point() %>%
  st_sfc(crs=4326) %>%
  st_transform(crs=5070) %>%
  st_buffer(dist = 4402) # meters ~ zoom level 13 on maps ~ 5 mi across

h2 <- houses %>%
  st_intersection(clip_circle)

# Make plot that is 10" with a 7.25" diameter circle,
# which shows the circle in a 10x10" frame (or fills a square with a 5x5" matte)
jpeg("~/MyMap.jpeg", width=10, height=10, units="in",res=300)
par(mar=c(0,0,0,0), omi=rep(1.375,4), xpd=NA, xaxs = "i", yaxs = "i")
plot(h2$geometry, col="#333333", border="#333333", lwd=0.2)
dev.off()

# ggplot() +
#   geom_sf(data = h2, fill="#333333", col="#333333", lwd=0.1) +
#   theme_void()
