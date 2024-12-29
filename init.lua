---@type mod_calllbacks
local M = {}

---@type brain_function
_G["Vibrant_Biomes.plant"] = function(body)
	---@type brain
	local brain = {}
	brain.rotation = rand_normal() - 0.1*body.angular_velocity

	return brain
end


---@type brain_function
_G["Vibrant_Biomes.Floating_Barge_brain"] = function(body)
	---@type brain
	local brain = {}
	brain.rotation = rand_normal() - 0.1*body.angular_velocity

    local wall_avoid_range = 60	
	avoid_walls(body, brain, wall_avoid_range)
	return brain
end


---@type brain_function
_G["Vibrant_Biomes.Linked_Generator_brain"] = function(body)
	---@type brain
	local brain = {}
	brain.rotation = rand_normal() - 0.1*body.angular_velocity
	if body.health >= body.max_health then
		brain.ability = true
	end
	return brain
end


---@type brain_function
_G["Vibrant_Biomes.Dark_Bouy_brain"] = function(body)
	---@type brain
	local randomadjustment = body.values[1] or 0.0 -- default to 0
	if randomadjustment == 0.0 then
		randomadjustment = rand_normal()
	end

	local brain = {}
	brain.rotation = rand_normal() - 0.1*body.angular_velocity

	local Increment = body.age + randomadjustment*60.0

	if ( (Increment) % ( 240 ) < 40 ) then
		brain.ability = true
	end

    brain.values = {}
	brain.values[1] = randomadjustment
	
	return brain
end

---@type brain_function
_G["Vibrant_Biomes.Molusk_brain"] = function(body)
	---@type brain
	local Increment = body.values[1] or 0.0 -- default to 0
	if Increment == 0.0 then
		Increment = rand_normal()*60
	end

	local brain = {}
	brain.rotation = rand_normal() - 0.1*body.angular_velocity

	local Increment = Increment + 1 + (rand_normal()*.5)

	if ( (Increment) % ( 300 ) < 30 ) then
		brain.ability = true
	end

    brain.values = {}
	brain.values[1] = Increment
	return brain
end

---@type brain_function
_G["Vibrant_Biomes.drifter_brain"] = function(body)

	local brain = {}

    local ally_avoid_range = 10
    local wall_avoid_range = 10

    local health = body.health
    local max_health = body.max_health

	brain.movement = brain.movement or 0
	brain.rotation = brain.rotation or 0

	-- movement while not aggro'd
	brain.movement = 1
	brain.rotation = 0.5*rand_normal() + math.sin(0.15*body.age) --random turning + a wiggle

    local bodies = get_visible_bodies(body.id, 100, true)
    for i, b in ipairs(bodies) do
        avoid_body(body, brain, b, ally_avoid_range)
    end

    -- update our custom values
    brain.values = {}

    return brain
end

---@type brain_function
_G["Vibrant_Biomes.Squid_brain"] = function(body)

	local brain = {}

    local ally_avoid_range = 20
    local wall_avoid_range = 20

    local health = body.health
    local max_health = body.max_health

	brain.movement = brain.movement or 0
	brain.rotation = brain.rotation or 0

	if body.health < body.max_health* .9 then
		brain.ability = true
	end

	-- movement while not aggro'd
	brain.movement = 1
	brain.rotation = 0.5*rand_normal() + math.sin(0.15*body.age) --random turning + a wiggle

    local bodies = get_visible_bodies(body.id, 100, true)
    for i, b in ipairs(bodies) do
        avoid_body(body, brain, b, ally_avoid_range)
    end
	avoid_walls(body, brain, wall_avoid_range)
    -- update our custom values
    brain.values = {}

    return brain
end

---@type brain_function
_G["Vibrant_Biomes.squishy_seeker_brain"] = function(body)--TODO not chasing player

	local state = body.values[1] or 0 
	local aggro_timer = body.values[2] or 600 -- timer for giving up on its target
    local target_x = body.values[3] or body.cost_center_x
    local target_y = body.values[4] or body.cost_center_y

	local brain = {}

    local ally_avoid_range = 10
    local wall_avoid_range = 10

    local health = body.health
    local max_health = body.max_health

	brain.movement = brain.movement or 0
	brain.rotation = brain.rotation or 0

	local closest_enemy, closest_enemy_id, closest_dist = nil, 0, 200  -- aggro range set to 200
    local bodies = get_visible_bodies(body.id, 200, true)

    for i, b in ipairs(bodies) do
		--chases enemies
		if b.team ~= body.team then
			closest_enemy = b
			closest_enemy_id = b.id
			closest_dist = b.dist
		end
		-- avoids allys
		if b.team == body.team then
			avoid_body(body, brain, b, ally_avoid_range)
		end
    end

	if state == 0 then
		-- movement while not aggro'd
		brain.movement = 1
		brain.rotation = 0.5*rand_normal() + math.sin(0.15*body.age) --random turning + a wiggle
		if closest_enemy then
			state = 1
		end

	elseif state == 1 then -- goes to last known position for the chance of finding hte player
		if closest_enemy then
			
			target_x = closest_enemy.cost_center_x
			target_y = closest_enemy.cost_center_y
			-- uses mouse thing for better aim
			brain.grab_target_x = target_x
			brain.grab_target_y = target_y
	
			brain.grab_weight = 1

			local dir_x = closest_enemy.cost_center_x - body.cost_center_x
			local dir_y = closest_enemy.cost_center_y - body.cost_center_y
			
			dir_x, dir_y = normalize(dir_x, dir_y)

			brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
			

			move_towards(body, brain, target_x, target_y)
			avoid_walls(body, brain, wall_avoid_range)
		end
		if closest_enemy_id == 0 then
			state = 2
			aggro_timer = DEAGGRO_TIME
		end

	elseif state == 2 then

		-- uses mouse thing for better aim
		brain.grab_target_x = target_x
		brain.grab_target_y = target_y

		brain.grab_weight = 1

		local dir_x = target_x - body.cost_center_x
		local dir_y = target_y - body.cost_center_y

		dir_x, dir_y = normalize(dir_x, dir_y)
		brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
	
	
		aggro_timer = aggro_timer-1

		if closest_enemy_id ~= 0 then
			state = 1
		end

		if aggro_timer <= 0 then
			state = 0
		end
	end
    -- update our custom values
    brain.values = {}
	brain.values[1] = state
    brain.values[2] = aggro_timer
    brain.values[3] = target_x
    brain.values[4] = target_y
    return brain
end

---@type brain_function
_G["Vibrant_Biomes.Basher_brain"] = function(body)--TODO not chasing player

	local state = body.values[1] or 0 
	local aggro_timer = body.values[2] or 600 -- timer for giving up on its target
    local target_x = body.values[3] or body.cost_center_x
    local target_y = body.values[4] or body.cost_center_y

	local brain = {}

    local ally_avoid_range = 10
    local wall_avoid_range = 10

    local health = body.health
    local max_health = body.max_health

	brain.movement = brain.movement or 0
	brain.rotation = brain.rotation or 0

	local closest_enemy, closest_enemy_id, closest_dist = nil, 0, 200  -- aggro range set to 200
    local bodies = get_visible_bodies(body.id, 200, true)

	local PunchDistance = 200

    for i, b in ipairs(bodies) do
		--chases enemies
		if b.team ~= body.team then
			closest_enemy = b
			closest_enemy_id = b.id
			closest_dist = b.dist
		end
		-- avoids allys
		if b.team == body.team then
			avoid_body(body, brain, b, ally_avoid_range)
		end
    end

	if state == 0 then
		-- movement while not aggro'd
		brain.movement = 1
		brain.rotation = 0.5*rand_normal() + math.sin(0.15*body.age) --random turning + a wiggle
		if closest_enemy then
			state = 1
		end
		avoid_walls(body, brain, wall_avoid_range)
		-- returns ball to center to heal 
		brain.grab_target_x = body.cost_center_x
		brain.grab_target_y = body.cost_center_y

		brain.grab_weight = 1

	elseif state == 1 then -- goes to last known position for the chance of finding hte player
		if closest_enemy then
			
			target_x = closest_enemy.cost_center_x
			target_y = closest_enemy.cost_center_y
			-- uses mouse thing for better aim
			brain.grab_target_x = target_x
			brain.grab_target_y = target_y
	
			brain.grab_weight = 1

			local dir_x = closest_enemy.cost_center_x - body.cost_center_x
			local dir_y = closest_enemy.cost_center_y - body.cost_center_y
			
			dir_x, dir_y = normalize(dir_x, dir_y)

			brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
			if ( body.age > 240 ) and ( body.age % ( 120 ) < 60 ) and ( body.mass > 380 ) and (closest_dist < PunchDistance) then
				-- returns ball to center to heal 
				brain.grab_target_x = target_x
				brain.grab_target_y = target_y

				brain.grab_weight = 1
			end

			if ( body.age % ( 120 ) >= 60 ) or ( body.mass < 380 ) or (closest_dist > PunchDistance) then
				-- returns ball to center to heal 
				brain.grab_target_x = body.cost_center_x
				brain.grab_target_y = body.cost_center_y

				brain.grab_weight = 1
			end
			move_towards(body, brain, target_x, target_y)
			avoid_walls(body, brain, wall_avoid_range)
		end
		if closest_enemy_id == 0 then
			state = 2
			aggro_timer = DEAGGRO_TIME
		end

	elseif state == 2 then

		-- uses mouse thing for better aim
		brain.grab_target_x = target_x
		brain.grab_target_y = target_y

		brain.grab_weight = 1

		local dir_x = target_x - body.cost_center_x
		local dir_y = target_y - body.cost_center_y

		dir_x, dir_y = normalize(dir_x, dir_y)
		brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)

		move_towards(body, brain, target_x, target_y)
		avoid_walls(body, brain, wall_avoid_range)
	
		aggro_timer = aggro_timer-1

		if closest_enemy_id ~= 0 then
			state = 1
		end

		if aggro_timer <= 0 then
			state = 0
		end
	end
    -- update our custom values
    brain.values = {}
	brain.values[1] = state
    brain.values[2] = aggro_timer
    brain.values[3] = target_x
    brain.values[4] = target_y
    return brain
end

_G["Vibrant_Biomes.Broadside_brain"] = function(body)--TODO not chasing player

	local state = body.values[1] or 0 
	local aggro_timer = body.values[2] or 600 -- timer for giving up on its target
    local target_x = body.values[3] or body.cost_center_x
    local target_y = body.values[4] or body.cost_center_y

	local brain = {}

    local ally_avoid_range = 50
    local wall_avoid_range = 70

    local health = body.health
    local max_health = body.max_health

	brain.movement = brain.movement or 0
	brain.rotation = brain.rotation or 0

	local closest_enemy, closest_enemy_id, closest_dist = nil, 0, 200  -- aggro range set to 200
    local bodies = get_visible_bodies(body.id, 200, true)

    for i, b in ipairs(bodies) do
		--chases enemies
		if b.team ~= body.team then
			closest_enemy = b
			closest_enemy_id = b.id
			closest_dist = b.dist
		end
		-- avoids allys
		if b.team == body.team then
			avoid_body(body, brain, b, ally_avoid_range)
		end
    end

	if state == 0 then
		-- movement while not aggro'd
		brain.movement = 1
		brain.rotation = 0.5*rand_normal() + math.sin(0.15*body.age) --random turning + a wiggle
		if closest_enemy then
			state = 1
		end
		avoid_walls(body, brain, wall_avoid_range)
	elseif state == 1 then
		if closest_enemy then
			
			target_x = closest_enemy.cost_center_x
			target_y = closest_enemy.cost_center_y
			-- uses mouse thing for better aim
			brain.grab_target_x = target_x
			brain.grab_target_y = target_y
	
			brain.grab_weight = 1

			local dir_x = closest_enemy.cost_center_x - body.cost_center_x
			local dir_y = closest_enemy.cost_center_y - body.cost_center_y
			
			dir_x, dir_y = normalize(dir_x, dir_y)

			brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
			
			if ( body.age > 240 ) and ( body.age % ( 240 ) < 30 ) and ( health > max_health * 0.4 ) then
				brain.ability = true
			end

			move_towards(body, brain, target_x, target_y)
			avoid_walls(body, brain, wall_avoid_range)
		end
		if closest_enemy_id == 0 then
			state = 2
			aggro_timer = DEAGGRO_TIME
		end

	elseif state == 2 then-- goes to last known position for the chance of finding hte player

		-- uses mouse thing for better aim
		brain.grab_target_x = target_x
		brain.grab_target_y = target_y

		brain.grab_weight = 1

		local dir_x = target_x - body.cost_center_x
		local dir_y = target_y - body.cost_center_y

		dir_x, dir_y = normalize(dir_x, dir_y)
		brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
	
		move_towards(body, brain, target_x, target_y)
		avoid_walls(body, brain, wall_avoid_range)
	
		aggro_timer = aggro_timer-1

		if closest_enemy_id ~= 0 then
			state = 1
		end

		if aggro_timer <= 0 then
			state = 0
		end
	end
    -- update our custom values
    brain.values = {}
	brain.values[1] = state
    brain.values[2] = aggro_timer
    brain.values[3] = target_x
    brain.values[4] = target_y
    return brain
end

_G["Vibrant_Biomes.Canivorous_Barge_brain"] = function(body)--TODO not chasing player

	local state = body.values[1] or 0 
	local aggro_timer = body.values[2] or 600 -- timer for giving up on its target
    local target_x = body.values[3] or body.cost_center_x
    local target_y = body.values[4] or body.cost_center_y

	local brain = {}

    local ally_avoid_range = 50
    local wall_avoid_range = 100

    local health = body.health
    local max_health = body.max_health

	brain.movement = brain.movement or 0
	brain.rotation = brain.rotation or 0

	local closest_enemy, closest_enemy_id, closest_dist = nil, 0, 200  -- aggro range set to 200
    local bodies = get_visible_bodies(body.id, 200, true)

    for i, b in ipairs(bodies) do
		--chases enemies
		if b.team ~= body.team then
			closest_enemy = b
			closest_enemy_id = b.id
			closest_dist = b.dist
		end
		-- avoids allys
		if b.team == body.team then
			avoid_body(body, brain, b, ally_avoid_range)
		end
    end

	if state == 0 then
		-- movement while not aggro'd

		brain.rotation = 0.5*rand_normal() + math.sin(0.15*body.age) --random turning + a wiggle
		if closest_enemy then
			state = 1
		end

		avoid_walls(body, brain, wall_avoid_range)
	elseif state == 1 then
		if closest_enemy then
			
			target_x = closest_enemy.cost_center_x
			target_y = closest_enemy.cost_center_y
			-- uses mouse thing for better aim
			brain.grab_target_x = target_x
			brain.grab_target_y = target_y
	
			brain.grab_weight = 1

			local dir_x = closest_enemy.cost_center_x - body.cost_center_x
			local dir_y = closest_enemy.cost_center_y - body.cost_center_y
			
			dir_x, dir_y = normalize(dir_x, dir_y)

			brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
			
			if ( body.age > 240 ) and ( body.age % ( 240 ) < 30 ) and ( health > max_health * 0.4 ) then
				brain.ability = true
			end

			move_towards(body, brain, target_x, target_y)
			avoid_walls(body, brain, wall_avoid_range)
		end
		if closest_enemy_id == 0 then
			state = 2
			aggro_timer = DEAGGRO_TIME
		end

	elseif state == 2 then-- goes to last known position for the chance of finding hte player

		-- uses mouse thing for better aim
		brain.grab_target_x = target_x
		brain.grab_target_y = target_y

		brain.grab_weight = 1

		local dir_x = target_x - body.cost_center_x
		local dir_y = target_y - body.cost_center_y

		dir_x, dir_y = normalize(dir_x, dir_y)
		brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
	
		move_towards(body, brain, target_x, target_y)
		avoid_walls(body, brain, wall_avoid_range)
	
		aggro_timer = aggro_timer-1

		if closest_enemy_id ~= 0 then
			state = 1
		end

		if aggro_timer <= 0 then
			state = 0
		end
	end
    -- update our custom values
    brain.values = {}
	brain.values[1] = state
    brain.values[2] = aggro_timer
    brain.values[3] = target_x
    brain.values[4] = target_y
    return brain
end


-- fancy brain for the big guy who hides in the dark
_G["Vibrant_Biomes.Seeking_Destroyer_brain"] = function(body)
	
	-- starts by staying still or very still (stalking)
	--sees a guy in range to strike in a short distance (stalking)
	--when it gets too close or far away switches to hunting state (hunting)
	-- runs after playerat high speed (hunting)
	--looks for last player position if it loses sight (hunting2)
	-- if it cant find player returns to stalking (stalking)

	local state = body.values[1] or 0  -- default to state 0 (stalking)
	local aggro_timer = body.values[2] or 600 -- timer for giving up on its target
    local target_x = body.values[3] or body.cost_center_x
    local target_y = body.values[4] or body.cost_center_y
	local ClosestGottenTo = body.values[5] or 600 -- intermediary so that far away players that get spotted arnt imidiatly chased after

	local brain = {}

    local wall_avoid_range = 30

    local health = body.health
    local max_health = body.max_health

    local DEAGGRO_TIME = 5*120 -- 5 seconds

	brain.movement = brain.movement or 0
	brain.rotation = brain.rotation or 0
	
	local bodies = get_visible_bodies(body.id, 600, true)
	local closest_enemy, closest_enemy_id, closest_dist = nil, 0, 600  -- aggro range set to 600

	for _, b in ipairs(bodies) do
		if b.team ~= body.team then
			closest_enemy = b
			closest_enemy_id = b.id
			closest_dist = b.dist
		end
	end

	-- staying still to trick the player into thinking its a dark bouy
	if state == 0 then
		brain.rotation = 0
		brain.movement = 0
		if closest_enemy then
			state = 1
			ClosestGottenTo = 600
		end

	elseif state == 1 then -- if detecting a player look at them
		-- slowly looks at player
		local dir_x = closest_enemy.cost_center_x - body.cost_center_x
		local dir_y = closest_enemy.cost_center_y - body.cost_center_y


		dir_x, dir_y = normalize(dir_x, dir_y)
		brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)*.1

		if closest_dist < ClosestGottenTo then
			ClosestGottenTo = closest_dist
		end
		if (closest_dist < 100) or ((closest_dist > 200) and (ClosestGottenTo < 200)) or (closest_enemy_id == 0 )  then
			state = 2
		end


	elseif state == 2 then -- goes after enemies that are too far away
		if closest_enemy then
			
			target_x = closest_enemy.cost_center_x
			target_y = closest_enemy.cost_center_y
			-- uses mouse thing for better aim
			brain.grab_target_x = target_x
			brain.grab_target_y = target_y
	
			brain.grab_weight = 1

			local dir_x = closest_enemy.cost_center_x - body.cost_center_x
			local dir_y = closest_enemy.cost_center_y - body.cost_center_y
			
			dir_x, dir_y = normalize(dir_x, dir_y)

			brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)
			

			move_towards(body, brain, target_x, target_y)
			avoid_walls(body, brain, wall_avoid_range)
		end
		if closest_enemy_id == 0 then
			state = 3
			aggro_timer = DEAGGRO_TIME
		end

	elseif state == 3 then

		-- uses mouse thing for better aim
		brain.grab_target_x = target_x
		brain.grab_target_y = target_y

		brain.grab_weight = 1

		local dir_x = target_x - body.cost_center_x
		local dir_y = target_y - body.cost_center_y

		dir_x, dir_y = normalize(dir_x, dir_y)
		brain.rotation = cross(body.dir_x, body.dir_y, dir_x, dir_y)

		move_towards(body, brain, target_x, target_y)
		avoid_walls(body, brain, wall_avoid_range)
	
		aggro_timer = aggro_timer-1

		if closest_enemy_id ~= 0 then
			state = 2
		end

		if aggro_timer <= 0 then
			state = 0
		end
	end
	-- update our custom values
	brain.values = {}
	brain.values[1] = state
    brain.values[2] = aggro_timer
    brain.values[3] = target_x
    brain.values[4] = target_y
	brain.values[5] = ClosestGottenTo
	return brain
end
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--##################(end of brains)#####################################################################################################################################################################################################################
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---@type spawn_function
_G["Vibrant_Biomes.drifting"] = function(body_id, x, y)
	give_mutation(body_id, MUT_DRIFTING)
	return { nil, nil, x, y } -- this determines spawn extra info
end
---@type spawn_function
_G["Vibrant_Biomes.budding"] = function(body_id, x, y)
	give_mutation(body_id, MUT_BUDDING)
	return { nil, nil, x, y } -- this determines spawn extra info
end

-- post hook is for defining creatures
function M.post(api, config)
	local Plant_SpawnRates = config.Plant_SpawnRates or 1.0
	local Animal_SpawnRates = config.Plant_SpawnRates or 1.0
	local Gyre_Animals = config.Plant_SpawnRates or true
	-- we shadow the creature_list function to call our additional code after it
	local old_creature_list = creature_list
	creature_list = function(...)
		-- call the original
		local r = { old_creature_list(...) }

		-- register our creatures
		register_creature(
			api.acquire_id("Vibrant_Biomes.Brain_Coral"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Brain_Coral.bod",
			"Vibrant_Biomes.plant"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Little_grass"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Little_grass.bod",
			"Vibrant_Biomes.plant"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Molusk"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Molusk.bod",
			"Vibrant_Biomes.Molusk_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Squid"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Squid.bod",
			"Vibrant_Biomes.Squid_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.drifter"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/drifter.bod",
			"Vibrant_Biomes.drifter_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.squishy_seeker"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/squishy_seeker.bod",
			"Vibrant_Biomes.squishy_seeker_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Bounce_Flower"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Bounce_Flower.bod",
			"Vibrant_Biomes.plant"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Seeking_Destroyer"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Seeking_Destroyer.bod",
			"Vibrant_Biomes.Seeking_Destroyer_brain",
			"Vibrant_Biomes.drifting"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Dark_Bouy"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Dark_Bouy.bod",
			"Vibrant_Biomes.Dark_Bouy_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Dark_Bouy_Large"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Dark_Bouy_Large.bod",
			"Vibrant_Biomes.Dark_Bouy_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Dark_Bouy_Floating"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Dark_Bouy_Floating.bod",
			"Vibrant_Biomes.Dark_Bouy_brain"
		)

		register_creature(
			api.acquire_id("Vibrant_Biomes.Blood_Coral"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Blood_Coral.bod",
			"Vibrant_Biomes.plant"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Linked_Generator"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Linked_Generator.bod",
			"Vibrant_Biomes.Linked_Generator_brain",
			"Vibrant_Biomes.budding"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Broadside"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Broadside.bod",
			"Vibrant_Biomes.Broadside_brain",
			"Vibrant_Biomes.budding"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Floating_Barge"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Floating_Barge.bod",
			"Vibrant_Biomes.Floating_Barge_brain",
			"Vibrant_Biomes.budding"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Canivorous_Barge"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Canivorous_Barge.bod",
			"Vibrant_Biomes.Canivorous_Barge_brain",
			"Vibrant_Biomes.budding"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Basher"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Basher.bod",
			"Vibrant_Biomes.Basher_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Acid_Molusk"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Acid_Molusk.bod",
			"Vibrant_Biomes.Molusk_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.Angler_Weed"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/Angler_Weed.bod",
			"Vibrant_Biomes.Molusk_brain"
		)
		register_creature(
			api.acquire_id("Vibrant_Biomes.gyre_drifter"),
			"data/scripts/lua_mods/mods/Vibrant_Biomes/bodies/gyre_drifter.bod",
			"Vibrant_Biomes.drifter_brain"
		)
		-- return the result of the original, not strictly neccesary here but useful in some situations
		return unpack(r)
	end

	-- shadow init_biomes function to call our stuff afterwards
	local old_init_biomes = init_biomes
	init_biomes = function(...)
		local r = { old_init_biomes(...) }
		-- add our creatures to the starting biome, if spawn_rates are too high you will start to see issues where only some creatures can spawn
		-- to fix this make sure the sum isn't too high, i will perhaps add a prehook for compat with this in future
		
		add_plant_spawn_chance("STRT", api.acquire_id("Vibrant_Biomes.Brain_Coral"), .02*Plant_SpawnRates, 2)
		add_plant_spawn_chance("STRT", api.acquire_id("Vibrant_Biomes.Little_grass"), .02*Plant_SpawnRates, 2)
		add_plant_spawn_chance("STRT", api.acquire_id("Vibrant_Biomes.Molusk"), .01*Plant_SpawnRates, 3)
		
		add_creature_spawn_chance("STRT", api.acquire_id("Vibrant_Biomes.Squid"), .01*Animal_SpawnRates, 3)

		
		add_plant_spawn_chance("TOXC", api.acquire_id("Vibrant_Biomes.Acid_Molusk"), .05*Plant_SpawnRates, 5)
		add_plant_spawn_chance("TOXC", api.acquire_id("Vibrant_Biomes.Angler_Weed"), .08*Plant_SpawnRates, 5)



		add_creature_spawn_chance("ICEE", api.acquire_id("Vibrant_Biomes.drifter"), .06*Animal_SpawnRates, 1)
		add_creature_spawn_chance("ICEE", api.acquire_id("Vibrant_Biomes.squishy_seeker"), .02*Animal_SpawnRates, 1)
		add_creature_spawn_chance("ICEE", api.acquire_id("Vibrant_Biomes.Linked_Generator"), .01*Animal_SpawnRates, 1)	

		add_plant_spawn_chance("ICEE", api.acquire_id("Vibrant_Biomes.Bounce_Flower"), .02*Plant_SpawnRates, 2)

		add_creature_spawn_chance("DARK", api.acquire_id("Vibrant_Biomes.Seeking_Destroyer"), 0.003*Animal_SpawnRates, 1)

		add_plant_spawn_chance("DARK", api.acquire_id("Vibrant_Biomes.Dark_Bouy"), .1*Plant_SpawnRates, 2)
		add_plant_spawn_chance("DARK", api.acquire_id("Vibrant_Biomes.Dark_Bouy_Large"), .07*Plant_SpawnRates, 2)
		add_creature_spawn_chance("DARK", api.acquire_id("Vibrant_Biomes.Dark_Bouy_Floating"), .1*Plant_SpawnRates, 300)
		
	
		add_plant_spawn_chance("FIRE", api.acquire_id("Vibrant_Biomes.Blood_Coral"), .05*Plant_SpawnRates, 0)

		add_creature_spawn_chance("FIRE", api.acquire_id("Vibrant_Biomes.Broadside"), .005*Animal_SpawnRates, 50)
		add_creature_spawn_chance("FIRE", api.acquire_id("Vibrant_Biomes.Basher"), .01*Animal_SpawnRates, 20)
		add_creature_spawn_chance("FIRE", api.acquire_id("Vibrant_Biomes.Floating_Barge"), .02*Animal_SpawnRates, 5)
		add_creature_spawn_chance("FIRE", api.acquire_id("Vibrant_Biomes.Canivorous_Barge"), .005*Animal_SpawnRates, 100)

		if Gyre_Animals == true then
			add_creature_spawn_chance("GYRE", api.acquire_id("Vibrant_Biomes.gyre_drifter"), .05*Animal_SpawnRates, 5)
		end
		return unpack(r)
	end
end

return M
