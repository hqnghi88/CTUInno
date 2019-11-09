/**
* Name: Traffic
* Author: Patrick Taillandier
* Description: A simple traffic model with a pollution model: the speed on a road depends on the number of people 
* on the road (the highest, the slowest), and the people diffuse pollution on the envrionment when moving.
* Tags: gis, shapefile, graph, skill, transport
*/
model traffic

global {
//Shapefile of the buildings
	file building_shapefile <- file("../includes/CTUBuildings.shp");
	//Shapefile of the roads
	//	file road_shapefile <- file("../includes/CTURoads.shp");
	file road_shapefile <- file("../includes/CTURoads_clean.shp");
	//Shape of the environment
	geometry shape <- envelope(road_shapefile);
	//Step value
	float step <- 10 #s;
	//Graph of the road network
	graph road_network;
	//Map containing all the weights for the road network graph
	map<road, float> road_weights;
	list<road> observe_road;
	float trafficjam;
	int number_people <- 55;
	int nb_speed <- 25;
	string scenario_type <- "A in B out" among: ["A in B out", "current"];
	//	float seed <- 0.4450924241567986;
	init {
		write seed;
		//Initialization of the building using the shapefile of buildings
		create building from: building_shapefile;
		//Initialization of the road using the shapefile of roads
		create road from: road_shapefile with: [DIRECTION::int(read("DIRECTION"))];
		observe_road <- [road[35], road[36], road[2], road[50], road[47], road[45]];
		if (scenario_type = "A in B out") {
		//scenario 1 : gate A in, gate B out
			ask road[3] {
				self.DIRECTION <- 1;
			}

			ask road[36] {
				self.DIRECTION <- 1;
			}

			ask road[5] {
				self.DIRECTION <- 1;
			}

			ask road[49] {
				self.DIRECTION <- 1;
			}
			//end scenario 1
		}

		ask road {
//			LANES<-1+rnd(6);
			switch DIRECTION {
				match 0 {
					color <- #green;
				}

				match 1 {
					color <- #red;
					//inversion of the road geometry
					shape <- polyline(reverse(shape.points));
				}

				match 2 {
					color <- #blue;
					//bidirectional: creation of the inverse road
					create road {
						shape <- polyline(reverse(myself.shape.points));
						DIRECTION <- 2;
						color <- #blue;
					}

				}

			}

		}

		//Creation of the people agents
		create people number: 2500 {
		//People agents are located anywhere in one of the building
		}
		//Weights of the road
		road_weights <- road as_map (each::each.shape.perimeter);
		//		road_network <- as_edge_graph(road);
		road_network <- directed(as_edge_graph(road));
	}
	//Reflex to update the speed of the roads according to the weights
	reflex update_road_speed {
		trafficjam <- 0.0;
		ask observe_road {
			trafficjam <- trafficjam + length((people where (each.csd = #darkred)) where (each overlaps self));
		}

		//		if (cycle = 2000) {
		//			do pause;
		//		}
		road_weights <- road as_map (each::each.shape.perimeter / (1+each.speed_coeff));
		road_network <- road_network with_weights road_weights;
	}

	reflex generate_people when: flip(0.01) {
	//		create people number: nb_people {
	//			location <- any_location_in(one_of(road where (each.NAME = "3 Tháng 2")));
	//			//				location <- any_location_in(one_of([road[2],road[2], road[46]]));
	//			target <- any_location_in(one_of(building));
	//		}

	}
	//Reflex to decrease and diffuse the pollution of the environment
	//	reflex pollution_evolution{
	//		//ask all cells to decrease their level of pollution
	//		ask cell {pollution <- pollution * 0.7;}
	//		
	//		//diffuse the pollutions to neighbor cells
	//		diffuse var: pollution on: cell proportion: 0.9 ;
	//	}
}

//Species to represent the people using the skill moving
species people skills: [moving] parallel:true{
//Target point of the agent
	point target;
	//Probability of leaving the building
	float leaving_proba_ori <- 0.05;
	float leaving_proba <- leaving_proba_ori;
	//Speed of the agent
	float speed <- ((5 + rnd(5)) / 10.0) #km / #h;
	//	rgb color <- rnd_color(255);
	float wsize <-( 6.0 + rnd(1) ) /1;
	geometry shape <- square(wsize);
	float perception_distance <- wsize;
	geometry TL_area;
	float csp <- speed;
	rgb csd <- #green;
	float min_accelerate <- 0.1;
	float max_accelerate <- 1.0;
	float accelerate <- 0.0;
	string purpose <- "go to school";

	init {
	//		location <- any_location_in(one_of(road where (each.NAME = "3 Tháng 2")));
		location <- any_location_in(one_of(road));
		target <- any_location_in(one_of(building));
	}

	//Reflex to leave the building to another building
	reflex leave when: (target = nil) and (flip(leaving_proba)) {
		if (flip(0.5)) {
			leaving_proba <- leaving_proba_ori;
			target <- any_location_in(one_of(building));
		} else {
			leaving_proba <- 0.5;
			purpose <- "go home";
			target <- any_location_in(one_of(road where (each.NAME = "3 Tháng 2")));
		}

	}
	//Reflex to move to the target building moving on the road network
	reflex move when: target != nil {
//		path path_followed <-
		do goto(target: target, speed: csp, on: road_network, recompute_path: false, return_path: false, move_weights: road_weights);
		TL_area <- ((cone(heading - 10, heading + 10) intersection world.shape) intersection (circle(perception_distance)) - shape);
		list<people> v <- (((people - self) at_distance (perception_distance))) where (each overlaps TL_area); //!(each.TL_area overlaps TL_area) and each.current_edge = self.current_edge and

		//we use the return_path facet to return the path followed
		if (current_edge!=nil and (length(v) > (current_edge as road).LANES)) {
			csd <- #darkred;
			float tmp <- v min_of each.csp;
			if (csp > tmp) {
				csp <- tmp;
			}

			if (csp > min_accelerate) {
				csp <- csp - 0.001;
			}

		} else {
			if (accelerate < max_accelerate) {
				accelerate <- accelerate + 0.01;
			}

			csd <- #green;
			csp <- (nb_speed / 100) + accelerate;
		}

		//if the path followed is not nil (i.e. the agent moved this step), we use it to increase the pollution level of overlapping cell
		//		if (path_followed != nil ) {
		//			ask (cell overlapping path_followed.shape) {
		//				pollution <- pollution + 10.0;
		//			}
		//		}
		if (self distance_to target < 0.0001) {
			target <- nil;
			if (purpose = "go home") {
			//				do die;
			}

		} }

	aspect default {
	//		if (target != nil and int(self) = 190) {
	//			draw line(location, target);
	//		}
	//		if (TL_area != nil) {
	//			draw TL_area color: csd empty: true depth: 0.5;
	//		}
		draw shape empty: true rotate: heading + 90 color: csd;
	} }

	//Species to represent the buildings
species building {
	int capacity <- int(number_people / 2); //rnd(50);
	//	reflex time_off when: flip(0.0005) {
	//		create people number: capacity {
	//			location <- any_location_in(one_of(road where (each.NAME != "3 Tháng 2")));
	//			target <- any_location_in(one_of(road where (each.NAME = "3 Tháng 2")));
	//			purpose <- "go home";
	//		}
	//
	//	}
	aspect default {
		draw shape color: #gray;
	}

}
//Species to represent the roads
species road {
	string NAME <- "";
	int DIRECTION;
	int LANES <- 1;
	string TYPE <- "";
	//Capacity of the road considering its perimeter
	float capacity <- 1 + shape.perimeter *3;
	//Number of people on the road
	int nb_people <- 0 update: length(people where (each.current_edge =self));
	//Speed coefficient computed using the number of people on the road and the capicity of the road
	float speed_coeff <- 1.0 update: exp(-nb_people / capacity) min: 0.1;
	int buffer <- 10;

	aspect default {
		draw (shape+LANES) color: #darkgray; // + buffer * speed_coeff)
	}

}

//cell use to compute the pollution in the environment
//grid cell height: 50 width: 50 neighbors: 8{
//	//pollution level
//	float pollution <- 0.0 min: 0.0 max: 100.0;
//	
//	//color updated according to the pollution level (from red - very polluted to green - no pollution)
//	rgb color <- #green update: rgb(255 *(pollution/30.0) , 0 * (1 - (pollution/30.0)), 255.0);
//}
experiment traffic type: gui {
	parameter "Scenario" var: scenario_type;
	parameter "Number of people generated per 10 min" var: number_people <- 55 min: 0 max: 150;
	parameter "Maximum Average Speed" var: nb_speed <- 25 min: 0 max: 100;
	//	parameter "voiture <-> moto" var: nb_moto <- 100 min: 0 max: 100;
	//	float minimum_cycle_duration <- 0.01;
	init {
	//		create simulation with: [seed::world.seed, scenario_type::"current", nb_speed::25, nb_people::55 ];
	}

	output {
	//		layout vertical([0::5000, 1::5000]) tabs: true editors: false;
		
				display "Statistic" {
					chart "Number of people stuck in traffic jams" type: series {
						data "jam " value: trafficjam color: #red marker: false style: line;
					}
		
				}
		display carte type: opengl synchronized: false camera_pos: {1063.0606, 1156.4411, 389.2278} camera_look_pos: {774.4739, 564.7507, -89.0491} camera_up_vector:
		{-0.2577, 0.5283, 0.809} {
			species building refresh: false;
			species road;
			species people;

			//display the pollution grid in 3D using triangulation.
			//			grid cell elevation: pollution * 3.0 triangulation: true transparency: 0.7;

		}


	}

}
