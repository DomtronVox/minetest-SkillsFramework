--File: SkillsFramwork/init.lua
--Author: Domtron Vox (domtron.vox@gmail.com)
--Description: SkillsFramwork mod init file. Creates global variable for accessing
--  the framework, imports API & util file, and sets up minetest.register_on functions.

SkillsFramework = {} --global variable that holds API and data

--holds skill information for each entity assigned a skill set
SkillsFramework.__skillsets = {}

--a base skill set which acts as a base for new skillsets 
SkillsFramework.__base_skillset = {}

--load important stuff
dofile(minetest.get_modpath(minetest.get_current_modname()).."/settings.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/util.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/api.lua")


--countdown to save all skillsets
SkillsFramework.__savetimer = SkillsFramework.SAVE_INTERVAL


--##Handle server status changes##
--load data on startup
SkillsFramework.__loadSkillsets() --see util.lua

--save data on shutdown
minetest.register_on_shutdown(function()
    --Note: not guaranteed to be called if minetest crashes which is why
    --    we save regularly in globalstep below
    SkillsFramework.__saveSkillsets() --see util.lua
end)

--modify save countdown each global step and save when zero
minetest.register_globalstep(function(dtime)
     --decrement timer
     SkillsFramework.__savetimer = SkillsFramework.__savetimer - dtime

     if SkillsFramework.__savetimer <= 0 then
         --reset timer
         SkillsFramework.__savetimer = SkillsFramework.SAVE_INTERVAL
         
         SkillsFramework.__saveSkillsets() --see util.lua
     end
end)

--##Handle player related events##
--setup a new player
minetest.register_on_newplayer(function(player)
    SkillsFramework.attachSkillset(player:get_player_name())
end)

--on join make sure player exists and that he has all the currently registered skills
--  Note: keep skills nolonger registerd for now
minetest.register_on_joinplayer(function(player)

    local plyname = player:get_player_name()

    if SkillsFramework.__skillsets[plyname] ~= nil then

        --Server has a recored of the players skills but lets make sure he has 
        --  all of them in case more skills were added
        for skill, value in pairs(SkillsFramework.__base_skillset) do

            if SkillsFramework.__skillsets[plyname][skill] == nil then
                SkillsFramework.__skillsets[plyname][skill] = value
            end

        end
    else

        --either player joined before skills were added or some other issue occurred
        --  give this poor lost soul a skill set!
        SkillsFramework.attachSkillset(plyname)

    end
end)

--save data when a player leaves
minetest.register_on_leaveplayer(function(ObjectRef)
    SkillsFramework.__saveSkillsets()
end)


--Chat command to list off skills. 
--TODO: not feasible when there are many skills, fix.
minetest.register_chatcommand("skills", {
    params = "",
    description = "Mod Manuel: Usage: /man <object name>",
    func = function(PCname, param)
        local SF = SkillsFramework
        --loop through each skill and print it
        for skillname,v in pairs(SF.__skillsets[PCname]) do
            minetest.chat_send_player(PCname,
                skillname .. 
                " - Level: " .. 
                SF.getLevel(PCname, skillname) .. 
                "; Experience: " ..
                SF.getExperience(PCname, skillname) ..
                "; Next Level: " ..
                SF.getNextLevelCost(PCname, skillname)
            )
        end
    end
})

