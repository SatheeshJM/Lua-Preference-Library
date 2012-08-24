local preference = require "preference"
 
--Store numbers
preference.save{a=1}
value = preference.getValue("a")
print("Retrieving number : ",value)
 
--Store strings
preference.save{b="1"}
value = preference.getValue("b")
print("Retrieving string : ",value)
 
--Store Boolean
preference.save{c=true}
value = preference.getValue("c")
print("Retrieving boolean : ",value)
 
--Store Tables
preference.save{d = {1,"2",true}}
value = preference.getValue("d")
print("Retrieving table : ",value)