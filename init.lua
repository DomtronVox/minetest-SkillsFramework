--File: SkillsFramwork/init.lua
--Author: Domtron Vox (domtron.vox@gmail.com)
--Description: SkillsFramwork mod init file. Creates global variable for accessing
--  the framework, imports API & util file, and sets up minetest.register_on functions.

SkillsFramework = {} --global variable that holds API and data

--holds skill information for each entity assigned a skill set
SkillsFramework.__skillsets = {}

--a table of all skill definitions
SkillsFramework.__skill_defs = {}

--the order of the skills for display
SkillsFramework.__skills_list = {}

--load important stuff
dofile(minetest.get_modpath(minetest.get_current_modname()).."/settings.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/util.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/api.lua")


--countdown to save all skillsets
SkillsFramework.__savetimer = SkillsFramework.SAVE_INTERVAL


--##Handle server status changes##
--load data on startup
SkillsFramework.__load_skillsets() --see util.lua

--save data on shutdown
minetest.register_on_shutdown(function()
    --Note: not guaranteed to be called if minetest crashes which is why
    --    we save regularly in globalstep below
    SkillsFramework.__save_skillsets() --see util.lua
end)

--modify save countdown each global step and save when zero
minetest.register_globalstep(function(dtime)
     --decrement timer
     SkillsFramework.__savetimer = SkillsFramework.__savetimer - dtime

     if SkillsFramework.__savetimer <= 0 then
         --reset timer
         SkillsFramework.__savetimer = SkillsFramework.SAVE_INTERVAL
         
         SkillsFramework.__save_skillsets() --see util.lua
     end
end)


--function for switching between pages of the skill formspec
minetest.register_on_player_receive_fields(function(player, formname, fields)
        -- verify this form is the skillframework form
	if (formname ~= "skillsframework:display") then
		return
	end

        --switch to the page whose button was clicked.
	if (fields["skills_page"]) then
		SkillsFramework.show_formspec(player:get_player_name(), fields["skills_page"])
	end
end)




--##Handle player related events##
--setup a new player
minetest.register_on_newplayer(function(player)
    SkillsFramework.attach_skillset(player:get_player_name())
end)


--on join make sure player exists and that he has all the currently registered skills
--  Note: keep skills nolonger registerd for now
minetest.register_on_joinplayer(function(player)

    local plyname = player:get_player_name()

    if SkillsFramework.__skillsets[plyname] ~= nil then

        --Server has a recored of the players skills but lets make sure he has 
        --  all of them in case more skills were added
        for skill, value in pairs(SkillsFramework.__skill_defs) do

            if SkillsFramework.__skillsets[plyname][skill] == nil then
                --TODO This is the same code as attach_skillset. code duplication bad so fix it.
                SkillsFramework.__skillsets[plyname][skill] = {name = skill}

                SkillsFramework.set_level(set_id, skill_id, SkillsFramework.__skill_defs[skill]["min"])
                SkillsFramework.set_experience(set_id, skill_id, 0)
            end

        end
    else

        --either player joined before skills were added or some other issue occurred
        --  give this poor lost soul a skill set!
        SkillsFramework.attach_skillset(plyname)

    end
end)


--save data when a player leaves
minetest.register_on_leaveplayer(function(ObjectRef)
    SkillsFramework.__save_skillsets()
end)

--do some stuff right after the game starts
minetest.after(0, function()

    --TODO: block new skills from being added.
    
end)


--Chat command to list off skills. 
minetest.register_chatcommand("skills", {
    params = "skill",
    description = "Skill Framework: Usage: '/skills' lists all skill names."..
                  "'/skills <skill name>' prints data on the requested skill."..
                  "'/Skills @gui' opens the skills formspec.",
    func = function(PCname, param)
        local SF = SkillsFramework

        --list what skills are avalible to the player
        if param == "" then
            local skill_list = ""

            --TODO: when disable/enable skill is implemented only list enabled skills
            for skillname,v in pairs(SkillsFramework.__skillsets[PCname]) do
                skill_list = skill_list..skillname..", "
            end

            minetest.chat_send_player(PCname, skill_list)

         --open the formspec with a chat command
         elseif param == "@gui" then
             SF.show_formspec(PCname)

         --TODO: make skill name parameter more lenient (i.e. allow both digging and Digging)
         -- the param is the skill so print the data if possible
         elseif SkillsFramework.__skillEntityExists(PCname, param) then
             minetest.chat_send_player(PCname,
                  param .. 
                  " - Level: " .. 
                  SF.get_level(PCname, param) .. 
                  "; Experience: " ..
                  SF.get_experience(PCname, param) ..
                  "; Next Level: " ..
                  SF.get_next_level_cost(PCname, param)
              )

         --all else has failed. print an error
         else
             minetest.chat_send_player(PCname, "\""..param.."\" is not a skill you have. make sure you spelled it right including capitalization.")
         end
    end --function end
})
