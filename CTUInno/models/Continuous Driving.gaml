/***
* Name: ContinuousMove
* Author: hqngh
* Description: 
* Tags: Tag1, Tag2, TagN
***/
model ContinuousMove

global {
	file building_shapefile <- file("../includes/dummy.shp");
	file boundbuilding_shapefile <- file("../includes/dummybound.shp");
	geometry shape <- envelope(boundbuilding_shapefile);
	point targ <- {0.6376229435038843, 136.93097410820067};
	//number of obstacles
	int nb_obstacles <- 10 parameter: true;
	float acceleration <- 0.0045 min: 0.0 max: 0.01 parameter: true;
	float deceleration <- 0.026 min: 0.0 max: 0.1 parameter: true;
	//perception distance
	float perception_distance <- 10.0 parameter: true;

	//precision used for the masked_by operator (default value: 120): the higher the most accurate the perception will be, but it will require more computation
	int precision <- 600 parameter: true;

	//space where the agent can move.
	geometry free_space <- copy(shape);
//	float seed <- 0.12;

	init {
		create obstacle from: building_shapefile { //number: nb_obstacles {
		//			shape <- rectangle(2 + rnd(20), 2 + rnd(20));
			free_space <- free_space - (shape + 5);
		}

		geometry temp_free <- free_space;
		create people number: 200 {
			location <- any_location_in(temp_free);
						mytarg <- {targ.x,(targ.y-20)+(rnd(40))};
			temp_free <- temp_free - (shape * 2);
			heading <- self towards mytarg;
			//			do goto target: targ speed: spd;
		}

	}

}

species people skills: [moving] {
	float spd <- 0.5;
	float size <- 5.0;
	geometry shape <- square(size);
	//	int p1 <- 0;
	//	int p2 <- 0;
		point mytarg;
	geometry TL_area;
	float old_heading;

	reflex moving {
		TL_area <- ((cone(heading - 5, heading + 5) intersection world.shape) intersection (circle(perception_distance)) - (shape rotated_by (heading + 90)));
		people close1 <- one_of(((self neighbors_at size)) sort_by (self distance_to each));
		if close1 != nil {
			old_heading <- heading;
			heading <- (self towards close1) - 180;
			loop times: 2 {
				do move speed: spd heading: heading;
			}

			heading <- old_heading;
		}

		obstacle close <- one_of(((obstacle overlapping TL_area)) sort_by (self distance_to each));
		if (close != nil) {
			float tmp_heading1 <- heading + 20;
			float tmp_heading2 <- heading - 20;
			geometry TL_area1 <- ((cone(tmp_heading1 - 5, tmp_heading1 + 5) intersection world.shape) intersection (circle(perception_distance)) - (shape rotated_by (tmp_heading1 + 90)));
			geometry TL_area2 <- ((cone(tmp_heading2 - 5, tmp_heading2 + 5) intersection world.shape) intersection (circle(perception_distance)) - (shape rotated_by (tmp_heading2 + 90)));
			obstacle close1 <- one_of(((obstacle overlapping TL_area1)) sort_by (self distance_to each));
			obstacle close2 <- one_of(((obstacle overlapping TL_area2)) sort_by (self distance_to each));
			if (close1 = nil) {
				heading <- tmp_heading1;
			}

			if (close2 = nil) {
				heading <- tmp_heading2;
			}

		}

		geometry l1 <- line(location, mytarg);
		if (length(obstacle overlapping l1) = 0) {
			heading <- self towards mytarg;
		}

		do move speed: spd heading: heading;
		if (location distance_to mytarg < 4) {
			do die;
		}

	}

	aspect default {
	//		if (mytarg != nil) {
	//			draw line(location, mytarg) color: #red;
	//		}
		if (TL_area != nil) {
			draw TL_area empty: true color: #blue;
		}

		draw shape empty: false color: #blue;
	}

}

species obstacle {

	aspect default {
		draw shape color: #gray border: #black;
	}

}

experiment traffic type: gui {
	output {
		display carte type: opengl synchronized: true {
			species obstacle;
			species people;
		}

	}

}
