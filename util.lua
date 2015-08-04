--File: SkillsFramwork/init.lua
--Author: Domtron Vox (domtron.vox@gmail.com)
--Description: Defines a handful of utility functions specifically for keeping the 
--          API lua file short and to remove code duplication.

--###Serialization###
--NOTE: saving and loading code barrowed and modified from AdventureTest's modified Default mod



--saves all the skill sets to a file 
SkillsFramework.__save_skillsets = function()
    minetest.log("info", "[SKILLFRAMEWORK, Notice] Saving skills")
    
    --open or create a file at the specified path
    local f = io.open(minetest.get_worldpath()..SkillsFramework.FILE_NAME, "w")
    
    --serialise the skillsets then save them to opend file
    f:write(minetest.serialize(SkillsFramework.__skillsets))

    --close the file
    f:close()
end


--loads all the skill sets from the file
SkillsFramework.__load_skillsets = function()
    --try and open the skill sets save file
    local file = io.open(minetest.get_worldpath()..SkillsFramework.FILE_NAME, "r")

    --varify file existed and was opened if not print warning.
    if file == nil then 
        SkillsFramework.log("Saved skillsets file " .. 
           minetest.get_worldpath()..SkillsFramework.FILE_NAME ..
           " not found, if this is not the first time running skillsframework you "  ..
           "may have lost player skills. Check debug and notify the mod author.")
    else

        --read the data from, then close the file
        local text = file:read("*all")
        file:close()

        --if the file existed but was empty print warning
        if text == "" or text == nil then 
            SkillsFramework.log("Saved skillsets file, " .. minetest.get_worldpath() ..
                SkillsFramework.FILE_NAME .. 
                ", is blank. If this is not the first time running skillsframework you " ..
                "may have lost player skills. Check your logs and notify the mod author.")
        else
            --deserialise the string recovered from the file and place the table under skillsets
            SkillsFramework.__skillsets = minetest.deserialize(text)
        end
    end
end



--###TESTING FUNCTIONS###


--Returns true if the skill definition exists
SkillsFramework.__skilldef_exists = function(skill_id, silent)
    if SkillsFramework.__skill_defs[skill_id] then
        return true
    else
        if silent == false and silent ~= nil then
            SkillsFramework.log("The skill name "..skill_id.." has not been defined! " ..
                                "devs: Check that you are using modname:skillname.")
        end
        return false
    end
end

--Returns true if the skill definition exists
SkillsFramework.__skillset_exists = function(set_id, silent)
    if SkillsFramework.__skillsets[set_id] then
        return true
     else
        if silent == false and silent ~= nil then
            SkillsFramework.log("The entity name "..set_id.." is not a valid skillset id!")
        end
        return false
    end
end

--Returns true if the skillset has the given skill
SkillsFramework.__skillset_has_skill = function(set_id, skill_id, silent)
    if SkillsFramework.__skilldef_exists(skill_id, silent) and
       SkillsFramework.__skillset_exists(set_id, silent) then
    
        if SkillsFramework.__skillsets[set_id][skill_id] then
            return true
        else
            if silent == false and silent ~= nil then
                SkillsFramework.log("The skill name "..skill_id.." is not in the skillset " ..
                                    set_id .. "!")
            end
            return false
        end
    else 
        return false
    end
end


--Make sure given data table has the required fields to define a new skill. 
--   Also make sure values are of the correct type.
SkillsFramework.__validate_skilldef_data = function(data)

    if not data.name then
        SkillsFramework.log("Skill registered without name. Skill discarded.")
        return nil

    elseif type(data.name) ~= "string" then
        SkillsFramework.log("Skill registered with a name value that is not a " ..
                            "string. Skill discarded. Value received was:")
        print(dump(data.name))
        return nil
    end

    if not data.mod then
        SkillsFramework.log("Skill " .. data.name ..
                            " registration without mod name. Skill discarded.")
        return nil

    elseif type(data.mod) ~= "string" then
        SkillsFramework.log("Skill " .. data.name ..
                            " registered with a mod name value that is not a string."..
                            " Skill discarded. Value recived was:")
        print(dump(data.mod))
        return nil
    end

    local skill_id = data.mod .. ':' .. data.name

    if not data.cost_func then
        SkillsFramework.log("Skill " .. skill_id ..
                       " was registered without a level cost function. Skill discarded.")
        return nil
    elseif type(data.cost_func) ~= "function" then
        SkillsFramework.log("Skill " .. skill_id .. " given value for level cost" ..
                            " function not a function. Skill discarded. Vslue recived was:")
        print(dump(data.cost_func))
        return nil
    end

    -- do sanity checks on min and max
    if data.min and data.min < 0 then
        SkillsFramework.log("Skill " .. data.mod .. ':' .. data.name ..
                            "'s min data is less then zero. Setting to zero instead.")
        data.min = 0
    end

    if data.max and data.max < 0 then
        SkillsFramework.log("Skill " .. data.mod .. ':' .. data.name ..
                            "'s max data is less then zero. Setting to zero instead.")
        data.max = 0
    end

--    if data.max and data.min and data.max ~= 0 and data.max < data.min then
--        SkillsFramework.log("Skill " .. data.mod .. ':' .. data.name
--                 "'s max level is less then the min level. Setting max to zero instead.")
--        data.max = 0
--    end

    --varify levelup function is actually a function
    if type(data.on_levelup) ~= "function" and data.on_levelup ~= nil then
        SkillsFramework.log("Skill " .. skill_id .. " given value for on_levelup" ..
                            " function not a function. Levelup func set to nil. Vslue recived was:")
        print(dump(data.on_levelup))
        data.on_levelup = nil
    end

    return data
end

--###SKILL MODIFYING FUNCTIONS###



--creates the data for a particular skill in a skill set
SkillsFramework.__instantiate_skilldata = function(set_id, skill_id)
    local skill_def = SkillsFramework.__skill_defs[skill_id]

    --make sure skill is registered
    if SkillsFramework.__skilldef_exists(skill_id) == false then
        SkillsFramework.log("attempted to create skill data for skillset " ..
                     set_id .. ". See previous message.")

    --make sure skillset exists
    elseif SkillsFramework.__skillset_exists(set_id) == false then
        SkillsFramework.log("attempted to create skill data for skill " .. 
                            skill_id .. " but failed. See previous message.")

    --check if skill has already been created.
    elseif SkillsFramework.__skillset_has_skill(set_id, skill_id, true) then
        SkillsFramework.log("attempted to create skill data for skill " ..
                     skill_id .. " in skill set " .. set_id ..
                     " but the player already has the skill. Nothing has changed.")

    --create the skill if everything else is good. 
    else
        --create a new entry for this skill in the given skill set and populate it
        SkillsFramework.__skillsets[set_id][skill_id] = {name = skill_id}

        SkillsFramework.set_level(set_id, skill_id, skill_def["min"])
        SkillsFramework.set_experience(set_id, skill_id, 0)
    end
end

--verifies that the experience "bar" does not exceed the to next level value
--  skill_obj: table that has a single skills data from a particular skill set
SkillsFramework.__fix_skill_exp_and_level = function(set_id, skill_id)
    local on_levelup = SkillsFramework.__skill_defs[skill_id]["on_levelup"]
    local skill_obj = SkillsFramework.__skillsets[set_id][skill_id]

    while skill_obj["experience"] >= skill_obj["next_level"] do
        skill_obj["experience"] = skill_obj["experience"] - skill_obj["next_level"]
        SkillsFramework.add_level(set_id, skill_id, 1) 
        
        --call on_levelup callback
        if on_levelup then
            on_levelup(set_id, SkillsFramework.get_level(set_id, skill_id))
        end
    end
end



--###MISC UTILITY FUNCTIONS###



--Logging function to simplify the rest of the code. Takes a string as the message.
SkillsFramework.log = function(mesg)
    --we use error as the log level so it shows up. We also add the mods prefix to the message
    minetest.log("error", "[SKILLSFRAMEWORK, WARNING!] "..mesg)
end


--Generates the experience/level bar for a given skill. Returns the formspec string
--    for the bare which will be appended to the main skill formspec string.
SkillsFramework.__generate_bar = function(playername, skill_id)
        local SF = SkillsFramework
        local level_string = ""

        --convert the int level to a string so we can step through each character
	local level = SF.get_level(playername, skill_id) .. ""

        --step the length of the sting and convert each digit into images of digits
	for i = 1,#level do
		local char = string.sub(level, i, i)
		level_string = level_string .. ":" .. 14 + (i - #level / 2) * 4 .. ",1=" ..
		"skillsframework_" .. char .. ".png"
	end
        
        --create the formspec string for the bar.
	local bar = "\\[combine:35x7:" 
                    .. (SF.get_experience(playername, skill_id) / 
                          SF.get_next_level_cost(playername, skill_id) * 35 - 35) 
                    .. ",0=skillsframework_bar.png:0,0=skillsframework_frame.png" .. level_string

	return bar
end
