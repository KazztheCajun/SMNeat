-- An adaptation of Seth Bling's MarI/O NEAT algorithm
-- The goal of this is to create a NEAT Network that can beat every level of SMB from 1-1 -> 8-4, excluding the two Underwater worlds 2-2 & 7-2
-- The primary change will be the introduction of the concept of Mario Moments to greatly expand the amount of training the networks recieve
-- These Mario Moments are the training dataset and consist of Save States created in various parts of Worlds 1-1 -> 5-1, excluding the Underwater world 2-2
-- The remaining endgame worlds (5-2 -> 8-4) will serve as the test dataset to verify the trained networks are able to apply the knowledge gained from training to unfamiliar situations

--
-- Setup Random
--
math.randomseed(os.time()) -- setup random number gen seed
for i=1,10 do
	math.random() -- warm up the RNG
end

--
-- Setup Dataset
--

MaxMoments = 222
Filenames = {}
for i=0,MaxMoments do
	Filenames[i+1] = "../../Saves/mm-"..i..".state"
end

--
-- Setup Hyperparameters
--

ButtonNames = { "A", "B", "Up", "Down", "Left", "Right" }

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

TimeoutConstant = 60

MaxNodes = 1000000

require "LuaNEAT"
require "Utils"

if pool == nil then
	initializePool()
end

form = forms.newform(300, 300, "Fitness")
maxFitnessLabel = forms.label(form, "Max Fitness: " .. math.floor(pool.maxFitness), 5, 8)
showNetwork = forms.checkbox(form, "Show Map", 5, 30)
showMutationRates = forms.checkbox(form, "Show M-Rates", 5, 52)
restartButton = forms.button(form, "Restart", initializePool, 5, 77)
saveButton = forms.button(form, "Save", savePool, 5, 102)
loadButton = forms.button(form, "Load", loadPool, 80, 102)
saveLoadFile = forms.textbox(form, "SMNeat_Test8.pool", 170, 25, nil, 5, 148)
saveLoadLabel = forms.label(form, "Save/Load:", 5, 129)
playTopButton = forms.button(form, "Play Top", playTop, 5, 170)
hideBanner = forms.checkbox(form, "Hide Banner", 5, 190)
pauseTraining = forms.checkbox(form, "Pause Training", 5, 210)


Filenames = Shuffle(Filenames)
backupDataset(forms.gettext(saveLoadFile) .. "-gen-" .. pool.generation)
writeFile("temp.pool")

MarioStart = 0
TotalFitness = 0
CurrentIndex = 1
FitnessBonus = 0
ForwardProgress = true
Rightmost = 0
Timeout = TimeoutConstant
CurrentMoment = Filenames[CurrentIndex]
MaxMoment = "none"
backgroundColor = 0xD0FFFFFF
LastFloat = 0x00

event.onexit(onExit)

--
-- Main loop
--

while true do
	local measured = 0
	local total = 0
	local species = pool.species[pool.currentSpecies]
	local genome = species.genomes[pool.currentGenome]

	if not forms.ischecked(hideBanner) then
		gui.drawBox(0, 0, 300, 38, backgroundColor, backgroundColor)
	end

	if forms.ischecked(showNetwork) then
		displayGenome(genome)
	end

	if not forms.ischecked(pauseTraining) then
		if pool.currentFrame%5 == 0 then
			evaluateCurrent()
		end

		joypad.set(controller)

		getPositions()
		
		-- if(lastFloat == 0x01 and marioFloat == 0x00) then -- reward a successful jump
		-- 	FitnessBonus = FitnessBonus + 50
		-- end

		lastFloat = marioFloat

		if(marioSpeed > 24) then
			FitnessBonus = FitnessBonus + 1
		end

		local trueRight = marioX - MarioStart
		--print("Start: " .. MarioStart.." | Progress: "..trueRight)
		if trueRight > Rightmost then -- if mario has made progress
			Rightmost = trueRight 	  -- update the current progress
			Timeout = TimeoutConstant
			ForwardProgress = true
		end
		
		Timeout = Timeout - 1
		
		if (memory.readbyte(0x001D) == 0x03) then -- if mario has reached the level flag
			FitnessBonus = FitnessBonus + 1000
			NextMoment() -- load a new moment and continue the run
		end
		
		getEnemyState()

		-- if(enemyState1 == 0x04) then
		-- 	FitnessBonus = FitnessBonus + 20
		-- end
		-- if(enemyState2 == 0x04) then
		-- 	FitnessBonus = FitnessBonus + 20
		-- end
		-- if(enemyState3 == 0x04) then
		-- 	FitnessBonus = FitnessBonus + 20
		-- end
		-- if(enemyState4 == 0x04) then
		-- 	FitnessBonus = FitnessBonus + 20
		-- end
		-- if(enemyState5 == 0x04) then
		-- 	FitnessBonus = FitnessBonus + 20
		-- end

		local timeoutBonus = pool.currentFrame / 8 			-- Add a extra time before timeout the longer this genome is able to play the game
		if Timeout + timeoutBonus <= 0 then -- Once the timout + bonus is gone, mario falls of screen, or dies
			NextMoment()
		elseif screenY > 1 or marioState == 0x0B then -- If mario dies or falls offscreen
			NextMoment()
		end

		if CurrentIndex > MaxMoments then
			ScoreGenome(genome)
		end

		for _,species in pairs(pool.species) do
			for _,genome in pairs(species.genomes) do
				total = total + 1
				if genome.fitness ~= 0 then
					measured = measured + 1
				end
			end
		end
			
		pool.currentFrame = pool.currentFrame + 1
		
	end
	
	if not forms.ischecked(hideBanner) then
		gui.drawText(0, 0, "Gen " .. pool.generation .. " species " .. pool.currentSpecies .. " genome " .. pool.currentGenome .. " (" .. math.floor(measured/total*100) .. "%)", 0xFF000000, 11)
		gui.drawText(0, 12, "Fitness:" .. math.floor((FitnessBonus + TotalFitness + Rightmost) - (pool.currentFrame / 4)), 0xFF000000, 11)
		gui.drawText(95, 12, "Max Fitness:" .. math.floor(pool.maxFitness), 0xFF000000, 11)
		gui.drawText(0, 24, "State: " .. marioState .. " | Speed: " .. marioSpeed .. " | Float: " .. marioFloat, 0xFF000000, 11)
	end

	emu.frameadvance()
end

