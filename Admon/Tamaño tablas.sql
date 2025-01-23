
SELECT segment_name AS "TABLE_NAME",
SUM (BYTES) AS "[Bytes]",
SUM (BYTES) / 1024 AS "[Kb]",
SUM (BYTES) / (1024*1024) AS "[Mb]",
SUM (BYTES) / (1024*1024*1024) AS "[Gb]"
FROM user_segments
WHERE segment_type = 'TABLE'
GROUP BY segment_name
ORDER BY 5 DESC;