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
	file gate_shapefile <- file("../includes/CTUGates.shp");
	file building_shapefile <- file("../includes/CTUBuildings3.shp");
	//Shapefile of the roads
	//	file road_shapefile <- file("../includes/CTURoads.shp");
	file road_shapefile <- file("../includes/CTURoads2.shp");
	//Shape of the environment
	geometry shape <- envelope(road_shapefile);
	//Step value
	float step <- 10 #s;
	//Graph of the road network
	graph road_network_external;
	graph road_network_CTU;
	//Map containing all the weights for the road network graph
	map<road, float> road_weights;
	//	list<road> observe_road;
	float trafficjam;
	int number_people <- 55;
	int nb_speed;
	string optimizer_type <- "NBAStarApprox" among: ["NBAStar", "NBAStarApprox", "Dijkstra", "AStar", "BellmannFord", "FloydWarshall"];
	string scenario_type <- "current" among: ["A in B out", "current"];
	bool newgate <- false;
	//		bool directed <- true;
	bool directed <- true;
	bool separate_2lanes <- true;
	bool random_event <- true;
	float seed <- 0.22041988;
	list<rgb> road_color <- [#green, #red, #blue];

	init {
		write seed;
		//Initialization of the building using the shapefile of buildings
		create building from: building_shapefile;
		create gate from: gate_shapefile;
		gate[1].regular <- 0.75;
		gate[2].regular <- 0.15;
		gate[4].regular <- 0.1;
		//Initialization of the road using the shapefile of roads
		create road from: road_shapefile with: [DIRECTION::int(read("DIRECTION"))];
		//		observe_road <- [road[183], road[63], road[76], road[185], road[184]];

		//		ask [road[87], road[141], road[64], road[75], road[25], road[85],road[180]] {
		//			DIRECTION <- 0;
		//		}
		//
		//		ask [road[45], road[176], road[41], road[120], road[125], road[101],road[16]] {
		//			DIRECTION <- 0;
		//		}
		if (scenario_type = "A in B out") {
		//scenario 1 : gate A in, gate B out
			ask road where (each.TYPE = "scenario1") {
				DIRECTION <- 1;
			}

			gate[1].DIRECTION <- 0;
			gate[2].DIRECTION <- 1;
			//end scenario 1
		}

		if (newgate) {
			ask gate {
				regular <- 0.2;
			}

			gate[0].TYPE <- "1";
			//			point p1 <- last(road[80].shape.points);
			//			point p2 <- road[144].shape.points closest_to p1;
			//			create road {
			//				shape <- line(p1, p2);
			//				DIRECTION <- 2;
			//			}
			gate[3].TYPE <- "1";
			//			p1 <- last(road[111].shape.points);
			//			p2 <- road[190].shape.points closest_to p1;
			//			create road {
			//				shape <- line(p1, p2);
			//				DIRECTION <- 2;
			//			}

		} else {
			ask [road[90], road[91]] {
				do die;
			}

		}

		if (directed) {
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
						if (separate_2lanes) {
							point p0 <- shape.points[0];
							point p1 <- shape.points[length(shape.points) - 1];
							shape <- shape translated_by {-5, 0};
							shape.points[0] <- p0;
							shape.points[length(shape.points) - 1] <- p1;
							//bidirectional: creation of the inverse road
							create road {
								shape <- polyline(reverse(myself.shape.points)) translated_by {10, 0};
								shape.points[0] <- myself.shape.points[length(myself.shape.points) - 1];
								shape.points[length(shape.points) - 1] <- myself.shape.points[0];
								DIRECTION <- 2;
								color <- #blue;
								OWNER <- myself.OWNER;
							}

						} else {
						//bidirectional: creation of the inverse road
							create road {
								shape <- polyline(reverse(myself.shape.points));
								DIRECTION <- 2;
								color <- #blue;
								OWNER <- myself.OWNER;
							}

						}

					}

				}

			}

			create people number: 250 {
			}

			create people number: 50 {
				purpose <- "go around";
				//People agents are located anywhere in one of the building
			}

		}
		//Creation of the people agents
		//Weights of the road
		//				road_weights <- road as_map (each::float(each.nb_people + 1));
		//		road_network <- as_edge_graph(road);
		road_network_external <- directed(as_edge_graph(road where (each.OWNER != "CTU")));
		road_network_external <- road_network_external with_optimizer_type optimizer_type;
		road_network_CTU <- directed(as_edge_graph(road where (each.OWNER = "CTU")));
		road_network_CTU <- road_network_CTU with_optimizer_type optimizer_type;
	}
	//Reflex to update the speed of the roads according to the weights
	reflex update_road_speed {
		trafficjam <- length(people where (each.csd = #darkred));
		if (random_event and flip(0.01) and length(people where (each.go_event)) = 0) {
			create people number: 50 {
				go_event <- true;
				if (go_event) {
					class <- any_location_in(building[408]);
				}

			}

		}
		//		trafficjam <- 0.0;
		//		ask observe_road {
		//			trafficjam <- trafficjam + length(((people at_distance 1) where (each.csd = #darkred)) where (each overlaps self));
		//		}

				if (cycle = 2000) {
					do pause;
				}
		//				road_weights <- road as_map (each::  (float(each.nb_people+1)));
		//		road_network <- road_network with_weights road_weights;
	}

	//	reflex generate_people when: flip(0.01) {
	//		create people number: nb_people {
	//			location <- any_location_in(one_of(road where (each.NAME = "main")));
	//			//				location <- any_location_in(one_of([road[2],road[2], road[46]]));
	//			target <- any_location_in(one_of(building));
	//		}
	//	}
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
species people skills: [moving] {
//Target point of the agent
	point home;
	point class;
	point my_gate;
	point target;
	//Probability of leaving the building
	//	float leaving_proba_ori <- 0.0000005;
	//	float leaving_proba <- leaving_proba_ori;
	//Speed of the agent
	//	float speed <- (nb_speed/10)  #km / #h; // (10.0 / 10.0) #km / #h;
	//	rgb color <- rnd_color(255);
	//	map<road, float> roads_knowledge;
	//	path path_to_follow;
	float wsize <- (15.0) / 1;
	float heading <- -90.0;
	geometry shape <- triangle(wsize);
	float perception_distance <- wsize * 4.5;
	//	geometry TL_area;
	float csp <- ((nb_speed / 5) #km / #h);
	rgb csd <- #green;
	float min_speed <- 0.5;

	//	path path_to_follow;
	//	float max_accelerate <- 1.2;
	//	float accelerate <- 0.0;
	string purpose <- "go home";
	bool go_event <- false;
	float work_time <- 120.0 + rnd(30);
	float rest_time <- 20.0 + rnd(30);
	bool inside_CTU <- false;
	//	float tick <- 0.0;
	init {
	//		roads_knowledge <- road_weights;
	//		location <- any_location_in(one_of(road where (each.TYPE = "main")));
		home <- any_location_in(one_of(building where (each.owner != "CTU" and each.owner != "KTX")));
		class <- any_location_in(one_of(building where (each.owner = "CTU")));
		if (go_event) {
			class <- any_location_in(building[408]);
		}

		list tmp <- (gate where (each.TYPE = "1"));
		int var0 <- rnd_choice(tmp collect each.regular);
		//		write tmp;
		//		write var0;
		my_gate <- tmp[var0].location;
		//				my_gate <- ((gate where (each.TYPE = "1")) closest_to home).location;
		//		location <- any_location_in(one_of(road));
		location <- home;
		target <- nil; // any_location_in(one_of(building));
	}

	//Reflex to leave the building to another building
	reflex leave when: (target = nil) { //and (flip(leaving_proba)) {
	//		tick <- tick + 1; 
		if (location distance_to my_gate < 0.000001) {
			if (purpose = "go home") {
				inside_CTU <- true;
			}

			if (purpose = "go to school") {
				inside_CTU <- false;
			}

		}

		if (purpose = "go to school" and (cycle mod 1000 >= 500)) {
		//			leaving_proba <- 0.5;
		//			tick <- 0.0;
			if (location distance_to class < 0.000001) {
				if (flip(0.1)) {
					if (scenario_type = "A in B out") {
						my_gate <- ((gate where (each.TYPE = "1" and each.DIRECTION != 0)) closest_to home).location;
					}

					target <- my_gate;
				}

			} else {
				purpose <- "go home";
				target <- home; // any_location_in(one_of(road where (each.TYPE = "main")));
			}

		}

		if (purpose = "go home" and (cycle mod 1000 < 500)) {
		//			leaving_proba <- leaving_proba_ori; 
			if (location distance_to home < 0.000001) {
				if (flip(0.1)) {
					if (scenario_type = "A in B out") {
						my_gate <- ((gate where (each.TYPE = "1" and each.DIRECTION != 1)) closest_to class).location;
					}

					target <- my_gate;
				}

			} else {
				purpose <- "go to school";
				//			location <- any_location_in(one_of(road where (each.TYPE = "main")));
				//			tick <- 0.0;
				target <- class; // any_location_in(one_of(building));
			}

		}

		if (purpose = "go around") {
		//			leaving_proba <- leaving_proba_ori;
		//			tick <- 0.0;
		//			target <- any_location_in(one_of(road));
			target <- any_location_in(one_of(road where (each.TYPE = "main")));
		}

	}

	//	point ppp <- nil;
	//Reflex to move to the target building moving on the road network
	reflex move when: target != nil {
	//		path path_followed <-
		do goto(target: target, speed: csp, on: inside_CTU ? road_network_CTU : road_network_external, recompute_path: true, return_path: false); //, move_weights: road_weights);
		//				if (path_to_follow = nil) {
		//		
		//				//Find the shortest path using the agent's own weights to compute the shortest path
		//					path_to_follow <- path_between(road_network with_weights road_weights, location, target);
		//				}
		//				//the agent follows the path it computed but with the real weights of the graph
		//				do follow path: path_to_follow speed: csp/20 move_weights: road_weights;
		if (destination = nil) {
			return;
		}
		//		TL_area <- ((cone(heading - 25, heading + 25) intersection world.shape) intersection (circle(perception_distance)) - (shape rotated_by (heading + 90)));
		geometry TL_area <- circle(0.5) at_location destination;
		list<people> v <- ((people - self) at_distance (perception_distance)) overlapping (TL_area); //(((people - self) at_distance (perception_distance))) where ( each.shape intersects TL_area); //!(each.TL_area overlaps TL_area) and each.current_edge = self.current_edge and
		//		list<people> vv<-v where (each.current_edge = self.current_edge);
		//we use the return_path facet to return the path followed
		if (current_edge != nil) {
			if ((length(v) > 0)) { //((current_edge as road).LANES))) {
			//				ppp <- v[0].location;
				csd <- #darkred;
				float tmp <- v min_of each.csp;
				if (csp > tmp) {
					csp <- tmp;
				}

				if (csp - 0.05 > min_speed) {
					csp <- csp - 0.1;
				}

			} else {
			//				ppp <- nil;
			//				if (accelerate < max_accelerate) {
			//					accelerate <- accelerate + 0.01;
			//				}
			//				if (csd = #darkred) {
			//					csd <- #green;
			//					csp <- ((nb_speed / 5) #km / #h); /// + accelerate;
			//				}
				csd <- #green;
				if ((csp + 0.25 <= ((nb_speed / 5) #km / #h))) {
					csp <- csp + 0.25;
				}

			}

		}

		//if the path followed is not nil (i.e. the agent moved this step), we use it to increase the pollution level of overlapping cell
		//		if (path_followed != nil ) {
		//			ask (cell overlapping path_followed.shape) {
		//				pollution <- pollution + 10.0;
		//			}
		//		}
		if (self distance_to target < 0.0001) {
		//					path_to_follow<-nil;
			if (target=home and go_event) {
				do die;
			}
			location <- target;

			csd <- #green;
			target <- nil;
		} }

	aspect default {
	//			if(ppp!=nil){				
	//				draw circle(0.5) empty:true at:ppp color:csd;
	//			}
	//		if (target != nil and name = "people197") {
	//			draw line(location, target) color: csd;
	//			//					draw circle(0.5) empty:true at:destination color:csd;
	//		}
	//				if (TL_area != nil) {
	//					draw TL_area color: csd empty: true;
	//				}
		if (go_event) {
			draw circle(wsize/2) color: #red;
		}
		else{
			
		draw shape empty: true rotate: heading + 90 color: csd;
		}
	} }

species gate {
	string NAME;
	string TYPE;
	int DIRECTION;
	float regular <- 0.0;

	aspect default {
		draw square(10) empty: true color: #black;
	}

}
//Species to represent the buildings
species building {
	string owner;
	int capacity <- int(number_people / 2); //rnd(50);
	//	reflex time_off when: flip(0.0005) {
	//		create people number: capacity {
	//			location <- any_location_in(one_of(road where (each.NAME != "main")));
	//			target <- any_location_in(one_of(road where (each.NAME = "main")));
	//			purpose <- "go home";
	//		}
	//
	//	}
	aspect default {
		draw shape empty: true color: #black;
	}

}
//Species to represent the roads
species road {
	string NAME <- "";
	int DIRECTION;
	int LANES <- 1;
	string TYPE <- "";
	string OWNER <- "";
	//Capacity of the road considering its perimeter
	//	float capacity <- float(number_people);
	//Number of people on the road
	//		int nb_people <- 0 update: length((people overlapping self));
	//Speed coefficient computed using the number of people on the road and the capicity of the road
	//	float speed_coeff <- 1.0 update: exp(-nb_people / capacity) min: 0.1;
	//	int buffer <- 10;
	aspect default {
		draw (shape) color: road_color[DIRECTION]; // + buffer * speed_coeff)
		if (!directed) {
			draw "" + int(self) at: location color: color perspective: false;
		}

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
	parameter "Maximum Average Speed" var: nb_speed <- 35 min: 0 max: 100;
	parameter "Open 2 new gates" var: newgate;
	parameter "Random Event" var: random_event;
	parameter "make directed graphs" var: directed;
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

		display carte type: opengl synchronized: false camera_pos: {1352.6461, 1292.8163, 1589.0471} camera_look_pos: {889.1801, 875.5097, 45.5246} camera_up_vector:
		{-0.689, 0.6204, 0.3746} {
			species building refresh: false;
			species gate refresh: false;
			species road;
			species people;

			//display the pollution grid in 3D using triangulation.
			//			grid cell elevation: pollution * 3.0 triangulation: true transparency: 0.7;

		}

	}

}
