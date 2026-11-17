-- =====================================================
-- 05. VIEWS
-- =====================================================
USE smart_hospital_db;

-- View 1: Bed occupancy and load status per department
--   load_status: HIGH LOAD (>= 60%) -> consider adding beds
--                NORMAL    (30-59%)
--                UNDER-USED (< 30%) -> beds can be shared
CREATE OR REPLACE VIEW vw_bed_occupancy AS
SELECT x.*,
       CASE
           WHEN x.occupancy_percent >= 60 THEN 'HIGH LOAD'
           WHEN x.occupancy_percent >= 30 THEN 'NORMAL'
           ELSE 'UNDER-USED'
       END AS load_status
FROM (
    SELECT d.dept_id, d.dept_name,
           COUNT(b.bed_id)                          AS total_beds,
           COALESCE(SUM(b.status = 'OCCUPIED'), 0)    AS occupied,
           COALESCE(SUM(b.status = 'AVAILABLE'), 0)   AS available,
           COALESCE(SUM(b.status = 'MAINTENANCE'), 0) AS maintenance,
           COALESCE(ROUND(SUM(b.status = 'OCCUPIED') * 100
                    / NULLIF(SUM(b.status <> 'MAINTENANCE'), 0), 1), 0) AS occupancy_percent
    FROM departments d
    LEFT JOIN beds b ON d.dept_id = b.dept_id
    GROUP BY d.dept_id, d.dept_name
) x;

-- View 2: Patients currently in hospital
CREATE OR REPLACE VIEW vw_current_inpatients AS
SELECT a.admission_id, p.full_name AS patient,
       TIMESTAMPDIFF(YEAR, p.dob, CURDATE()) AS age,
       dr.doctor_name, dp.dept_name AS department,
       a.bed_id, b.bed_type, a.admit_date,
       DATEDIFF(CURDATE(), a.admit_date) AS days_admitted,
       a.diagnosis
FROM admissions a
JOIN patients p     ON a.patient_id = p.patient_id
JOIN doctors dr     ON a.doctor_id = dr.doctor_id
JOIN departments dp ON dr.dept_id = dp.dept_id
JOIN beds b         ON a.bed_id = b.bed_id
WHERE a.status = 'ADMITTED';

-- View 3: Workload of every doctor
CREATE OR REPLACE VIEW vw_doctor_workload AS
SELECT d.doctor_id, d.doctor_name, dp.dept_name AS department, d.shift,
       (SELECT COUNT(*) FROM appointments a WHERE a.doctor_id = d.doctor_id AND a.status = 'COMPLETED') AS completed_visits,
       (SELECT COUNT(*) FROM appointments a WHERE a.doctor_id = d.doctor_id AND a.status = 'NO_SHOW')   AS no_shows,
       (SELECT COUNT(*) FROM appointments a WHERE a.doctor_id = d.doctor_id AND a.status = 'SCHEDULED') AS upcoming_visits,
       (SELECT COUNT(*) FROM admissions ad WHERE ad.doctor_id = d.doctor_id AND ad.status = 'ADMITTED') AS current_inpatients
FROM doctors d
JOIN departments dp ON d.dept_id = dp.dept_id;

-- View 4: Revenue of each department (OPD + IPD)
CREATE OR REPLACE VIEW vw_department_revenue AS
SELECT dp.dept_id, dp.dept_name,
       COALESCE(o.opd, 0) AS opd_revenue,
       COALESCE(i.ipd, 0) AS ipd_revenue,
       COALESCE(o.opd, 0) + COALESCE(i.ipd, 0) AS total_revenue
FROM departments dp
LEFT JOIN (
    SELECT dr.dept_id, SUM(b.amount) AS opd
    FROM bills b
    JOIN appointments a ON b.appointment_id = a.appointment_id
    JOIN doctors dr     ON a.doctor_id = dr.doctor_id
    GROUP BY dr.dept_id
) o ON o.dept_id = dp.dept_id
LEFT JOIN (
    SELECT dr.dept_id, SUM(b.amount) AS ipd
    FROM bills b
    JOIN admissions ad ON b.admission_id = ad.admission_id
    JOIN doctors dr    ON ad.doctor_id = dr.doctor_id
    GROUP BY dr.dept_id
) i ON i.dept_id = dp.dept_id;

-- View 5: Bills not yet paid
CREATE OR REPLACE VIEW vw_pending_bills AS
SELECT b.bill_id, p.full_name AS patient, p.phone,
       CASE WHEN b.appointment_id IS NOT NULL THEN 'OPD' ELSE 'IPD' END AS bill_type,
       b.amount, b.bill_date, DATEDIFF(CURDATE(), b.bill_date) AS days_pending
FROM bills b
JOIN patients p ON b.patient_id = p.patient_id
WHERE b.payment_status = 'PENDING';

-- =====================================================
-- NEW VIEWS: pharmacy and patient satisfaction
-- =====================================================

-- View 6: Medicine stock alerts
--   EXPIRED, LOW STOCK (< 30 units), EXPIRING SOON (within 30 days), OK
CREATE OR REPLACE VIEW vw_medicine_stock_alert AS
SELECT medicine_id, medicine_name, category, unit_price, stock_quantity, expiry_date,
       DATEDIFF(expiry_date, CURDATE()) AS days_to_expiry,
       CASE
           WHEN expiry_date < CURDATE()                     THEN 'EXPIRED'
           WHEN stock_quantity < 30                         THEN 'LOW STOCK'
           WHEN DATEDIFF(expiry_date, CURDATE()) <= 30      THEN 'EXPIRING SOON'
           ELSE 'OK'
       END AS stock_status
FROM medicines;

-- View 7: Every prescription with names and cost
CREATE OR REPLACE VIEW vw_prescription_details AS
SELECT pr.prescription_id, pr.prescription_date,
       p.full_name AS patient, d.doctor_name,
       m.medicine_name, m.category, pr.quantity, m.unit_price,
       pr.quantity * m.unit_price AS total_cost
FROM prescriptions pr
JOIN patients p  ON pr.patient_id = p.patient_id
JOIN doctors d   ON pr.doctor_id = d.doctor_id
JOIN medicines m ON pr.medicine_id = m.medicine_id;

-- View 8: Patient satisfaction of every doctor
CREATE OR REPLACE VIEW vw_doctor_feedback AS
SELECT d.doctor_id, d.doctor_name, dp.dept_name AS department,
       COUNT(f.feedback_id) AS feedback_count,
       COALESCE(ROUND(AVG(f.rating), 2), 0) AS avg_rating,
       CASE
           WHEN COUNT(f.feedback_id) = 0 THEN 'NO FEEDBACK'
           WHEN AVG(f.rating) >= 4.5     THEN 'EXCELLENT'
           WHEN AVG(f.rating) >= 4       THEN 'GOOD'
           WHEN AVG(f.rating) >= 3       THEN 'AVERAGE'
           ELSE 'NEEDS IMPROVEMENT'
       END AS satisfaction
FROM doctors d
JOIN departments dp ON d.dept_id = dp.dept_id
LEFT JOIN appointments a      ON a.doctor_id = d.doctor_id
LEFT JOIN patient_feedback f  ON f.appointment_id = a.appointment_id
GROUP BY d.doctor_id, d.doctor_name, dp.dept_name;

-- Usage:
-- SELECT * FROM vw_bed_occupancy;
-- SELECT * FROM vw_current_inpatients;
-- SELECT * FROM vw_doctor_workload;
-- SELECT * FROM vw_department_revenue;
-- SELECT * FROM vw_pending_bills;
-- SELECT * FROM vw_medicine_stock_alert;
-- SELECT * FROM vw_prescription_details;
-- SELECT * FROM vw_doctor_feedback;
