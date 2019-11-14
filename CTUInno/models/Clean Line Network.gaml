/**
* Name: clean_road_network
* Author: Patrick Taillandier
* Description: shows how GAMA can help to clean network data before using it to make agents move on it
* Tags: gis, shapefile, graph, clean
*/
model clean_road_network

global {
//Shapefile of the roads
	file road_shapefile <- file("../includes/CTURoads22.shp");

	//Shape of the environment
	geometry shape <- envelope(road_shapefile);

	//clean or not the data
	bool clean_data <- true parameter: true;

	//tolerance for reconnecting nodes
	float tolerance <- 0.5 parameter: true;

	//if true, split the lines at their intersection
	bool split_lines <- true parameter: true;

	//if true, keep only the main connected components of the network
	bool reduce_to_main_connected_components <- false parameter: true;
	string legend <- not clean_data ?
	"Raw data" : ("Clean data : tolerance: " + tolerance + "; split_lines: " + split_lines + " ; reduce_to_main_connected_components:" + reduce_to_main_connected_components);
	list<list<point>> connected_components;
	list<rgb> colors;

	init {

	//clean data, with the given options
		list<geometry> clean_lines <- clean_data ? clean_network(road_shapefile.contents, tolerance, split_lines, reduce_to_main_connected_components) : road_shapefile.contents;

		//create road from the clean lines
		create road from: clean_lines;
//		ask road {
//			point so <- first(self.shape.points);
//			road rr1 <- ((road - self) closest_to so);
//			geometry r1 <- rr1.shape;
//			point p1 <- r1.points closest_to self;
//			write p1 distance_to so;
//			if (p1 distance_to so < 50) {
//				list g1 <- r1 split_at p1;
//				create road from: g1;
//				ask rr1 {
//					do die;
//				}
//
//				shape.points[0] <- p1;
//				s1 <- circle(5) at_location p1;
//			}
//
//			so <- last(self.shape.points);
//			road rr2 <- ((road - self) closest_to so);
//			geometry r2 <- rr2.shape;
//			point p2 <- r2.points closest_to self;
//			if (p2 distance_to so < 50) {
//				list g2 <- r2 split_at p2;
//				create road from: g2;
//				ask rr2 {
//					do die;
//				}
//
//				shape.points[length(shape.points) - 1] <- p2;
//				s2 <- circle(5) at_location p2;
//			}
//
//		}

		//build a network from the road agents
		graph road_network_clean <- as_edge_graph(road);
		//computed the connected components of the graph (for visualization purpose)
		connected_components <- list<list<point>>(connected_components_of(road_network_clean));
		loop times: length(connected_components) {
			colors << rnd_color(255);
		}

	}

	reflex ss {

			save road to:"../includes/CTURoads222.shp" type:shp  attributes: ["NAME"::name,"LANES":: LANES, "TYPE"::TYPE, "DIRECTION"::DIRECTION];

	}

}

//Species to represent the roads
species road {
//	string name<-"";
	geometry s1 <- nil;
	geometry s2 <- nil;
	int DIRECTION;
	int LANES <- 4;
	string TYPE <- "";

	aspect default {
		draw shape + 10 empty: true color: #black;
		if (s1 != nil) {
			draw s1;
		}

		if (s2 != nil) {
			draw s2;
		}

	}

}

experiment clean_network type: gui {
//	init {
//		create clean_road_network_model with:[clean_data::false]; 
//		create clean_road_network_model with:[split_lines::false,reduce_to_main_connected_components::false]; 
//		create clean_road_network_model with:[split_lines::true,reduce_to_main_connected_components::false]; 
//	}
	output {
		display network type: opengl {
		//			 overlay position: { 10, 100 } size: { 1000 #px, 60 #px } background: # black transparency: 0.5 border: #black rounded: true
		//            {
		//				draw legend color: #white font: font("SansSerif", 20, #bold) at: {40#px, 40#px, 1 };
		//			}
			graphics "connected components" {
				loop i from: 0 to: length(connected_components) - 1 {
					loop j from: 0 to: length(connected_components[i]) - 1 {
											draw circle(12) color: colors[i] at: connected_components[i][j];	
					}

				}

			}

			species road;
		}

	}

}
