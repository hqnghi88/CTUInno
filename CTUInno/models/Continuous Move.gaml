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

	//perception distance
	float perception_distance <- 40.0 parameter: true;

	//precision used for the masked_by operator (default value: 120): the higher the most accurate the perception will be, but it will require more computation
	int precision <- 600 parameter: true;

	//space where the agent can move.
	geometry free_space <- copy(shape);

	init {
		create obstacle from:building_shapefile{//number: nb_obstacles {
//			shape <- rectangle(2 + rnd(20), 2 + rnd(20));
			free_space <- free_space - shape;
		}

		create people number: 500 {
			location <- any_location_in(free_space);
			mytarg <- targ;
			//			free_space <- free_space - shape;
		}

	}

}

species people skills: [moving] {
	float spd <- 0.5;
	float size<-3.0;
	geometry shape <- square(size);
	int p1 <- 0;
	int p2 <- 0;
	point mytarg;

	reflex moving {
		people close1 <- one_of(((self neighbors_at size) of_species people) sort_by (self distance_to each));
		if close1 != nil {
			p1 <- p1 + 1;
			heading <- (self towards close1) - 180;
			float dist <- self distance_to close1;
		}

		obstacle close <- one_of(((obstacle overlapping shape)) sort_by (self distance_to each));
		if close != nil {
			p2 <- p2 + 1;
			heading <- (self towards close) - 180;
			float dist <- self distance_to close;
			//			do move speed: spd heading: heading;
		}

		if (p1 >= 200 or p2 >= 20) {
			mytarg <- any_location_in(free_space);
		}

		if (close != nil or close1 != nil) {
			do move speed: spd heading: heading;
		} else {
			do goto target: mytarg speed: spd;
		}

		if (location distance_to mytarg < 2) {
			
				p1 <- 0;
				p2 <- 0;
				mytarg <- targ; 

		}if(location distance_to targ< 4) {
				do die;
			} 

	}

	aspect default {
//		if (mytarg != nil) {
//			draw line(location, mytarg) color: #red;
//		}

		draw shape empty: true color: #blue;
	}

}

species obstacle {

	aspect default {
		draw shape color: #gray border: #black;
	}

}

experiment traffic type: gui {
	output {
		display carte type: opengl synchronized: false {
			species obstacle;
			species people;
		}

	}

}
