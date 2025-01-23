select DISTINCT REGEXP_SUBSTR ('uno,dos,tres', '[^,]+', 1, level) as nombre
from dual
connect by level <= length(regexp_replace('uno,dos,tres','[^,]+'))+1 