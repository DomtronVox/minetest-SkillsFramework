#About
This is a modification(mod) for [MineTest](minetest.net) that creates a character skill framework. Being a framework, this mod's intended audience is modders and game makers. Its primary purpose is to provide an easy to use yet highly configurable skill system that tracks both experience and levels for registered skills. This mod does not define any skills and is __useless on its own__.

# License
Public Domain

# Feature Summery

* Detailed documentation of code and API.
* Skill system where each skill gains experience by being used.
* __Skill sets__ are defined with unique identifiers allowing them to describe either individual's or a group's skills.
* Specific skill set entries that track a skill's level and experience.
* General __skill definitions__ using a name, sort group, and user defined level cost function.
* A function for testing/trying a skill when an action occurs.
* A Formspec for skill viewing and interaction.

# API Reference

__Usage__: SkillsFramework.function_name(arguments)


| Name            | Arguments               | Returns | Description |
|-----------------|-------------------------|---------|-------------|
| showFormspec    | player                  | none | Shows a formspec for graphical skill interaction. |
| defineSkill     | name, group, level_func | none | Adds a new skill definition to the skill system. |
| trySkill        | entity, name, test_func | int  | Tests a skill to see if the action succeeds. |
| attachSkillset  | entity, static=false    | none | Creates and then attaches a new skill set to the given identifier.|
| removeSkillSet  | entity                  | none | Deletes a skill set. |
| setLevel        | entity, skill, level    | none | Allows setting the level of a skill in a skill set. |
| getLevel        | entity, skill           | int  | Return the level of specified skill. |
| getNextLevelCost | entity, skill          | int  | Returns the cost of the next level be it in experience or progression points. |
| setExperience  | entity, skill, experience | none | Sets the specified skill's experience. |
| getExperience  | entity, skill             | int  | Returns the specified skill's experience. |

# Configuration Options
Settings are Located in settings.lua. They have all capitalized names with underscore spacing and are prefixed with "SkillsFramework.". (I.e. SkillsFramework.HIDE\_ZERO\_SKILLS)

* HIDE\_ZERO\_SKILLS (bool): When true hides skills with a 0 in both level and experience. Allows for 'discovering' skills.
* SAVE_SKILLS (bool): When false skills will not be saved. Use if you want to handle saving skills in another mod.
* SAVE_INTERVAL (positive integer): How often skill data should be saved. This is ignored if save skills is false.

# Setup and Usage in Three Easy Steps
## 1) Register Skills
Skills must be registered during Minetest's registration period. This is done with the SkillsFramework.addSkill(name, group, level\_func) function. A skill is defined as a level experience pair with an assigned cost for each level.

* SkillsFramework.addSkill(name, group, level\_func)
    * "name" is an identifier for the skill and what the player will see.
    * "group" is an arbitrary category name used to sort/group skills.
    * "level_func" is a function called when a new skill set is created and on each subsequent level up. It needs to receive the skill's next level and must return a number which is the cost for that next level in experience.

###Level Cost Function Examples
Here are two level_func examples. The first example makes every level cost 100. The second example increases the cost linearly (i.e. level 3 costs 300).

        function(next_level) return 100 end
        function(next_level) return 100*next_level end

## 2) Adding Skill Sets
Skill sets are a collection of skills that are attached to unique identifiers (the player's name for example). This makes skill sets flexible enough to describe the skills of either an individual or a group. For example a skill set can be created and preinitialized for "level one skeletons" allowing any of them to use those skills. When doing this the skill set should be set as static(it will not gain experience) otherwise the group will gain experience from actions each individual does. Use the SkillsFramework.attachSkillset(entity, static=false) to create a skill set connected to an entity.

* SkillsFramework.attachSkillset(entity, static=false)
    * "entity" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "static" (default: __false__) is a bool that when true turns off experience gain for the skill set.

### Manually Modifying Skill Sets
Manually manipulating skills is useful for preinitializing skill sets or rewarding players. This is done with a handful of getter and setter functions. __Note__ that normal progression is handled automatically these functions are only needed for special cases.

These two functions respectively retrieves and sets a skill's level value.

* SkillsFramework.getLevel(entity, skill)
* SkillsFramework.setLevel(entity, skill, level)
    * "entity" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "skill" the name of the skill to modify.
    * "level" number that the skill level will be assigned.
    * __warning__: setting the level also resets experience to 0. Save the experience before and set it afterwards if you want to keep the experience (this may cause the skill to level up again so be careful).

These two functions respectively retrieves and sets a skill's experience value.

* SkillsFramework.getExperience(entity, skill)
* SkillsFramework.setExperience(entity, skill, level)
    * "entity" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "level" number that the characters level will be assigned.
    * __warning__: setting experience may cause the skill to level up.

## 3) Using Skills
An action is said to occur whenever SkillsFramework.trySkill is called. There are three common places to call trySkill:

* in a node definition's "on\_punch" function. You can use MineTest's override function to redefine aspects of a node definition like the on\_punch function.
* in a registered on craft function.
* in register\_on\_punchnode. However this can significantly slow down mintest since it is called every time a node is dug and therefore should be used as a last resort.

* SkillsFramework.trySkill(entity, skill, test\_func)
    * "entity" is an unique identifier. This should be the entity's Minetest ID for individuals or a unique string for groups.
    * "skill" the name of the skill to test/check.
    * "test_func" is a function that receives the skill level and experience worth and returns a number.

The __test_func__ returns a number which is the amount of experience that will be added to the skill. The trySkill function will then return the same number to its caller allowing for further processing (i.e. adding special meta data to a crafted item). 


#### Using Multiple Skills
If an action requires several skill checks, a modder could do two things. He could call them in parallel in the "on something" registration function and then combined the results to determine the action's success.

    result1 = trySkill("singleplayer", "woodworking", function(lvl, exp)
        *do dice roll/random number gen and checking*
        return myresult
    end)
    result2 = trySkill("singleplayer", "metalworking", function(lvl, exp)
        *do dice roll/random number gen and checking*
        return myresult
    end)

    *do tests against result 1 and 2*

If the success of one skill depends on the success of another, he could also chain trySkill calls within a trySkill test function.

    result = trySkill("singleplayer", "woodworking", function(lvl, exp)
        inside_result = trySkill("singleplayer", "knowledge: botany", function(lvl, exp)
            *do dice roll/random number gen and checking*
            return myresult
        end)

        *do dice roll/random number gen and checking*
        return myresult
    end)

# Feedback, Bugs, and Improvements
All feedback and bug reports are welcome. Open a new GitHub issue for bugs or post them and your feedback on the mod's [forum topic](). Most pull requests will be accepted after review. 

# TODO
In order of importance.

* Actually handle the static setting when attaching skill sets.

* Create formspec for viewing skills.

* Better handling of old skill sets when:
    * Players never log in again or haven't logged in for a very long time.
    * Skills have been added or removed from the lua code.
        * If skills are removed consider removing them from skill sets. When implemented this should to be optional(opt-in probebly).

* Think about implementing multiple skill systems (like originally intended) in a clean way or just making each skill system a separate mod. 
