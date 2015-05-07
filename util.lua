--File: SkillsFramwork/init.lua
--Author: Domtron Vox (domtron.vox@gmail.com)
--Description: Defines a handful of utility functions

--NOTE: saving and loading code barrowed and modified from AdventureTest's modified Default mod

--saves all the skill sets to a file 
SkillsFramework.__saveSkillsets = function()
    minetest.log("info", "[SKILLFRAMEWORK, Notice] Saving skills")
    
    --open or create a file at the specified path
    local f = io.open(SkillsFramework.FILEPATH, "w")
    
    --serialise the skillsets then save them to opend file
    f:write(minetest.serialize(SkillsFramework.__skillsets))

    --close the file
    f:close()
end


--loads all the skill sets from the file
SkillsFramework.__loadSkillsets = function()
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
SkillsFramework.__skillEntityExists = function(entity, skill)
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
SkillsFramework.__fixSkillExpAndLevel = function(entity, skill)
    local skill_obj = SkillsFramework.__skillsets[entity][skill]

    while skill_obj["experience"] >= skill_obj["next_level"] do
        skill_obj["experience"] = skill_obj["experience"] - skill_obj["next_level"]
        SkillsFramework.addLevel(entity, skill, 1) 
    end
end
