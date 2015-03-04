--File: SkillsFramwork/init.lua
--Author: Domtron Vox (domtron.vox@gmail.com)
--Description: SkillsFramwork mod settings file.

--bool. When true hides skills whose level is 0 from the player.
SkillsFramework.HIDE_ZERO_SKILLS = false

--bool. When false skills will not be saved. Good if you want to handle saving skills in another mod.
SkillsFramework.SAVE_SKILLS = true

--positive integer. How often skill data should be saved. This is ignored if 
--    save skills is false.
SkillsFramework.SAVE_INTERVAL = 1000 --milliseconds

--filepath where all skillsets are saved 
SkillsFramework.FILEPATH = minetest.get_worldpath().."/skill_sets"

