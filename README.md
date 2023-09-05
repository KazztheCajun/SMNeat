# SMNeat

<p>This is my thesis project which has the goal of teaching a bot how to play Super Mario Brothers from start to finish.  It employs a style of Neural Network known as a NEAT algorithm. NEAT is an acronym for Neuro Evolution through Augmenting Topologies, which was first described in the paper ["Evolving Neural Networks through Augmenting Topologies"](https://direct.mit.edu/evco/article/10/2/99-127/1123) by Kenneth O. Stanley & Risto Miikkulainen.</p>
<p>This NEAT algorithm is adapted from the MarI/O algorithm created by [Seth Bling](https://www.youtube.com/@SethBling) and used in his explosively popular YouTube videos.  [Source](https://pastebin.com/ZZmSNaHX)  I have used the NEAT Algorithm he created; however, I have modified it in the following ways:</p>

* [x] Created a database of save states, known as a Mario Moment, from worlds 1-1 through 5-1
* [x] Each training run of a genome loads a random Mario Moment as the starting point
* [x] When a run completes a level, a new Mario Moment is chosen and the training run continues from there
* :white_large_square Exhastivly test each hyperparameter to find the combination that creates the best results
* :white_large_square Employ a 10 fold cross validation of the models to create a diverse set of elite models for the final test runs
* :white_large_square Create a test run algorithm that tests the elite models from each fold to determine the best model
