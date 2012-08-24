--[[
Save_And_Load Module
Author: Satheesh
Version: 1.1
License: MIT
Web: http:www.timeplusq.com


--Change Log 

1.1 
Fixed a minor bug where a subtable with numerical key raises an error.	
http://developer.coronalabs.com/code/save-data-files-tablesnumbersstringsboolean#comment-120973
 
 
 
 
 
FUNCTIONS
 
preference.save
preference.getValue
preference.getAllValues
preference.print
preference.printAll
 
 
 
USAGE AND EXAMPLES
 
preference = require "preference"
 
 
preference.save{a=1}
value = preference.getValue("a")
 
preference.save{b="1"}
value = preference.getValue("b")
 
preference.save{c=true}
value = preference.getValue("c")
 
preference.save{d       =       {1,"2",true}}
value = preference.getValue("d")
 
 
--]]
 
 
 
 
local preference = {}
 
 
--Localise
local system = system
local type = type
local tonumber = tonumber
local pairs = pairs 
local print = print 
local pairs = pairs 
local io = io
 
--constants
local separator = "||__||"
local elementSeparator = "!!!"
 
 
 
 
 
 
local function saveFile( fileName, fileData )
        --Path for file
        local path = system.pathForFile( fileName, system.DocumentsDirectory )
        local file = io.open( path, "w" )
        
        if file then
           file:write( fileData )
           io.close( file )
        end
end
 
 
local function loadFile( fileName )
        local path = system.pathForFile( fileName, system.DocumentsDirectory )
        local file = io.open( path, "r" )
 
        if file then
           local fileData = file:read( "*a" )
           io.close( file )
           return fileData
        else
           return false
        end
end
 
 
 
 
 
 
local function formatValueForStoring(value,params)
        params = params or {}
        
        
        local elementIsInsideATable = params.elementIsInsideATable
        local separator = elementIsInsideATable and  elementSeparator or separator
        
        
        
        
        local dataType = type(value)
        local value2
        if dataType == "number" then            
                value2 = value..separator.."n"
                
        elseif dataType == "string" then 
                value2 = value..separator.."s"
                
        elseif dataType == "boolean" then 
                value2 = (value and 1 or 0)..separator.."b"     
                
        elseif dataType == "table" then
                value2 = convertTableToString(value)
                
        else 
                value2 = dataType.."_cannot_be_stored "..separator.."s"
                dataType = "string"
        end
        
        if elementIsInsideATable then 
                local index = params.index
                value2 = index..separator..value2       --tab["1"]
 
                if type(index) == "number" then 
                        local endd = value2:sub(-1,-1)
                        local start = value2:sub(1,-2)                          --tab[1]  if index is number append a n as penultimate character
                        local mid = "n"
                        value2 = start..mid..endd
                end
        end
        
        return value2
end
 
 
function convertTableToString(tab)
        local finalString = "<t>\n"
        for i,v in pairs(tab) do 
                local value2 = formatValueForStoring(v,{elementIsInsideATable = true,index = i})
                finalString = finalString..value2.."\n"
        end
        finalString = finalString.."<#t>"
        return finalString
end
 
 
 
local function saveModule(fileName,value)
 
        local allFiles = preference.__allFiles
        local allFilesAsString  = ""
        
        
        
        --store value in global
        preference.__allFiles[fileName] = value
        
        
        --Store value in file
        saveFile(fileName,formatValueForStoring(value))
        
        
        --Store filename in preference file
        for fileName,v in pairs(allFiles) do 
                allFilesAsString = allFilesAsString..fileName.."\n"
        end
        saveFile("preference.bin",allFilesAsString)
end
 
 
local function convertStringToTableElement(str)
        
        local index,value
        local separator = elementSeparator
        if str:find("<t>") then 
                local s,e       =       str:find(separator)
                index           =       str:sub(1,s-1)
                value = {}
        elseif str:find("<#t>") then 
                value = "eot"
				
		elseif str:find("<#tn>") then 
                value = "eot"
        else 
                local dataType = str:sub(-1,-1)
 
                
                local s,e       =       str:find(separator)
                index           =       str:sub(1,s-1)
        
                
                local s2,e2     =       str:find(separator,e+1)
                value           =       str:sub(e+1,s2-1)
        
 
                if              dataType == "n" then            
                        value = tonumber(value)
                elseif  dataType == "s" then 
                elseif  dataType == "b" then 
                        value = (tonumber(value) == 1)
                end
                
                
        end
        return index,value
end
 
 
local function convertStringToTable(str)
        local finalTable = {}
        
        local start = 5
        local endd = -5
        local tableData = str:sub(start,endd)
        
        local start = 1
        local tableHierarchy = 1
        local tableStart,tableEnd
        local tableIndex
 
 
        repeat
                local pos = tableData:find("\n",start);
                if pos then
                        local elementAsString = tableData:sub(start,pos-1)
                        local index,value = convertStringToTableElement(elementAsString)
 
                        if tableHierarchy == 1 then 
                                if elementAsString:sub(-2,-2)=="n" then         --Table index is a number
                                        index = tonumber(index)
                                end
                                finalTable[index] = value
                        end
                        
                        if type(value) == "table" then 
                                tableHierarchy = tableHierarchy + 1
                                if tableHierarchy == 2 then 
                                        tableStart = tableData:find("<t>",start)
                                        tableIndex = index
                                end
                        end
                        if value == "eot" then 
                                tableHierarchy = tableHierarchy - 1
                                if tableHierarchy == 1 then 
                                        tableEnd = pos-1
                                        local subTableString = tableData:sub(tableStart,tableEnd )
                                        local subTable =  convertStringToTable(subTableString)
										
										--index is a number and value is subtable
										if elementAsString:find("<#tn>") then
											finalTable[tableIndex] = nil
											tableIndex = tonumber(tableIndex)
										end 
										
                                        finalTable[tableIndex] = subTable
                                end
                        end
                        
                        start = pos+1
                end
        until(not pos)
                
        return finalTable
end
 
local function parse(fileData)
        local finalString
        if fileData:sub(1,3)=="<t>" then 
                finalString = convertStringToTable(fileData)
                -- dump(finalString)
        else 
                local dataType = fileData:sub(-1,-1)
                local index = fileData:find(separator)
                local value = fileData:sub(1,index-1)
 
                if              dataType == "n" then 
                        finalString = tonumber(value)
                elseif  dataType == "s" then 
                        finalString = value
                elseif  dataType == "b" then 
                        finalString = (tonumber(value) == 1)
                end
                
        end
        return finalString
end
 
 
local function loadModule(fileName)
        local finalString = parse(loadFile(fileName))
        return finalString
end
 
 
local function initialize()
        preference.__allFiles = {}
        local allFiles = preference.__allFiles 
        local allOptions = loadFile("preference.bin")
        if not allOptions then 
                saveFile("preference.bin","")
                allOptions = ""
        end
        
                local start = 1
                repeat
                        local pos = allOptions:find("\n",start);
                        if pos then
                                local option = allOptions:sub(start,pos-1)
                                allFiles[option] = true
                                start = pos+1
                        end
                until(not pos)
end
 
 
 
 
 
function preference.save(params)
 
        for fileName,value in pairs(params) do 
                saveModule(fileName,value)
        end
end
 
 
function preference.getValue(fileName)
        
        local value
        local allOptions = preference.__allFiles
        
        if allOptions[fileName] == true then 
                value = loadModule(fileName)
                allOptions[fileName]  = value
        else 
                value = allOptions[fileName]
        end
        
        return value
                
end
 
 
function preference.getAllValues()
        local allOptions = preference.__allFiles
        local finalTable = {}
        
        for fileName,value in pairs(allOptions) do 
                if value==true then 
                        value = loadModule(fileName)
                end
                finalTable[fileName] = value 
        end
        return finalTable
end
 
 
function preference.print(fileName)
        local value = loadModule(fileName)
        print(value)
end
 
 
function preference.printAll(fileName)
        local allOptions = preference.__allFiles
        for fileName,v in pairs(allOptions) do 
                local value = loadModule(fileName)
                print(fileName,value)
        end
end
 
 
 
initialize() 
return preference