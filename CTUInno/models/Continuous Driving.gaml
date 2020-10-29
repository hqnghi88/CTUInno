model EvacuationInClassroom

global {
	int max <- 10;
	//DImension of the grid agent
	int nb_cols <- 500;
	int nb_rows <- 500;
	file roads_shapefile <- file("../includes/roads_LHP.shp");
	geometry shape <- envelope(roads_shapefile);
	list<cell> avai <- [];
	float maxspd<-2.0;
	init {
		create road from: roads_shapefile {
			old_shape <- copy(shape);
			shape <- shape + 2;
			ask cell overlapping self {
				color <- #lightgray;
			}

		}

		ask cell where (each.color = #white) {
			do die;
		}
		//		avai <- cell where (each.color = #white);
		avai <- cell where (!dead(each));
		create people number: 200 {
			location <- any_location_in(one_of(road).old_shape);
			target <- any_location_in(one_of(road).old_shape);
		}

	}

}

species road {
	geometry old_shape;

	aspect default {
		draw shape + 2 color: #lightgray;
	}

}

species people skills: [moving] parallel: true {
	cell c;
	//Evacuation point
	point target;
	float spd <- (2 + rnd(maxspd));
	rgb color <- rnd_color(255);
	list<cell> passed <- [];
	path path_followed;
	//Reflex to move the agent 
	reflex evacuate {
	//Make the agent move only on cell without walls 
	//		do goto target: target speed: 1.0 on: (cell where (not each.is_wall and (each.p != self))) return_path: true recompute_path: true; 
		path_followed <- goto(target: target, on: (avai where (not each.used)), speed: spd, recompute_path: false, return_path: true);
		if (path_followed != nil) {
			ask (passed) {
				used <- false;
				p <- nil;
				color <- #lightgray;
			}

			passed <- avai overlapping path_followed.shape;
		}

		ask (passed) {
			used <- true;
			p <- myself;
			color <- myself.color;
		}

		if (current_edge = nil) {
			ask (passed) {
				used <- false;
				p <- nil;
				color <- #lightgray;
			}

			target <- any_location_in(one_of(road).old_shape);
			spd <- (2 + rnd(maxspd));
		}
		//If the agent is close enough to the exit, it dies
		if (self distance_to target) < 1 {
			ask (passed) {
				used <- false;
				p <- nil;
				color <- #lightgray;
			}

			target <- any_location_in(one_of(road).old_shape);
			spd <- (2 + rnd(maxspd));
		} }

	aspect default {
		draw square(1) color: color;
	} }

	//Grid species to discretize space
grid cell width: nb_cols height: nb_rows neighbors: 8 parallel: true schedules: [] use_individual_shapes: false use_regular_agents: false {
	bool used <- false;
	people p;
	rgb color <- #white;

	reflex ss {
	//			p <- nil;
	}

}

experiment "Continuous Driving" type: gui {
	output {
		display Main type: java2D synchronized: false { //camera_pos: {50.00000000000001,140.93835147797245,90.93835147797242} camera_look_pos: {50.0,50.0,0.0} camera_up_vector: {-4.3297802811774646E-17,0.7071067811865472,0.7071067811865478}{
			image file: "../includes/satellite.png" refresh: false;
			grid cell refresh: false transparency:0.55;
//									species road refresh: false;
			species people;
		}

	}

}

