/**
* Name: DiseaseSpreadModel
* Author: Rahma
* Description: A model simulating disease spread in a population with graphical outputs, including hospitals.
* Tags: disease, simulation, spread, people, hospital
*/// Déclaration du modèle principal
model NewModelrourou

global { 
    // Paramètres globaux pour la simulation
    int nb_preys_init <- 200; // Nombre initial de proies
    int nb_predators_init <- 20; // Nombre initial de prédateurs
    float prey_max_energy <- 1.0; // Énergie maximale des proies
    float prey_max_transfer <- 0.1; // Maximum d'énergie que les proies peuvent transférer
    float prey_energy_consum <- 0.05; // Consommation d'énergie des proies
    float predator_max_energy <- 1.0; // Énergie maximale des prédateurs
    float predator_energy_transfer <- 0.5; // Transfert d'énergie des prédateurs
    float predator_energy_consum <- 0.02; // Consommation d'énergie des prédateurs
    float prey_proba_reproduce <- 0.01; // Probabilité de reproduction des proies
    int prey_nb_max_offsprings <- 5; // Nombre maximal de descendants des proies
    float prey_energy_reproduce <- 0.5; // Énergie nécessaire à la reproduction des proies
    float predator_proba_reproduce <- 0.01; // Probabilité de reproduction des prédateurs
    int predator_nb_max_offsprings <- 3; // Nombre maximal de descendants des prédateurs
    float predator_energy_reproduce <- 0.5; // Énergie nécessaire à la reproduction des prédateurs
    file map_init <- image_file("../includes/raster_map.png"); // Image de la carte initiale
    int nb_preys -> {length(prey)}; // Nombre de proies
    int nb_predators -> {length(predator)}; // Nombre de prédateurs
    bool is_batch <- false; // Mode batch

    // Initialisation du modèle
    init { 
        create prey number: nb_preys_init; // Création des proies
        create predator number: nb_predators_init; // Création des prédateurs
        ask vegetation_cell { 
            color <- rgb(map_init at {grid_x,grid_y}); // Définition de la couleur de la cellule de végétation à partir de l'image
            food <- 1 - (((color as list) at 0) / 255); // Calcul de la quantité de nourriture
            food_prod <- food / 100; // Production de nourriture
        } 
    }

    // Sauvegarde des résultats pendant la simulation
    reflex save_result when: (nb_preys > 0) and (nb_predators > 0){ 
        save ("cycle: "+ cycle + "; nbPreys: " + nb_preys 
            + "; minEnergyPreys: " + (prey min_of each.energy) 
            + "; maxSizePreys: " + (prey max_of each.energy)   
            + "; nbPredators: " + nb_predators 
            + "; minEnergyPredators: " + (predator min_of each.energy)            
            + "; maxSizePredators: " + (predator max_of each.energy))     
        to: "results.txt" rewrite: (cycle = 0) ? true : false; // Sauvegarde des résultats dans un fichier texte
    }

    // Arrêter la simulation quand il n'y a plus de proies ou de prédateurs
    reflex stop_simulation when: ((nb_preys = 0) or (nb_predators = 0)) and !is_batch { 
        do pause; // Pause de la simulation
    } 
}

// Définition d'une espèce générique
species generic_species { 
    float size <- 1.0; // Taille de l'espèce
    rgb color; // Couleur de l'espèce
    float max_energy; // Énergie maximale de l'espèce
    float max_transfer; // Maximum d'énergie pouvant être transféré
    float energy_consum; // Consommation d'énergie
    float proba_reproduce; // Probabilité de reproduction
    int nb_max_offsprings; // Nombre maximal de descendants
    float energy_reproduce; // Énergie nécessaire à la reproduction
    image_file my_icon; // Icône représentant l'espèce
    vegetation_cell my_cell <- one_of(vegetation_cell); // Cellule de végétation associée à l'espèce
    float energy <- rnd(max_energy) update: energy - energy_consum max: max_energy; // Énergie actuelle de l'espèce

    // Initialisation de l'espèce
    init { 
        location <- my_cell.location; // Localisation de l'espèce
    }

    // Mouvement de l'espèce
    reflex basic_move { 
        my_cell <- choose_cell(); // Choisir une nouvelle cellule pour se déplacer
        location <- my_cell.location; // Mettre à jour la localisation
    }

    // Réaction à la consommation de nourriture
    reflex eat { 
        energy <- energy + energy_from_eat(); // Consommer de l'énergie
    }

    // Réaction à la mort de l'espèce quand l'énergie est épuisée
    reflex die when: energy <= 0 { 
        do die; // L'espèce meurt
    }

    // Réaction à la reproduction de l'espèce
    reflex reproduce when: (energy >= energy_reproduce) and (flip(proba_reproduce)) { 
        int nb_offsprings <- rnd(1, nb_max_offsprings); // Nombre de descendants
        create species(self) number: nb_offsprings { 
            my_cell <- myself.my_cell; // Les descendants se reproduisent à partir de la même cellule
            location <- my_cell.location; // Localisation des descendants
            energy <- myself.energy / nb_offsprings; // L'énergie est répartie entre les descendants
        }  
        energy <- energy / nb_offsprings; // L'énergie est réduite après la reproduction
    }

    // Méthode de consommation d'énergie
    float energy_from_eat { 
        return 0.0; // Par défaut, aucune énergie n'est consommée
    }

    // Méthode pour choisir la cellule voisine
    vegetation_cell choose_cell { 
        return nil; // Par défaut, aucun mouvement n'est effectué
    }

    // Dessin de l'espèce
    aspect base { 
        draw circle(size) color: color; // Dessiner un cercle pour l'espèce
    }

    aspect icon { 
        draw my_icon size: 2 * size; // Dessiner l'icône de l'espèce
    }

    aspect info { 
        draw square(size) color: color; // Dessiner un carré pour l'espèce
        draw string(energy with_precision 2) size: 3 color: #black; // Afficher l'énergie de l'espèce
    } 
}

// Définition de l'espèce "prey" (proie) héritée de "generic_species"
species prey parent: generic_species { 
    rgb color <- #blue; // Couleur bleue pour les proies
    float max_energy <- prey_max_energy; // Énergie maximale des proies
    float max_transfer <- prey_max_transfer; // Maximum d'énergie transférable pour les proies
    float energy_consum <- prey_energy_consum; // Consommation d'énergie des proies
    float proba_reproduce <- prey_proba_reproduce; // Probabilité de reproduction des proies
    int nb_max_offsprings <- prey_nb_max_offsprings; // Nombre maximal de descendants des proies
    float energy_reproduce <- prey_energy_reproduce; // Énergie nécessaire à la reproduction des proies
    image_file my_icon <- image_file("../includes/data/sheep.png"); // Icône des proies

    // Consommation d'énergie par les proies
    float energy_from_eat { 
        float energy_transfer <- 0.0; 
        if(my_cell.food > 0) { 
            energy_transfer <- min([max_transfer, my_cell.food]); // Transfert d'énergie en fonction de la nourriture disponible
            my_cell.food <- my_cell.food - energy_transfer; // Réduction de la nourriture disponible
        }             
        return energy_transfer; 
    }

    // Choix de la cellule voisine pour se déplacer
    vegetation_cell choose_cell { 
        return (my_cell.neighbors2) with_max_of (each.food); // Choisir la cellule voisine avec la nourriture maximale
    } 
}

// Définition de l'espèce "predator" (prédateur) héritée de "generic_species"
species predator parent: generic_species { 
    rgb color <- #red; // Couleur rouge pour les prédateurs
    float max_energy <- predator_max_energy; // Énergie maximale des prédateurs
    float energy_transfer <- predator_energy_transfer; // Transfert d'énergie des prédateurs
    float energy_consum <- predator_energy_consum; // Consommation d'énergie des prédateurs
    float proba_reproduce <- predator_proba_reproduce; // Probabilité de reproduction des prédateurs
    int nb_max_offsprings <- predator_nb_max_offsprings; // Nombre maximal de descendants des prédateurs
    float energy_reproduce <- predator_energy_reproduce; // Énergie nécessaire à la reproduction des prédateurs
    image_file my_icon <- image_file("../includes/data/wolf.png"); // Icône des prédateurs

    // Consommation d'énergie par les prédateurs
    float energy_from_eat { 
        list<prey> reachable_preys <- prey inside (my_cell); // Recherche de proies dans la cellule
        if(! empty(reachable_preys)) { 
            ask one_of (reachable_preys) { 
                do die; // Mange une proie
            } 
            return energy_transfer; // Transfert d'énergie après avoir mangé
        } 
        return 0.0; 
    }

    // Choix de la cellule voisine pour se déplacer
    vegetation_cell choose_cell { 
        vegetation_cell my_cell_tmp <- shuffle(my_cell.neighbors2) first_with (!(empty(prey inside (each)))); 
        if my_cell_tmp != nil { 
            return my_cell_tmp; // Choisir une cellule voisine contenant une proie
        } else { 
            return one_of(my_cell.neighbors2); // Sinon, choisir une cellule voisine au hasard
        } 
    } 
}

// Définition de la grille de cellules végétales
grid vegetation_cell width: 50 height: 50 neighbors: 4 { 
    float max_food <- 1.0; // Quantité maximale de nourriture
    float food_prod <- rnd(0.01); // Production aléatoire de nourriture
    float food <- rnd(1.0) max: max_food update: food + food_prod; // Mise à jour de la nourriture
    rgb color <- rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))) update: rgb(int(255 * (1 - food)), 255, int(255 * (1 - food))); // Mise à jour de la couleur de la cellule
    list<vegetation_cell> neighbors2 <- (self neighbors_at 2); // Liste des voisins à distance 2
}

// Expérience de simulation de prédateurs et proies avec une interface graphique
experiment prey_predator type: gui { 
    // Paramètres pour l'expérience (les paramètres peuvent être modifiés par l'utilisateur)
    parameter "Initial number of preys: " var: nb_preys_init min: 0 max: 1000 category: "Prey"; 
    parameter "Prey max energy: " var: prey_max_energy category: "Prey"; 
    parameter "Prey max transfer: " var: prey_max_transfer category: "Prey"; 
    parameter "Prey energy consumption: " var: prey_energy_consum category: "Prey"; 
    parameter "Initial number of predators: " var: nb_predators_init min: 0 max: 200 category: "Predator"; 
    parameter "Predator max energy: " var: predator_max_energy category: "Predator"; 
    parameter "Predator energy transfer: " var: predator_energy_transfer category: "Predator"; 
    parameter "Predator energy consumption: " var: predator_energy_consum category: "Predator"; 
    parameter 'Prey probability reproduce: ' var: prey_proba_reproduce category: 'Prey'; 
    parameter 'Prey nb max offsprings: ' var: prey_nb_max_offsprings category: 'Prey'; 
    parameter 'Prey energy reproduce: ' var: prey_energy_reproduce category: 'Prey'; 
    parameter 'Predator probability reproduce: ' var: predator_proba_reproduce category: 'Predator'; 
    parameter 'Predator nb max offsprings: ' var: predator_nb_max_offsprings category: 'Predator'; 
    parameter 'Predator energy reproduce: ' var: predator_energy_reproduce category: 'Predator'; 

    // Affichage de la simulation
    output { 
        display main_display type:2d antialias:false { 
            grid vegetation_cell border: #black; // Affichage des cellules de végétation
            species prey aspect: icon; // Affichage des proies
            species predator aspect: icon; // Affichage des prédateurs
        }  

        display info_display type:2d antialias:false { 
            grid vegetation_cell border: #black; // Affichage des informations des cellules
            species prey aspect: info; // Affichage des informations des proies
            species predator aspect: info; // Affichage des informations des prédateurs
        }  

        display Population_information refresh: every(5#cycles)  type: 2d { 
            // Affichage des graphiques de population
            chart "Species evolution" type: series size: {1,0.5} position: {0, 0} { 
                data "number_of_preys" value: nb_preys color: #blue; // Evolution du nombre de proies
                data "number_of_predator" value: nb_predators color: #red; // Evolution du nombre de prédateurs
            } 
            chart "Prey Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0, 0.5} { 
                data "]0;0.25]" value: prey count (each.energy <= 0.25) color:#blue; // Distribution d'énergie des proies
                data "]0.25;0.5]" value: prey count ((each.energy > 0.25) and (each.energy <= 0.5)) color:#blue; 
                data "]0.5;0.75]" value: prey count ((each.energy > 0.5) and (each.energy <= 0.75)) color:#blue; 
                data "]0.75;1]" value: prey count (each.energy > 0.75) color:#blue; 
            } 
            chart "Predator Energy Distribution" type: histogram background: #lightgray size: {0.5,0.5} position: {0.5, 0.5} { 
                data "]0;0.25]" value: predator count (each.energy <= 0.25) color: #red; // Distribution d'énergie des prédateurs
                data "]0.25;0.5]" value: predator count ((each.energy > 0.25) and (each.energy <= 0.5)) color: #red; 
                data "]0.5;0.75]" value: predator count ((each.energy > 0.5) and (each.energy <= 0.75)) color: #red; 
                data "]0.75;1]" value: predator count (each.energy > 0.75) color: #red; 
            } 
        }  

        // Moniteurs des populations
        monitor "Number of preys" value: nb_preys; 
        monitor "Number of predators" value: nb_predators; 
    } 
}


// Expérience d'optimisation en mode batch
experiment Optimization type: batch repeat: 2 keep_seed: true until: (time > 200) { 
    // Paramètres d'optimisation pour maximiser la population totale
    parameter "Prey max transfer:" var: prey_max_transfer min: 0.05 max: 0.5 step: 0.05; 
    parameter "Prey energy reproduce:" var: prey_energy_reproduce min: 0.05 max: 0.75 step: 0.05; 
    parameter "Predator energy transfer:" var: predator_energy_transfer min: 0.1 max: 1.0 step: 0.1; 
    parameter "Predator energy reproduce:" var: predator_energy_reproduce min: 0.1 max: 1.0 step: 0.1; 
    parameter "Batch mode:" var: is_batch <- true; 

    // Méthode d'optimisation (tabou) pour maximiser la population
    method tabu maximize: nb_preys + nb_predators iter_max: 10 tabu_list_size: 3; 

    // Sauvegarde des résultats d'optimisation
    reflex save_results_explo { 
        ask simulations { 
            save [int(self),prey_max_transfer,prey_energy_reproduce,predator_energy_transfer,predator_energy_reproduce,self.nb_predators,self.nb_preys]     
            to: "results.csv" format:"csv" rewrite: (int(self) = 0) ? true : false header: true; 
        } 
    } 
} 