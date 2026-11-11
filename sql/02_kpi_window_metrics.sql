-- Query 1: CTE for On-Time Dispatch Rate (%) and Network Delays by Hub
WITH HubMetrics AS (
    SELECT 
        hub_name,
        COUNT(*) AS total_shipments,
        SUM(CASE WHEN dispatch_status = 'ON_TIME' THEN 1 ELSE 0 END) AS on_time_shipments,
        SUM(CASE WHEN dispatch_status = 'DELAYED' THEN 1 ELSE 0 END) AS delayed_shipments,
        AVG(delay_minutes) AS avg_delay_mins
    FROM parcel_shipments
    GROUP BY hub_name
)
SELECT 
    hub_name,
    total_shipments,
    on_time_shipments,
    delayed_shipments,
    ROUND(avg_delay_mins, 1) AS avg_delay_mins,
    ROUND((on_time_shipments * 100.0 / total_shipments), 2) AS on_time_dispatch_pct
FROM HubMetrics;

-- Query 2: Damaged Exceptions & Average Resolution Duration
SELECT 
    hub_name,
    exception_code,
    COUNT(*) AS total_damaged_parcels,
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,
    MAX(resolution_hours) AS max_resolution_hours
FROM parcel_shipments
WHERE exception_code LIKE 'DAMAGED%'
GROUP BY hub_name, exception_code;