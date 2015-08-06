SkillFramework
==============
#About
This is a modification(mod) for [MineTest](minetest.net) that creates a character skill framework. Being a framework, this mod's intended audience are modders and game makers. Its primary purpose is to provide an easy to use yet highly configurable skill system that tracks both experience and levels for registered skills. This mod does not define any skills and is __useless on its own__.

* License: Public Domain
* Mod Version: 0.4
* Minetest Version(s): Minetest 0.4.12
* Dependencies: None
* Git repository: https://github.com/DomtronVox/minetest-SkillsFramework
* Forum thread: [[Mod] SkillsFramework [0.4] [skillsframework]](https://forum.minetest.net/viewtopic.php?f=9&t=11406)

# Feature Summery

* Detailed documentation of code and API.
* __Skillsets__ are a collection of unique skill data.
    * Can be used to describe the skills of either an entity or group of entities.
    * Each skill in a skillset keeps a uniqe level and experience counter.
    * Skills can be added to skillsets allowing characters to learn skills.
* __Skill definitions__ using a name, sort group, and user defined level cost function plus some other optional control values like the level cap.
* Functions for accessing and modifying skills.
* Data is saved and loaded from a file for persistence across server or single player shutdown.
* A Formspec for skill viewing.

# API Reference

__Usage__: SkillsFramework.function_name(arguments)


| Name            | Arguments               | Returns | Description |
|-----------------|-------------------------|---------|-------------|
| show_formspec    | player                 | none | Shows a formspec for graphical skill interaction. |
| register\_skill  | data_table             | none | Adds a new skill definition to the skill system. |
| attach\_skillset | set_id                 | none | Creates and attaches a new skill set to the given identifier.|
| remove\_skillset  | set_id                  | none | Deletes a skill set. |
| append\_skills     | set_id, skill or list  | bool | Adds a single skill or list of skills to the indicated skill set. returns false if skill is already added|
| set\_level        | set_id, skill, level    | none | Allows setting the level of a skill in a skill set. |
| add\_level        | set_id, skill, level      | none | Adds the given amount to the level. |
| get\_level        | set_id, skill           | int  | Return the level of specified skill. |
| get\_next\_level\_cost | set_id, skill          | int  | Returns the cost of the next level be it in experience or progression points. |
| set\_experience  | set_id, skill, experience | none | Sets the specified skill's experience. |
| add\_experience  | set_id, skill, experience | none | Adds the given amount to the skill. |
| get\_experience  | set_id, skill             | int  | Returns the specified skill's experience. |

# Save File
Data for this mod is saved to the world folder in a file called by default "skill\_sets" (no extention). However, the file it saves to can be changed see configuration options below.

# Configuration Options
Settings are Located in settings.lua. They have all capitalized names with underscore spacing and are prefixed with "SkillsFramework.". (I.e. SkillsFramework.HIDE\_ZERO\_SKILLS)

* HIDE\_ZERO\_SKILLS (bool): When true hides skills with a 0 in both level and experience. Allows for 'discovering' skills.
* SAVE_SKILLS (bool): When false skills will not be saved. Use if you want to handle saving skills in another mod.
* SAVE_INTERVAL (positive integer): How often skill data should be saved. This is ignored if save skills is false.
* FILE_NAME (file path string): Location under the world folder where the skill set data is saved.
* STARTING_SKILLS (nil or table): What skills new players will receive. If nil all defined skills are added. If an empty array is given no skills will be added. If a populated array is given then each element will be added as a skill (and if it is invalid an error will be printed).

# Setup and Use the SkillsFramework mod
## 1) Register Skills
Skills must be registered during Minetest's registration period. This is done with the SkillsFramework.define\_skill(data\_table) function. A skill is then defined with some basic control values and information.

* SkillsFramework.define\_skill(data\_table)
    * "data_table" is a table containing info about the skill.

The data table can have the fields listed below. Required means there is no default and the registration fails without it. Table keys need to match the names below exactly.

* mod: __Required__. Name of the mod who is registering the skill.
* name: __Required__. Name the player will see
* cost\_func: __Required__. A function that defines the cost of each level. Receives an int that is the next level, should return an int that is the experience cost.
* group: default "none". An arbitrary category name used to sort skills.
* max: default no limit. Maximum level the skill can reach. If less then min, max is ignored.
* min: default "0". Level the skill is initiated to and the level it can not drop below.
* on\_levelup: default none. A function called whenever the next level experience requirement is met. Receives both a set_id of the skillset that is leveling up that int that is the new level that was just attained. Return value is ignored.

Example use of define\_skill.

        SkillsFramework.define\_skill({"mod":"thediggingmod"
                                      ,"name":"Digging"
                                      ,"cost_func":function(level) return 400*level end
                                      ,"group":"Landscaping"
                                      ,"max": 20
                                      ,"min": 1
                                      ,"on_levelup":dig_levelup_func})

###Level Cost Function Examples
Here are two cost\_func examples. The first example makes every level cost 100. The second example increases the cost linearly (i.e. level 3 costs 300).

        function(level) return 100 end
        function(level) return 100*level end

### On Levelup Function Examples
Here is an example function that help explain the usefulness of the on\_levelup function. Here I assume that the skills digging and mining are defined and that digging is given to the player from the start while mining must be learned. We could give the player the mining skill once he has reached a certain digging level by defining the digging skill with the following on\_levelup function :

        digging_definition["on_levelup"] = function(set_id, level)
            if level == 3 then
                Skillsframework.append_skills(set_id, "thediggingmod:Mining"
            end
        end

## 2) Adding Skillsets
Skillsets are collections of skills that are attached to unique identifiers (the player's name for example).

This makes skillsets flexible enough to describe the skills of either an individual or a group. For example a skill set can be created and preinitialized for "level one skeletons" allowing any of level one skeleton to use those skills. Of course when using it for a group the modder should not add experience to skills on each use otherwise the entire group will gain levels from actions each individual does. 

Use the SkillsFramework.attach\_skillset(set\_id, skills) to create a skillset connected to an entity.

* SkillsFramework.attach_skillset(set\_id, skills)
    * "set\_id" is an unique identifier. This could be the entity's Minetest ID for individuals or a unique string for groups.
    * "skills" is an array of skill names that will be placed into the skillset. Passing nil will add all skills to the skill set. If a string is given it will assume the string is one skill.

## 3) Using and Manipulating Skills
Actions use skills. The definition of an action is upto the modder and needs to be implemented in code. The common places for this code would be in the callbacks for the following 3 types of functions:

* Node definition's "on\_punch" function. You can use MineTest's override function to redefine aspects of a node definition like the on\_punch function.
* On craft function.
* in register\_on\_punchnode. However this can significantly slow down mintest since it is called every time a node is dug and therefore should be used as a last resort.

Of course, an action could be implemented just about anywhere. Even during global tick.

For implementing actions, SkillFramework provides various getter and setter functions. The getters are useful in testing against skills. The setters are useful for preinitializing skill sets or rewarding player's actions.

* SkillsFramework.get\_next\_level\_cost(set\_id, skill)
* SkillsFramework.get\_level(set\_id, skill)
* SkillsFramework.set\_level(set\_id, skill, level)
* SkillsFramework.add\_level(set\_id, skill, level)
    * "set\_id" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "skill" the name of the skill to modify.
    * "level" number that the skill level will be assigned or will be added to the skill.;


* SkillsFramework.get\_experience(set\_id, skill)
* SkillsFramework.set\_experience(set\_id, skill, experience)
* SkillsFramework.add\_experience(set\_id, skill, experience)
    * "set\_id" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "experience" number that the skill's experience will be assigned or will be added to the skill.
    * __warning__: setting experience may cause the skill to level up if the added experience puts the skill over the value returned by get\_next\_level\_cost(). Experiance will not be added if the skill is at the level cap.



Examples 

    --Threshold test
    if SF.get_level("singleplayer", "Combat Knowledge") >= level then 
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

However, some skills should not be available to all entities. You may want certain skills to be associated with a class and/or have to be learned. In this case skills can be added using the append\_skill function. If a skill is already in the skillset the function will do nothing.

* SkillsFramework.append\_skills(set_id, skills) returns bool
    * "set\_id" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "skills" an array of skill ids (mod:skill) that will be added to the skill set.
    * returns a bool; true if the skill was added; false if the skill was already in the skill set.


# Feedback, Bugs, and Improvements
All feedback and bug reports are welcome. Open a new GitHub issue for bugs or post them and your feedback on the mod's [forum topic](https://forum.minetest.net/viewtopic.php?f=9&t=11406). Most pull requests will be accepted once they have been reviewed. 

# TODO
In order of importance.

* Ongoing: Add user error prevention code (sanity checks).

* Improve skill formspec.
    * fix pages all showing the same 18 skills
    * add an indicator that a skill is at the maximum level.
    * group skills by type

* Optional "show last used skills on HUD".

* Better handling of old skill sets when:
    * Players never log in again or haven't logged in for a very long time.
    * Skills have been added or removed from the lua code.
        * If skills are removed consider removing them from skill sets. When implemented this should to be optional for the game maker(opt-in probebly).

* Way to see another player's skills for admins and maybe other players.

* Think about implementing multiple skill systems (like originally intended) in a clean way or decide to just make each skill system a separate mod. Alternate: have different skillsystems as seprate mods that depend on skillsframwork
