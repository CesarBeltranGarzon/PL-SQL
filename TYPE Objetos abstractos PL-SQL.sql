/*
La cl�usula NOT INSTANTIABLE le permite declarar un objeto abstracto. No se puede usar un objeto abstracto 
como es; tendr� que crear un subtipo o ni�o tipo de dichos objetos para utilizar sus funcionalidades.

Por ejemplo,
*/

CREATE OR REPLACE TYPE rectangle AS OBJECT
(length number,
 width number,
 NOT INSTANTIABLE NOT FINAL MEMBER PROCEDURE display) 
 NOT INSTANTIABLE NOT FINAL;
 

