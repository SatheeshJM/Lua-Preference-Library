local preference = require "preference"


preference.save{a=1}
value = preference.getValue("a")
 
preference.save{b="1"}
value = preference.getValue("b")
 
preference.save{c=true}
value = preference.getValue("c")
 
preference.save{d = {1,"2",true}}
value = preference.getValue("d")