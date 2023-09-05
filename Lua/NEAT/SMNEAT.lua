-- An adaptation of Seth Bling's MarI/O NEAT algorithm
-- The goal of this is to create a NEAT Network that can beat every level of SMB from 1-1 -> 8-4, excluding the two Underwater worlds 2-2 & 7-2
-- The primary change will be the introduction of the concept of Mario Moments to greatly expand the amount of training the networks recieve
-- These Mario Moments are the training dataset and consist of Save States created in various parts of Worlds 1-1 -> 5-1, excluding the Underwater world 2-2
-- The remaining endgame worlds (5-2 -> 8-4) will serve as the test dataset to verify the trained networks are able to apply the knowledge gained from training to unfamiliar situations

--
-- Helper funcitons
--

function NextMoment()
	TotalDistance = TotalDistance + rightmost -- save the distance traveled in the run

    moment = Filenames[math.random(0, MaxMoments)] -- select a new Mario Moment
    savestate.load(moment)                         -- load the moment
    getPositions()
	MarioStart = marioX
    rightmost = 0
	--pool.currentFrame = 0
	timeout = TimeoutConstant
    clearJoypad()
    evaluateCurrent()
	
end

--
-- Main loop
--

math.randomseed(os.time()) -- setup random number gen seed
for i=0,10 do
	math.random() -- warm up the RNG
end

ButtonNames = { "A", "B", "Up", "Down", "Left", "Right" }
MaxMoments = 234
MarioStart = 0
TotalDistance = 0

Filenames = {}

for i=0,MaxMoments do
	Filenames[i] = "../../Saves/mm-"..i..".state"
end

BoxRadius = 6
InputSize = (BoxRadius*2+1)*(BoxRadius*2+1)

Inputs = InputSize+1
Outputs = #ButtonNames

Population = 300
DeltaDisjoint = 2.0
DeltaWeights = 0.4
DeltaThreshold = 1.0

StaleSpecies = 15

MutateConnectionsChance = 0.25
PerturbChance = 0.90
CrossoverChance = 0.75
LinkMutationChance = 2.0
NodeMutationChance = 0.50
BiasMutationChance = 0.40
StepSize = 0.1
DisableMutationChance = 0.4
EnableMutationChance = 0.2

TimeoutConstant = 20

MaxNodes = 1000000

require "LuaNEAT"
require "Utils"

if pool == nil then
	initializePool()
end

writeFile("temp.pool")

event.onexit(onExit)

form = forms.newform(300, 300, "Fitness")
maxFitnessLabel = forms.label(form, "Max Fitness: " .. math.floor(pool.maxFitness), 5, 8)
showNetwork = forms.checkbox(form, "Show Map", 5, 30)
showMutationRates = forms.checkbox(form, "Show M-Rates", 5, 52)
restartButton = forms.button(form, "Restart", initializePool, 5, 77)
saveButton = forms.button(form, "Save", savePool, 5, 102)
loadButton = forms.button(form, "Load", loadPool, 80, 102)
saveLoadFile = forms.textbox(form, "SMNeat.pool", 170, 25, nil, 5, 148)
saveLoadLabel = forms.label(form, "Save/Load:", 5, 129)
playTopButton = forms.button(form, "Play Top", playTop, 5, 170)
hideBanner = forms.checkbox(form, "Hide Banner", 5, 190)


while true do
	local backgroundColor = 0xD0FFFFFF
	if not forms.ischecked(hideBanner) then
		gui.drawBox(0, 0, 300, 26, backgroundColor, backgroundColor)
	end

	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]
	
	if forms.ischecked(showNetwork) then
		displayGenome(genome)
	end
	
	if pool.currentFrame%5 == 0 then
		evaluateCurrent()
	end

	joypad.set(controller)

    getPositions()
    
    local trueRight = marioX - MarioStart
	--print("Start: " .. MarioStart.." | Progress: "..trueRight)
	if trueRight > rightmost then -- if mario has made progress
		rightmost = trueRight 	      -- update the current progress
		timeout = TimeoutConstant	  -- reset the timeout value
	end
	
	timeout = timeout - 1
	
	if (memory.readbyte(0x001D) == 0x03) then -- if mario has reached the level flag
		NextMoment() -- load a new moment and continue the run
    end
	
	local timeoutBonus = pool.currentFrame / 4 			-- Add a extra time before timeout the longer this genome is able to play the game
    if timeout + timeoutBonus <= 0 then					-- Once the timout + bonus is gone
		TotalDistance = TotalDistance + rightmost			  -- add the distance traveled this run to the total
		local fitness = TotalDistance - pool.currentFrame / 2 -- set this genome's fitness to how far mario traveled during the entire run - half of the frames it took to get there
        if fitness == 0 then                            	  -- punish the model for not progressing during the run
            fitness = -100
        end
		
		genome.fitness = fitness							  -- set this genomes fitness to the calculated value
		
		if fitness > pool.maxFitness then					  -- if this genome is better than the current best
			pool.maxFitness = fitness						  -- make it the new best
            forms.settext(maxFitnessLabel, "Max Fitness: " .. math.floor(pool.maxFitness))
			print("Saving Backup ->" .. "backup_" .. pool.generation .. "_" .. forms.gettext(saveLoadFile))
			writeFile("backup_" .. pool.generation .. "_" .. forms.gettext(saveLoadFile)) -- create a backup containing the new best model
		end
		
		console.writeline("Gen " .. pool.generation .. " species " .. pool.currentSpecies .. " genome " .. pool.currentGenome .. " fitness: " .. fitness)
		pool.currentSpecies = 1
		pool.currentGenome = 1
		while fitnessAlreadyMeasured() do
			nextGenome()
		end
		initializeRun()
	end

	local measured = 0
	local total = 0
	for _,species in pairs(pool.species) do
		for _,genome in pairs(species.genomes) do
			total = total + 1
			if genome.fitness ~= 0 then
				measured = measured + 1
			end
		end
	end
	if not forms.ischecked(hideBanner) then
		gui.drawText(0, 0, "Gen " .. pool.generation .. " species " .. pool.currentSpecies .. " genome " .. pool.currentGenome .. " (" .. math.floor(measured/total*100) .. "%)", 0xFF000000, 11)
		gui.drawText(0, 12, "Fitness: " .. math.floor(rightmost - (pool.currentFrame) / 2 - (timeout + timeoutBonus)*2/3), 0xFF000000, 11)
		gui.drawText(100, 12, "Max Fitness: " .. math.floor(pool.maxFitness), 0xFF000000, 11)
	end
		
	pool.currentFrame = pool.currentFrame + 1

	emu.frameadvance();
end