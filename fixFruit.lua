---------------------------------------------------------------------------------------------------------
-- FIXFRUIT SCRIPT
---------------------------------------------------------------------------------------------------------
-- Purpose: To adjust fruit properties.  
-- Authors:  Akuenzi, theSeb
--

FixFruit = {};

--do not use print. use self:debugPrint() instead, unless we want the message to be displayed in a release version
FixFruit.debugLevel = 1 -- 0 if you don't want to see debugging messages in the log file / console. 1 to switch on debug statements

--TODO: these values should probably be added into the fixFruitData table in the future, but won't bother until the animation from the back of the harvester issue is fixed
FixFruit.rapeWindrowLiterPerSqm = 4; -- based on the assumption that OSR produces about 0.5 of wheat which is 7 in the game and then rounded up. Not sure if this value can be a float so rounded up
FixFruit.soybeanWindrowLiterPerSqm = 3; -- based on the assumption that soybean produces slightly less straw than OSR
FixFruit.barleyWindrowLiterPerSqm = 6; -- based on the assumption that winter barley produces about 0.8 of winter wheat which is 7 in the game and then rounded up. Not sure if this value can be a float so rounded up
FixFruit.springBarleyWindrowLiterPerSqm = 5; -- based on the assumption that spring barley will produce a bit less straw than winter barley. TODO:implement spring barley with shorter growth cycles
FixFruit.springWheatWindrowLiterPerSqm = 6; -- based on the assumption that spring wheat will produce a bit less straw than winter wheat. TODO:implement spring wheat with shorter growth cycles


-- error messages
FixFruit.MSG_ERROR_WHEAT_WINDROW_NOT_FOUND = "Wheat windrow index could not be found. Additional swaths will not be installed."


--[[NOTE:   FixFruitStuff is a table bound by {}.  Within this table are additional tables, separated by a comma, for each fruit.
    Additional fruits may be added as shown by following the examples below, so long as each additional table added is separated by comma.
   The game table variables to change for each fruit are shown in each respective fruit table.]]
   
-- local FixFruitStuff =   {
--         {"sugarBeet", 1},
--         {"barley", 1},
--         {"wheat", 1},
--         {"rape", 1},
--         {"sunflower", 1},
--         {"maize", 1},
--         {"oilseedRadish", 1},
--         {"poplar", 1},
--         {"grass", 1},
--         {"dryGrass", 1},
--         {"potato", 1},
--         {"soybean", 1},
--                         }

function FixFruit:loadMap(name) 

    --Seb: changed variable name and appropriate camel case. variables should start with lower case letter. Changed all to 2 hours for the moment for easier debugging when checking if things are working
    local fixFruitData = {
   {"sugarBeet",   growthStateTime=2, minHarvestingGrowthState=9,  minForageGrowthState=9},
   {"barley",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=3},
   {"wheat",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=3},
   {"rape",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=4},
   {"sunflower",   growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=4},
   {"maize",    growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=3},
   {"oilseedRadish",  growthStateTime=2,  minHarvestingGrowthState=2,  minForageGrowthState=2},
   {"poplar",    growthStateTime=2,  minHarvestingGrowthState=4,  minForageGrowthState=4},
   {"grass",    growthStateTime=2,  minHarvestingGrowthState=2,  minForageGrowthState=2},
   {"dryGrass",   growthStateTime=2,  minHarvestingGrowthState=2,  minForageGrowthState=2},
   {"potato",    growthStateTime=2, minHarvestingGrowthState=9,  minForageGrowthState=9},
   {"soybean",   growthStateTime=2, minHarvestingGrowthState=4,  minForageGrowthState=4},
     }

    -- To update FruitUtil tables for changes to fruit growth state times.
    self:debugPrint("Starting to change growth")
    
    for _, fruitType in pairs(fixFruitData) do
        self:FixFruitTimes(fruitType[1], fruitType["growthStateTime"])
    end;
 
    self:debugPrint("Changed growth")

    -- Seb:commeting this out for now until I understand the intentions for FixFruitData
    -- To update FruitUtil tables for changes to minHarvesting and minForage allowed growth states.
    
    --  for _, elem in pairs(fixFruitData) do
    --   local fruitName = "FRUITTYPE_" .. string.upper(elem[1])
    --   local fruitNumber = FruitUtil[fruitName]
    --   ModifyFruitData(elem[1], fruitNumber, elem["minHarvestingGrowthState"], "minHarvestingGrowthState")
    --   ModifyFruitData(elem[1], fruitNumber, elem["minForageGrowthState"], "minForageGrowthState")
    --  end;
    --end of new commented out code

    -- add straw to OSR and soybean
    self:AddStrawSwathsToRapeAndSoybean();

    --modify straw output for barley (winter barley)
    self:ModifyStrawSwathOutputForFruit(FruitUtil.fruitTypes["barley"].name,self.barleyWindrowLiterPerSqm)
    --is this a better (safer) way to access a fruitype name? TODO: come back to this in the future. leave commented out now
    --self:debugPrint("checking something: " .. FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_BARLEY].name);
        
end;

function FixFruit:deleteMap() 
end

function FixFruit:mouseEvent(posX, posY, isDown, isUp, button)
end;

function FixFruit:keyEvent(unicode, sym, modifier, isDown)
    --this is to help with debugging. Pressing K will print the tables below to the log file / console. 
    if (unicode == 107) then
        print_r(FruitUtil.fruitTypeGrowths); 
        print_r(FruitUtil.fruitTypes);
        --print_r(HelperUtil); just checking out this table to see if there was a way to reduce worker wages through it
        --print_r(FruitUtil);
    end;
end;

function FixFruit:update(dt)
end;

function FixFruit:draw() 
end;

-- Seb:I have modified this to be a member of the FixFruit class hence FixFruit: in front. To call self:FixFruitTimes(). global functions are bad. not that it makes a huge difference in FS, but hey ho, let's stick to good practices. 
function FixFruit:FixFruitTimes(fruitTypeName, fruitTime)
    
      
    -- Test to ensure fruit exists, and that growth time is not less than or equal to zero.
    
    if FruitUtil.fruitTypeGrowths[fruitTypeName] == nil or fruitTime <=0 then
        return;
    end;
 
    local newTime = fruitTime * 60 * 60 * 1000 -- To convert from hours to milliseconds
        FruitUtil.fruitTypeGrowths[fruitTypeName]["growthStateTime"] = newTime
         self:debugPrint("FruitGrowthStateTime changed for ".. fruitTypeName .. " to " .. newTime); --changed , to .. as it does not include a new line so it's easier to read in the log
end;

    --Seb: Commenting this entire function out since I am not sure what the intention is here currently. 
    --Is there an else missing after return?
    
    -- function ModifyFruitData(fruitName, fruitNumber, fruitData, fruitAttribute)
    -- -- Test to ensure fruit exists, and that state changes are (somewhat) valid.
    --     if FruitUtil.fruitIndexToDesc[fruitNumber] == nil or -- Does the fruit exist?
    -- (fruitData < 1 or fruitData > FruitUtil.fruitTypeGrowths[fruitName]["numGrowthStates"]) then -- Is changed state 0 or less, or greater than the number of total fruit states?
  
    --     return;
    -- end;

    -- FruitUtil.fruitIndexToDesc[fruitNumber][fruitAttribute] = fruitData
    -- -- self:debugPrint("Fruit Attribute Changed: ", fruitAttribute, ", Hours: ", fruitData)
    --     end;
    -- end;

--trying to get info out of updateables but not very successfully so commented out for now
-- function printMinFieldTable()
--     local updateables = g_currentMission.updateables
--     local continue = true
--     for k, v in pairs(updateables) do
--         if type(k) == "table" and continue == true then
--             if k["minFieldGrowthStateTime"] ~= nil then
--                 --print(k["minFieldGrowthStateTime"]);
--             end;
--         end;
--     end;
-- end;

--experimenting with adding a swath to rape and soybean
--TODO: modify function to add swaths to any crop. 
function FixFruit:AddStrawSwathsToRapeAndSoybean()
    
    --self:debugPrint("Looking up WIndrow fill type 30 expected. Actual: " .. FruitUtil.fruitTypeToWindrowFillType[FruitUtil.fruitTypes["wheat"].index]);

    --first we look up the windrow type for wheat
    local wheatWindrowFillType = FruitUtil.fruitTypeToWindrowFillType[FruitUtil.FRUITTYPE_WHEAT]
    self:debugPrint("Looking up windrow fill type 30 expected. Actual: " .. wheatWindrowFillType);
    --BUG: This adds straw, but animation of the straw coming out from the back of the combine is missing. The straw swaths appear on the ground. Is this as simple as the fact that there is no appropriate texture/particle emitter for this in the game?
    if wheatWindrowFillType ~= nil then 
        --rape first
        -- old code FruitUtil.setFruitTypeWindrow(FruitUtil.fruitTypes["rape"].index,wheatWindrowFillType,self.rapeWindrowLiterPerSqm);
        FruitUtil.setFruitTypeWindrow(FruitUtil.FRUITTYPE_RAPE,wheatWindrowFillType,self.rapeWindrowLiterPerSqm);
        --Seb: not entirely sure if this is required or not, but I've noticed that barley uses wheat's straw type and it does have a forage conversion in a dump of FruitUtil.fruitTypes  
        --FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.fruitTypes["rape"].index,FruitUtil.fruitTypes["wheat"].index);
        FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.FRUITTYPE_RAPE,FruitUtil.FRUITTYPE_WHEAT);

        --now soybean
        FruitUtil.setFruitTypeWindrow(FruitUtil.FRUITTYPE_SOYBEAN,wheatWindrowFillType,self.soybeanWindrowLiterPerSqm);
        --Seb: not entirely sure if this is required or not, but I've noticed that barley uses wheat's straw type and it does have a forage conversion in a dump of FruitUtil.fruitTypes  
        FruitUtil.registerFruitTypeWindrowForageWagonConversion(FruitUtil.FRUITTYPE_SOYBEAN,FruitUtil.FRUITTYPE_WHEAT);
        self:debugPrint("Done adding swaths");
    else
        self:errorPrint(self.MSG_ERROR_WHEAT_WINDROW_NOT_FOUND);
    end;
    
end;

function FixFruit:ModifyStrawSwathOutputForFruit(fruitTypeName,newSwathOutput)
    
    if FruitUtil.fruitTypes[fruitTypeName].windrowLiterPerSqm ~= nil then
        self:debugPrint(fruitTypeName .. "'s old swath value:  " .. FruitUtil.fruitTypes[fruitTypeName].windrowLiterPerSqm);
        FruitUtil.fruitTypes[fruitTypeName].windrowLiterPerSqm = newSwathOutput;
        self:debugPrint(fruitTypeName .. "'s swath value changed to: " .. newSwathOutput);
    else
        self:debugPrint("Trying to modify swath for a fruit that does not have a swath:" .. fruitTypeName);
    end;
end;

function FixFruit:debugPrint(message)
    if self.debugLevel == 1 then
        print(message)
    end;
end;


--use to show errors in the log file. These are there to inform the user of issues, so will stay in a release version
function FixFruit:errorPrint(message)
    print("--------");
    print("Seasons Mod error");
    print(messsage);
    print("--------");
end;

--debug print table function. will be removed later
function print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end;

addModEventListener(FixFruit);