-- =====================================================
-- 03. INSERT DATA
-- Sample data is "as of" 2026-11-15
-- IMPORTANT: Run 01_create_database.sql and 02_create_tables.sql first.
-- Run this file ONCE on the freshly created database. Do not rerun it
-- without dropping/recreating the database, or AUTO_INCREMENT IDs will differ.
-- =====================================================
USE smart_hospital_db;

INSERT INTO departments (dept_name, floor_no) VALUES
('Cardiology', 2), ('Orthopedics', 3), ('General Medicine', 1),
('Pediatrics', 1), ('Critical Care', 4);

INSERT INTO doctors (doctor_name, dept_id, specialization, consultation_fee, shift) VALUES
('Dr. Ramesh Naidu',  1, 'Cardiologist',       800.00, 'MORNING'),
('Dr. Sunitha Reddy', 2, 'Orthopedic Surgeon', 700.00, 'MORNING'),
('Dr. Anil Verma',    3, 'General Physician',  400.00, 'MORNING'),
('Dr. Kavya Menon',   4, 'Pediatrician',       500.00, 'EVENING'),
('Dr. Prakash Rao',   3, 'General Physician',  400.00, 'EVENING'),
('Dr. Neha Kapoor',   5, 'Intensivist',       1000.00, 'NIGHT'),
('Dr. Vikram Shah',   1, 'Cardiologist',       800.00, 'EVENING');

INSERT INTO patients (full_name, gender, dob, city, phone) VALUES
('Ravi Teja',     'M', '1985-04-12', 'Hyderabad',    '9866600001'),
('Sita Devi',     'F', '1992-09-30', 'Hyderabad',    '9866600002'),
('Baby Aarav',    'M', '2022-06-15', 'Secunderabad', '9866600003'),
('Mohammed Ali',  'M', '1958-01-25', 'Hyderabad',    '9866600004'),
('Lavanya',       'F', '2000-12-05', 'Warangal',     '9866600005'),
('Kiran Kumar',   'M', '1975-03-08', 'Hyderabad',    '9866600006'),
('Anitha Rao',    'F', '1968-07-19', 'Karimnagar',   '9866600007'),
('Rohan Gupta',   'M', '2010-11-02', 'Hyderabad',    '9866600008'),
('Fatima Begum',  'F', '1950-05-30', 'Hyderabad',    '9866600009'),
('Suresh Babu',   'M', '1989-08-14', 'Hyderabad',    '9866600010');

INSERT INTO beds (dept_id, bed_type, daily_charge, status) VALUES
(1, 'GENERAL', 1500.00, 'AVAILABLE'),    -- 1
(1, 'GENERAL', 1500.00, 'OCCUPIED'),     -- 2
(1, 'PRIVATE', 3500.00, 'OCCUPIED'),     -- 3
(2, 'GENERAL', 1500.00, 'AVAILABLE'),    -- 4
(2, 'PRIVATE', 3500.00, 'MAINTENANCE'),  -- 5
(3, 'GENERAL', 1200.00, 'AVAILABLE'),    -- 6
(3, 'GENERAL', 1200.00, 'OCCUPIED'),     -- 7
(3, 'GENERAL', 1200.00, 'AVAILABLE'),    -- 8
(4, 'GENERAL', 1300.00, 'AVAILABLE'),    -- 9
(4, 'PRIVATE', 3000.00, 'AVAILABLE'),    -- 10
(5, 'ICU',     6000.00, 'OCCUPIED'),     -- 11
(5, 'ICU',     6000.00, 'AVAILABLE');    -- 12

INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, status) VALUES
(1,  1, '2026-11-02', '10:00:00', 'COMPLETED'),
(2,  3, '2026-11-02', '10:30:00', 'COMPLETED'),
(3,  4, '2026-11-02', '17:00:00', 'COMPLETED'),
(5,  3, '2026-11-03', '10:15:00', 'COMPLETED'),
(10, 5, '2026-11-03', '18:00:00', 'COMPLETED'),
(6,  2, '2026-11-03', '11:00:00', 'COMPLETED'),
(2,  3, '2026-11-04', '10:45:00', 'NO_SHOW'),
(7,  3, '2026-11-04', '11:00:00', 'COMPLETED'),
(8,  4, '2026-11-05', '17:30:00', 'CANCELLED'),
(4,  1, '2026-11-05', '09:30:00', 'COMPLETED'),
(10, 7, '2026-11-06', '16:30:00', 'COMPLETED'),
(5,  3, '2026-11-09', '10:00:00', 'COMPLETED'),
(1,  1, '2026-11-09', '10:30:00', 'COMPLETED'),
(9,  3, '2026-11-16', '10:00:00', 'SCHEDULED'),
(3,  4, '2026-11-17', '17:00:00', 'SCHEDULED');

INSERT INTO admissions (patient_id, doctor_id, bed_id, admit_date, discharge_date, diagnosis, treatment_charges, status) VALUES
(4, 1, 1,  '2026-10-01', '2026-10-06', 'Heart failure',          22000.00, 'DISCHARGED'),
(6, 2, 4,  '2026-10-05', '2026-10-12', 'Knee replacement',       85000.00, 'DISCHARGED'),
(9, 6, 11, '2026-10-08', '2026-10-15', 'Pneumonia (critical)',   60000.00, 'DISCHARGED'),
(3, 4, 9,  '2026-10-15', '2026-10-18', 'Viral fever',             4500.00, 'DISCHARGED'),
(7, 3, 6,  '2026-10-20', '2026-10-24', 'Diabetes complications',  9000.00, 'DISCHARGED'),
(4, 1, 2,  '2026-11-05', NULL,         'Chest pain',                 0.00, 'ADMITTED'),
(1, 7, 3,  '2026-11-10', NULL,         'Cardiac arrhythmia',         0.00, 'ADMITTED'),
(9, 6, 11, '2026-11-12', NULL,         'Sepsis',                     0.00, 'ADMITTED'),
(8, 5, 7,  '2026-11-13', NULL,         'Dengue',                     0.00, 'ADMITTED');

-- Verify the five admission IDs used by the IPD bills exist before inserting bills.
SELECT admission_id, patient_id
FROM admissions
WHERE admission_id BETWEEN 1 AND 5
ORDER BY admission_id;

-- OPD bills = doctor fee.  IPD bills = days x bed charge + treatment charges
INSERT INTO bills (patient_id, appointment_id, admission_id, amount, payment_status, bill_date) VALUES
(1,  1,    NULL,   800.00, 'PAID',    '2026-11-02'),
(2,  2,    NULL,   400.00, 'PAID',    '2026-11-02'),
(3,  3,    NULL,   500.00, 'PAID',    '2026-11-02'),
(5,  4,    NULL,   400.00, 'PAID',    '2026-11-03'),
(10, 5,    NULL,   400.00, 'PAID',    '2026-11-03'),
(6,  6,    NULL,   700.00, 'PAID',    '2026-11-03'),
(7,  8,    NULL,   400.00, 'PENDING', '2026-11-04'),
(4,  10,   NULL,   800.00, 'PAID',    '2026-11-05'),
(10, 11,   NULL,   800.00, 'PAID',    '2026-11-06'),
(5,  12,   NULL,   400.00, 'PAID',    '2026-11-09'),
(1,  13,   NULL,   800.00, 'PAID',    '2026-11-09'),
(4,  NULL, 1,    29500.00, 'PAID',    '2026-10-06'),
(6,  NULL, 2,    95500.00, 'PAID',    '2026-10-12'),
(9,  NULL, 3,   102000.00, 'PENDING', '2026-10-15'),
(3,  NULL, 4,     8400.00, 'PAID',    '2026-10-18'),
(7,  NULL, 5,    13800.00, 'PENDING', '2026-10-24');

-- =====================================================
-- NEW TABLES DATA
-- (stock_quantity is the current stock after the sample prescriptions)
-- =====================================================
INSERT INTO medicines (medicine_name, category, unit_price, stock_quantity, expiry_date) VALUES
('Paracetamol 500mg',   'Analgesic',    2.50, 500, '2027-08-31'),
('Amoxicillin 500mg',   'Antibiotic',  12.00, 200, '2027-03-31'),
('Atorvastatin 10mg',   'Cardiac',      8.00, 300, '2027-06-30'),
('Aspirin 75mg',        'Cardiac',      1.50, 400, '2027-05-31'),
('Metformin 500mg',     'Antidiabetic', 3.00,  25, '2027-01-31'),   -- low stock
('Diclofenac 50mg',     'Analgesic',    4.00, 150, '2026-12-10'),   -- expiring soon
('Cough Syrup 100ml',   'Respiratory', 65.00,  40, '2026-11-30'),   -- expiring soon
('ORS Sachet',          'Rehydration', 15.00,  12, '2027-02-28'),   -- low stock
('Pantoprazole 40mg',   'Gastro',       6.50, 180, '2026-11-10'),   -- expired
('Calcium 500mg',       'Supplement',   5.00, 220, '2027-09-30');

INSERT INTO prescriptions (patient_id, doctor_id, medicine_id, quantity, prescription_date) VALUES
(1,  1, 4,  30, '2026-11-02'),
(1,  1, 3,  30, '2026-11-02'),
(2,  3, 1,  15, '2026-11-02'),
(3,  4, 7,   1, '2026-11-02'),
(5,  3, 1,  10, '2026-11-03'),
(10, 5, 9,  14, '2026-11-03'),
(6,  2, 6,  14, '2026-11-03'),
(6,  2, 10, 30, '2026-11-03'),
(7,  3, 5,  60, '2026-11-04'),
(4,  1, 4,  30, '2026-11-05'),
(10, 7, 3,  30, '2026-11-06'),
(5,  3, 2,  15, '2026-11-09'),
(1,  1, 3,  30, '2026-11-09'),
(1,  7, 4,  30, '2026-11-10'),
(9,  6, 2,  14, '2026-11-12'),
(8,  5, 8,  10, '2026-11-13');

-- Feedback only for COMPLETED appointments of the same patient
INSERT INTO patient_feedback (patient_id, appointment_id, rating, feedback_date) VALUES
(1,  1,  5, '2026-11-02'),
(2,  2,  4, '2026-11-02'),
(3,  3,  5, '2026-11-03'),
(5,  4,  3, '2026-11-03'),
(10, 5,  4, '2026-11-04'),
(6,  6,  5, '2026-11-04'),
(7,  8,  2, '2026-11-05'),
(4,  10, 4, '2026-11-06'),
(10, 11, 3, '2026-11-07'),
(5,  12, 4, '2026-11-10');
