-- Tabla que referencia a otra en sus constrainst
select owner,constraint_name,constraint_type,table_name,r_owner,r_constraint_name
 from dba_constraints 
    where constraint_type='R'
    and r_constraint_name in (select constraint_name from dba_constraints 
    where constraint_type in ('P','U') and table_name=UPPER('Ptv_Version_Seq'));
