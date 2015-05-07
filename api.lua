--File: skillsFramework/api.lua
--Author: Domtron Vox(domtron.vox@gmail.com)
--Description: Set of functions that make up the API

--shows a formspec for skill GUI interaction.
SkillsFramework.showFormspec = function(playername, page)
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
		formspec = formspec ..
			"image[0," .. y_index * .5 + .1 .. ";1.5,.4;" .. generateBar(playername, skillname) .. "]" ..
			"label[1.5," .. y_index * .5 .. ";Skill: " .. skillname .. "]"
		y_index = y_index + 1
	end
	minetest.show_formspec(playername, "skillsframework:display", formspec)
end

--Adds a new skill definition to the skill system.
--  name       : skill's name
--  group      : name of group the skill belongs to
--  level_func : called on level up; receives skill level integer 
SkillsFramework.defineSkill = function(name, group, level_func)

    --calculate experience point cost for next level
    local next_lvl = level_func(1)

    --create entry for the new skill
    SkillsFramework.__base_skillset[name] = {
        ["name"] = name,              --skill name
        ["group"] = group,            --grouping name
        ["level"] = 0,                --current level
        ["experience"] = 0,           --current experience
        ["next_level"] = next_lvl,    --cost to reach next level (pp or exp)
        ["level_func"] = level_func   --function that calculates each levels cost
    }

    --skills are listed on the formspec in the order they are registered.
    table.insert(SkillsFramework.__skills_list, name)
end

--Tests a skill to see if the action succeeds.
--  entity    : skill set id 
--  skill     : name of the skill to test
--  test_func : does the test; revives skill level; returns bool
SkillsFramework.trySkill = function(entity, skill, test_func)
    --make sure the given entity and skill exists
    if SkillsFramework.__skillEntityExists(entity, skill) then --see util.lua

        --skill set
        local SSet = SkillsFramework.__skillsets[entity]
        
        local result = test_func(SSet[skill]["level"], SSet[skill]["experience"])

        -- if the skill is not static then add the experience
        if not SSet[skill]["static"] then
            SkillsFramework.addExperience(entity, skill, result)
        end

        --make sure level up happens if it should
        SkillsFramework.__fixSkillExpAndLevel(entity, skill) --see util.lua

        return result
    end
end

--Creates and then attaches a new skill set to the given identifier.
--  entity    : skill set id 
SkillsFramework.attachSkillset = function(entity, static)
    local base_set = SkillsFramework.__base_skillset
    SkillsFramework.__skillsets[entity] = {}

    --copy the base skill set into the new entity's skill set
    for skill, value in pairs(base_set) do
        SkillsFramework.__skillsets[entity][skill] = value
        SkillsFramework.__skillsets[entity][skill]["static"] = static
    end
end

--Deletes a skill set. 
--  entity    : skill set id 
SkillsFramework.removeSkillSet = function(entity)
    SkillsFramework.__skillsets[entity] = nil
end

--Return the level of specified skill.
--  entity    : skill set id 
--  skill     : name of the skill to test
SkillsFramework.getLevel = function(entity, skill)
    if SkillsFramework.__skillEntityExists(entity, skill) then
        return SkillsFramework.__skillsets[entity][skill]["level"]
    else
        return nil --skill or entity does not exits
    end
end

--Allows setting the level of a skill in a skill set.
--  entity    : skill set id 
--  skill     : name of the skill to test
--  level     : new level to set it to
SkillsFramework.setLevel = function(entity, skill, level)
    if SkillsFramework.__skillEntityExists(entity, skill) then
        local skill_obj = SkillsFramework.__skillsets[entity][skill]
        --set the level
        skill_obj["level"] = level
        --fix next_level value
        skill_obj["next_level"] = skill_obj["level_func"](level+1) 
    end
end

--Returns the cost of the next level be it in experience or progression points.
--  entity    : skill set id 
--  skill     : name of the skill to test
SkillsFramework.getNextLevelCost = function(entity, skill)
    if SkillsFramework.__skillEntityExists(entity, skill) then
        return SkillsFramework.__skillsets[entity][skill]["next_level"]
    else
        return nil
    end
end

--Returns the specified skill's experience.
--  entity    : skill set id 
--  skill     : name of the skill to test
SkillsFramework.getExperience = function(entity, skill)
    if SkillsFramework.__skillEntityExists(entity, skill) then
        return SkillsFramework.__skillsets[entity][skill]["experience"]
    else
        return nil
    end
end

--Sets the specified skill's experience.
--  entity    : skill set id 
--  skill     : name of the skill to test
--  experience : amount to set it to
SkillsFramework.setExperience = function(entity, skill, experience)
    if SkillsFramework.__skillEntityExists(entity, skill) then        
        --remove decimal portion
        experience = math.floor(experience + 0.5)

        --set the new experience value and make sure a level up occurs if needed
        SkillsFramework.__skillsets[entity][skill]["experience"] = experience
        SkillsFramework.__fixSkillExpAndLevel(entity, skill) --see util.lua

        return true
    else
        return false
    end
end


--##Aliases##--

--Four adder functions that add the given value to the attribute
SkillsFramework.addLevel = function(entity, skill, level)
    return SkillsFramework.setLevel(entity, skill, 
                                   SkillsFramework.getLevel(entity, skill)+level)
end

SkillsFramework.addExperience = function(entity, skill, experience)
    return SkillsFramework.setExperience(entity, skill, 
                         SkillsFramework.getExperience(entity, skill)+experience)
end
