--File: SkillsFramwork/init.lua
--Author: Domtron Vox (domtron.vox@gmail.com)
--Description: Defines a handful of utility functions

--NOTE: saving and loading code barrowed and modified from AdventureTest's modified Default mod

--saves all the skill sets to a file 
SkillsFramework.__save_skillsets = function()
    minetest.log("info", "[SKILLFRAMEWORK, Notice] Saving skills")
    
    --open or create a file at the specified path
    local f = io.open(SkillsFramework.FILEPATH, "w")
    
    --serialise the skillsets then save them to opend file
    f:write(minetest.serialize(SkillsFramework.__skillsets))

    --close the file
    f:close()
end


--loads all the skill sets from the file
SkillsFramework.__load_skillsets = function()
    --try and open the skill sets save file
    local file = io.open(SkillsFramework.FILEPATH, "r")

    --varify file existed and was opened if not print warning.
    if file == nil then 
        minetest.log("[SKILLSFRAMEWORK, WARNING!] Saved skillsets file " .. 
           SkillsFramework.FILEPATH ..
           " not found, if this is not the first time running skillsframework you "  ..
           "may have lost player skills. Check debug and notify the mod author.")
    else

        --read the data from then close the file
        local text = file:read("*all")
        file:close()

        --if the file existed but was empty print warrning
        if text == "" or text == nil then 
            minetest.log("[SKILLSFRAMEWORK, WARNING!] Saved skillsets file  is" ..
                SkillsFramework.FILEPATH .. 
                " blank, if this is not the first time running skillsframework you " ..
                "may have lost player skills. Check debug and notify the mod author.")
        else
            --deserialise the string recovered from the file and place the table under skillsets
            SkillsFramework.__skillsets = minetest.deserialize(text)
        end
    end
end


--returns true if the entity and skill exists and false+an error if they don't.
SkillsFramework.__skill_entity_exists = function(entity, skill)
    --make sure the given entity exists
    if SkillsFramework.__skillsets[entity] then
        --make sure the skill exists
        if SkillsFramework.__skillsets[entity][skill] then
            return true -- both exist we are done
        else
            minetest.log("[SKILLSFRAMEWORK, WARNING!] The skill name "..skill.." is not a registered skill!")
        end
    else
        minetest.log("[SKILLSFRAMEWORK, WARNING!] The entity name "..entity.." is not a valid skill set id!")
    end

    return false --one or the other is missing look for errors in the log
end


--verifies that the experience "bar" does not exceed the to next level value
--  skill_obj: table that has a single skills data from a particular skill set
SkillsFramework.__fix_skill_exp_and_level = function(entity, skill)
    local skill_obj = SkillsFramework.__skillsets[entity][skill]

    while skill_obj["experience"] >= skill_obj["next_level"] do
        skill_obj["experience"] = skill_obj["experience"] - skill_obj["next_level"]
        SkillsFramework.add_level(entity, skill, 1) 
    end
end


--Generates the experience/level bar for a given skill. Returns the formspec string
--    for the bare which will be appended to the main skill formspec string.
function generate_bar(playername, skillname)
        local SF = SkillsFramework
        local level_string = ""

        --convert the level to a string so we can step throught it
	local level = SF.get_level(playername, skillname) .. ""

        --step the length of the sting and convert each digit into images of digits
	for i = 1,#level do
		local char = string.sub(level, i, i)
		level_string = level_string .. ":" .. 14 + (i - #level / 2) * 4 .. ",1=" ..
		"skillsframework_" .. char .. ".png"
	end
        
        --create the formspec string for the bar.
	local bar = "\\[combine:35x7:" 
                    .. (SF.get_experience(playername, skillname) / 
                          SF.get_next_level_cost(playername, skillname) * 35 - 35) 
                    .. ",0=skillsframework_bar.png:0,0=skillsframework_frame.png" .. level_string

	return bar
end
