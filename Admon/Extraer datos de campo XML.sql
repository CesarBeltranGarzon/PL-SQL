SELECT XMLTYPE(t.xml).EXTRACT('//OWNERS/OWNER/OWNERID/text()').getStringVal(), 
       XMLTYPE(t.xml).EXTRACT('//OWNERS/OWNER/QUANTITY/VALUE/text()').getStringVal(),
       t.*        
FROM bdpsiv.logmensajes t
where idmensaje LIKE '%38802-40845-77817-2015-10-18-GAS-38802-RECETOR - PAUTO%'
ORDER BY fecha desc
