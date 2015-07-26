--File: skillsFramework/api.lua
--Author: Domtron Vox(domtron.vox@gmail.com)
--Description: Set of functions that make up the API

--shows a formspec for skill GUI interaction.
SkillsFramework.show_formspec = function(playername, page)
        local SF = SkillsFramework

	page = page or 1
	local formspec = "size[8,9]" ..
			"tabheader[0,0;skills_page;"

	for i = 1,math.ceil(#SkillsFramework.__skills_list / 18)do
		formspec = formspec ..
			"Page " .. i .. ","
	end
	formspec = string.sub(formspec, 1, -2)
	formspec = formspec .. ";" .. page .. "]"

	local y_index = 0
	page = page - 1
	for i = 1 + page * 18,18 + page * 18,1 do
		local skillname = SkillsFramework.__skills_list[i]
		if not skillname then
			break
		end
                
		formspec = formspec 
			.. "image[0," .. y_index * .5 + .1 .. ";1.5,.4;" 
                        .. SF.__generate_bar(playername, skillname) .. "]" 
			.. "label[1.5," .. y_index * .5 .. ";Skill: " .. skillname:split(":")[2] 
                        .. "]"
		y_index = y_index + 1
	end
	minetest.show_formspec(playername, "skillsframework:display", formspec)
end

--Adds a new skill definition to the skill system. Data contains:
--  name       : skill's name
--  mod        : registering mod
--  level_func : called on level up; receives skill level integer 
--  group      : name of group the skill belongs to
--  min        : start level value and minimum level
--  max        : maximum level value
SkillsFramework.define_skill = function(data)
    --TODO test that values are the right types (ints, strings, ect)
    --make sure required values are in the table.
    if not data.name then
        minetest.log("[Warning, SkillFramework] Skill registered without name. Skill discarded.")
        return 
    end

    if not data.mod then
        minetest.log("[Warning, SkillFramework] Skill "
                     ..data.name
                     .." registration without mod name. Skill discarded.")
        return
    end

    if not data.level_func then
        minetest.log("[Warning, SkillFramework] Skill "
                     ..data.mod..':'..data.name
                     .." registration without level cost function. Skill discarded.")
        return
    end

    -- do sanity checks on min and max
    if data.min and data.min < 0 then
        minetest.log("[Warning, SkillFramework] Skill "
                     ..data.mod..':'..data.name
                     .."'s min data is less then zero. Setting to zero instead.")
        data.min = 0
    end

    if data.max and data.max < 0 then
        minetest.log("[Warning, SkillFramework] Skill "
                     ..data.mod..':'..data.name
                     .."'s max data is less then zero. Setting to zero instead.")
        data.max = 0
    end

    --create entry for the new skill
    SkillsFramework.__skill_defs[data.mod..':'..data.name] = {
        ["name"] = data.name,              --skill name
        ["mod"] = data.mod,                --name of registering mod
        ["group"] = data.group,            --grouping name
        ["level_func"] = data.level_func,  --function that calculates each levels cost
        ["min"] = data.min or 0,           --minimum level
        ["max"] = data.max or 0,           --maximum level
    }

    --skills are listed on the formspec in the order they are registered.
    table.insert(SkillsFramework.__skills_list, data.mod..':'..data.name)
end


--Creates and then attaches a new skill set to the given identifier.
--  set_id    : skill set id 
SkillsFramework.attach_skillset = function(set_id)
    local skill_defs = SkillsFramework.__skill_defs
    SkillsFramework.__skillsets[set_id] = {}
    local skill_set = SkillsFramework.__skillsets[set_id]

    --create skill data for each registered skill and populate the new skill set
    for skill_id, value in pairs(skill_defs) do
        skill_set[skill_id] = {name = skill_id}

        SkillsFramework.set_level(set_id, skill_id, value["min"])
        SkillsFramework.set_experience(set_id, skill_id, 0)
    end
end

--Deletes a skill set. 
--  set_id    : skill set id 
SkillsFramework.remove_skillset = function(set_id)
    SkillsFramework.__skillsets[set_id] = nil
end

--Return the level of specified skill.
--  set_id    : skill set id 
--  skill_id  : name of the skill to test
SkillsFramework.get_level = function(set_id, skill_id)
    if SkillsFramework.__skill_entity_exists(set_id, skill_id) then
        return SkillsFramework.__skillsets[set_id][skill_id]["level"]
    else
        return nil --skill or entity does not exits
    end
end

--Allows setting the level of a skill in a skill set.
--  set_id    : skill set id 
--  skill     : name of the skill to test
--  level     : new level to set it to
SkillsFramework.set_level = function(set_id, skill, level)
    if SkillsFramework.__skill_entity_exists(set_id, skill) then
        local skill_def = SkillsFramework.__skill_defs[skill]
        local skill_set = SkillsFramework.__skillsets[set_id][skill]

        if level > skill_def.max then
            level = skill_def.max
        end
 
        skill_set["level"] = level

        --calculate new next_level value; if 0 then set to 1 since we need some cost for 
        skill_set["next_level"] = skill_def["level_func"](level+1)
        if skill_set["next_level"] == 0 then 
            skill_set["next_level"] = 1 
        end

    end
end

--Returns the cost of the next level be it in experience or progression points.
--  set_id    : skill set id 
--  skill     : name of the skill to test
SkillsFramework.get_next_level_cost = function(set_id, skill)
    if SkillsFramework.__skill_entity_exists(set_id, skill) then
        return SkillsFramework.__skillsets[set_id][skill]["next_level"]
    else
        return nil
    end
end

--Returns the specified skill's experience.
--  set_id    : skill set id 
--  skill     : name of the skill to test
SkillsFramework.get_experience = function(set_id, skill)
    if SkillsFramework.__skill_entity_exists(set_id, skill) then
        return SkillsFramework.__skillsets[set_id][skill]["experience"]
    else
        return nil
    end
end

--Sets the specified skill's experience.
--  set_id    : skill set id 
--  skill     : name of the skill to test
--  experience : amount to set it to
SkillsFramework.set_experience = function(set_id, skill, experience)
    if SkillsFramework.__skill_entity_exists(set_id, skill) then
        local skill_def = SkillsFramework.__skill_defs[skill]
        local skill_set = SkillsFramework.__skillsets[set_id][skill]
        
        --don't add experience if a level is maxed out.
        if skill_set["level"] >= skill_def.max and not skill_def.max == 0 then
            return true
        end

        --remove decimal portion
        experience = math.floor(experience + 0.5)

        --set the new experience value and make sure a level up occurs if needed
        SkillsFramework.__skillsets[set_id][skill]["experience"] = experience
        SkillsFramework.__fix_skill_exp_and_level(set_id, skill) --see util.lua

        return true
    else
        return false
    end
end


--##Aliases##--

--Four adder functions that add the given value to the attribute
SkillsFramework.add_level = function(set_id, skill, level)
    return SkillsFramework.set_level(set_id, skill, 
                                   SkillsFramework.get_level(set_id, skill)+level)
end

SkillsFramework.add_experience = function(set_id, skill, experience)
    return SkillsFramework.set_experience(set_id, skill, 
                         SkillsFramework.get_experience(set_id, skill)+experience)
end
