CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

SELECT 
    query, 
    calls, 
    total_exec_time, 
    mean_exec_time, 
    rows, 
    (total_exec_time / sum(total_exec_time) OVER()) * 100 AS porcentaje_del_total
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 5;
