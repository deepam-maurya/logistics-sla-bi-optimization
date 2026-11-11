DROP TABLE IF EXISTS parcel_shipments;

CREATE TABLE parcel_shipments (
    tracking_id VARCHAR(12) PRIMARY KEY,
    hub_name VARCHAR(20),
    carrier VARCHAR(20),
    scheduled_dispatch DATETIME,
    actual_dispatch DATETIME,
    dispatch_status VARCHAR(15), -- 'ON_TIME' or 'DELAYED'
    delay_minutes INT,
    exception_code VARCHAR(30),  -- NULL if clear, or specific error
    resolution_hours DECIMAL(4,1)
);

INSERT INTO parcel_shipments VALUES 
('TRK_DE_101', 'Berlin_Hub', 'DHL', '2026-10-26 10:00:00', '2026-10-26 09:55:00', 'ON_TIME', 0, NULL, 0.0),
('TRK_DE_102', 'Berlin_Hub', 'UPS', '2026-10-26 10:00:00', '2026-10-26 10:45:00', 'DELAYED', 45, 'DAMAGED_BARCODE', 1.5),
('TRK_DE_103', 'Berlin_Hub', 'DHL', '2026-10-26 11:00:00', '2026-10-26 11:05:00', 'ON_TIME', 5, NULL, 0.0),
('TRK_DE_104', 'Berlin_Hub', 'UPS', '2026-10-26 11:00:00', '2026-10-26 12:30:00', 'DELAYED', 90, 'DAMAGED_PACKAGING', 3.2),
('TRK_DE_105', 'Berlin_Hub', 'DPD', '2026-10-26 12:00:00', '2026-10-26 12:00:00', 'ON_TIME', 0, NULL, 0.0),
('TRK_DE_201', 'Munich_Hub', 'DHL', '2026-10-26 09:00:00', '2026-10-26 09:10:00', 'ON_TIME', 10, NULL, 0.0),
('TRK_DE_202', 'Munich_Hub', 'UPS', '2026-10-26 10:00:00', '2026-10-26 11:20:00', 'DELAYED', 80, 'DAMAGED_LABEL', 2.0),
('TRK_DE_203', 'Munich_Hub', 'DPD', '2026-10-26 10:30:00', '2026-10-26 10:30:00', 'ON_TIME', 0, NULL, 0.0),
('TRK_DE_204', 'Munich_Hub', 'DHL', '2026-10-26 11:00:00', '2026-10-26 11:50:00', 'DELAYED', 50, 'CUSTOMS_HOLD', 4.5),
('TRK_DE_205', 'Munich_Hub', 'UPS', '2026-10-26 12:00:00', '2026-10-26 12:05:00', 'ON_TIME', 5, NULL, 0.0);