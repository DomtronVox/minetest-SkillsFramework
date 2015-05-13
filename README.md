SkillFramework
==============
#About
This is a modification(mod) for [MineTest](minetest.net) that creates a character skill framework. Being a framework, this mod's intended audience are modders and game makers. Its primary purpose is to provide an easy to use yet highly configurable skill system that tracks both experience and levels for registered skills. This mod does not define any skills and is __useless on its own__.

* License: Public Domain
* Mod Version: 0.2
* Minetest Version(s): Minetest 0.4.12
* Dependencies: None
* Git repository: https://github.com/DomtronVox/minetest-SkillsFramework
* Forum thread: [[Mod] SkillsFramework [0.2] [skillsframework]](https://forum.minetest.net/viewtopic.php?f=9&t=11406)

# Feature Summery

* Detailed documentation of code and API.
* __Skill sets__ hold the values for a group of skills.
    * Can be used to describe the skills of either an individual or group.
    * Specific skill set entries that track a skill's level and experience.
* __Skill definitions__ using a name, sort group, and user defined level cost function.
* Functions for accessing and modifying skills.
* Data is saved and loaded from a file for persistence across server or single player shutdown.
* A Formspec for skill viewing and interaction.

# API Reference

__Usage__: SkillsFramework.function_name(arguments)


| Name            | Arguments               | Returns | Description |
|-----------------|-------------------------|---------|-------------|
| show_formspec    | player                  | none | Shows a formspec for graphical skill interaction. |
| register\_skill  | name, group, level_func | none | Adds a new skill definition to the skill system. |
| attach\_skillset | set_id                 | none | Creates and attaches a new skill set to the given identifier.|
| remove\_skillset  | set_id                  | none | Deletes a skill set. |
| set\_level        | set_id, skill, level    | none | Allows setting the level of a skill in a skill set. |
| add\_level        | set_id, skill, level      | none | Adds the given amount to the level. |
| get\_level        | set_id, skill           | int  | Return the level of specified skill. |
| get\_next\_level\_cost | set_id, skill          | int  | Returns the cost of the next level be it in experience or progression points. |
| set\_experience  | set_id, skill, experience | none | Sets the specified skill's experience. |
| add\_experience  | set_id, skill, experience | none | Adds the given amount to the skill. |
| get_experience  | set_id, skill             | int  | Returns the specified skill's experience. |

# Save File
Data for this mod is saved to the world folder in a file called 

# Configuration Options
Settings are Located in settings.lua. They have all capitalized names with underscore spacing and are prefixed with "SkillsFramework.". (I.e. SkillsFramework.HIDE\_ZERO\_SKILLS)

* HIDE\_ZERO\_SKILLS (bool): When true hides skills with a 0 in both level and experience. Allows for 'discovering' skills.
* SAVE_SKILLS (bool): When false skills will not be saved. Use if you want to handle saving skills in another mod.
* SAVE_INTERVAL (positive integer): How often skill data should be saved. This is ignored if save skills is false.
* FILE_NAME (file path string): Location under the world folder where the skill set data is saved.

# Setup and Usage in Three Easy Steps
## 1) Register Skills
Skills must be registered during Minetest's registration period. This is done with the SkillsFramework.add\_skill(name, group, level\_func) function. A skill is defined as a level experience pair with an assigned cost for each level.

* SkillsFramework.register\_skill(data\_table)
    * "data_table" is a table containting info about the skill.

The data table can have the fields listed below. Required means there is no default and the registration fails without it. Table keys need to match the names below exactly.

* mod: __Required__. Name of the mod who is registering the skill.
* name: __Required__. Name the player will see
* level\_func: __Required__. A function that defines the cost of each level. Receives an int that is the next level, should return an int that is the experience cost.
* group: default "none". An arbitrary category name used to sort skills.
* max: default "no max". Maximum level the skill can reach. If less then min, max is ignored.
* min: default "0". Level the skill is initiated to and the level it can not drop below.
* locked: default false. What lock state the skill will start with. If locked the player cannot see the skill and any attempt to change it fails.


###Level Cost Function Examples
Here are two level\_func examples. The first example makes every level cost 100. The second example increases the cost linearly (i.e. level 3 costs 300).

        function(next\_level) return 100 end
        function(next\_level) return 100*next_level end

## 2) Adding Skill Sets
Skill sets are a collection of skills that are attached to unique identifiers (the player's name for example).

This makes skill sets flexible enough to describe the skills of either an individual or a group. For example a skill set can be created and preinitialized for "level one skeletons" allowing any of level one skeleton to use those skills. Of course when using it for a group the modder should not add experience otherwise the entire group will gain levels from actions each individual does. 

Use the SkillsFramework.attach\_skillset(entity) to create a skill set connected to an entity.

* SkillsFramework.attach_skillset(set\_id)
    * "set\_id" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.

## 3) Using and Manipulating Skills
Actions use skills. The definition of an action is upto the modder and needs to be coded. The common places for this code would be in the callbacks for the following 3 types of functions:

* Node definition's "on\_punch" function. You can use MineTest's override function to redefine aspects of a node definition like the on\_punch function.
* On craft function.
* in register\_on\_punchnode. However this can significantly slow down mintest since it is called every time a node is dug and therefore should be used as a last resort.

Of course an action could be implemented most anywhere. Even on the global tick.

For implementing actions, SkillFramework provides various getter and setter functions. The getters are useful in testing against skills. The setters are useful for preinitializing skill sets or rewarding player's actions.

* SkillsFramework.get\_next\_level\_cost(set\_id, skill)
* SkillsFramework.get\_level(set\_id, skill)
* SkillsFramework.set\_level(set\_id, skill, level)
* SkillsFramework.add\_level(set\_id, skill, level)
    * "set\_id" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "skill" the name of the skill to modify.
    * "level" number that the skill level will be assigned or will be added to the skill.


* SkillsFramework.get\_experience(set\_id, skill)
* SkillsFramework.set\_experience(set\_id, skill, experiance)
* SkillsFramework.add\_experience(set\_id, skill, experiance)
    * "set\_id" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "experiance" number that the skill's experiance will be assigned or will be added to the skill.
    * __warning__: setting experience may cause the skill to level up if the added experience puts the skill over the value returned by get\_next\_level\_cost().



Examples 

    --Threshold test
    if SF.get_level("singleplayer", "Combat Knowlage") >= level then 
      --allow player into arena 
    end

    --Randomized success test
    success = SF.get_level("singleplayer", "Smithing") >= rand_num

    --Margin of success
    margin = (rand_num - SF.get_level) / 10
     
    --Increment experience
    SF.add_experience(singleplayer, "Woodcutting", 60)

    --Increment level setting exp to 0
    SF.add_level(singleplayer, "Digging", 1)
    SF.set_experience(singleplayer, "Digging", 0)

# Feedback, Bugs, and Improvements
All feedback and bug reports are welcome. Open a new GitHub issue for bugs or post them and your feedback on the mod's [forum topic](https://forum.minetest.net/viewtopic.php?f=9&t=11406). Most pull requests will be accepted once they have been reviewed. 

# TODO
In order of importance.

* Ongoing: Add user error prevention code (sanity checks).

* Improve skill formspec.
    * fix pages all showing the same 18 skills
    * add an indicator that a skill is maxed out.

* Optional "show last used skills on HUD".

* Better handling of old skill sets when:
    * Players never log in again or haven't logged in for a very long time.
    * Skills have been added or removed from the lua code.
        * If skills are removed consider removing them from skill sets. When implemented this should to be optional(opt-in probebly).

* Add a on\_level\_up function for skills

* Way to see another player's skills for admins and maybe players.

* Let Modders define weather a skill is locked by default and allow them to unlock skills when conditions are met. Could be useful for learning skills or skill trees.

* Support having multiple skill set types rather then just one skill set. Allow attaching a skill set type to an entity. This can be used to simulate classes and maybe other things. Think about allowing multiple skill set types for one entity (multi-classing) and maybe adding specific skills to an entity's skill set (cross class skills).

* Think about implementing multiple skill systems (like originally intended) in a clean way or decide to just make each skill system a separate mod. 
