# ALKIS Karte
# Berry, 2021-04-05
# https://data.geobasis-bb.de/geobasis/daten/alkis/Vektordaten/shape/

library(leaflet)
library(leaflet.extras)

if(!exists("shp")){
message("Reading data...")
shp <- sf::st_read("ALKIS_Shape_OPR/flurstueck.shp")
}
message("Cropping data...")
lims <- c(xmin=339400, ymin=5897700, xmax=350500, ymax=5904000)
shp2 <- sf::st_crop(shp, lims) ; rm(lims)
message("Projecting data...")
shp2 <- sf::st_transform(shp2, '+proj=longlat +datum=WGS84')
shp2$flaeche <- shp2$flaeche/1e4
cent <- sf::st_centroid(shp2)
cent <- cent[cent$flaeche > 1.5,]
popup <- unname(berryFunctions::popleaf(shp2, sel=c("gemarkung", "flur", "flurstnr", "aktualit", "flaeche", "lagebeztxt")))

message("Creating map...")
# create map, add controls:
rmap <- leaflet() %>% addPolygons(data=shp2, popup=popup, group="Flure", fillOpacity=0, weight=1) %>% #, 
        #label=~flurstnr, labelOptions=labelOptions(noHide=T, textOnly=T)) %>% 
  addLabelOnlyMarkers(data=cent, label=~flurstnr, labelOptions=labelOptions(noHide=T, textOnly=T), group="Nr") %>% 
  addSearchOSM(options=searchOptions(autoCollapse=TRUE, minLength=2, hideMarkerOnCollapse=TRUE, zoom=16)) %>% 
  addControlGPS(options=gpsOptions(position="topleft", 
                                   activate=TRUE, autoCenter=TRUE, maxZoom=16, setView=TRUE)) %>% 
  addMeasure(primaryLengthUnit="kilometers", primaryAreaUnit="hectares",
             activeColor="#3D535D", completedColor="#7D4479", position="topleft") %>% 
  addScaleBar(position="topleft") %>% 
  addFullscreenControl()
# add background map layer options:
prov <- c(OSM="OpenStreetMap", Sat="Esri.WorldImagery", Topo="OpenTopoMap") # mapview::mapviewGetOption("basemaps")
for(pr in names(prov)) rmap <- rmap %>% addProviderTiles(unname(prov[pr]), group=pr, 
                                                         options=providerTileOptions(maxZoom=20))
rmap <- rmap %>% addLayersControl(baseGroups=names(prov),
                                  overlayGroups=c("Flure", "Nr"),
                                  options=layersControlOptions(collapsed=FALSE)) %>% 
  #hideGroup(c("Flure")) %>% 
  hideGroup(c("Nr")) %>% 
  setView(12.652, 53.248, zoom=15) 
print(rmap)

# Export:
if(T){
message("Exporting map as html...")
htmlwidgets::saveWidget(rmap, "index.html", selfcontained=TRUE)
message("Changing html header...")
# HTML head for mobile devices:
# https://stackoverflow.com/questions/42702394/make-leaflet-map-mobile-responsive
map_h <- readLines("index.html")
map_h <- sub('<title>leaflet</title>', x=map_h,
             '<meta name="viewport" content="width=device-width, initial-scale=1.0"/>\n<title>Flurkarte</title>')
writeLines(map_h, "index.html") ; rm(map_h)
berryFunctions::openFile("index.html")
}  

