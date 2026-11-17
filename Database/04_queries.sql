-- =====================================================
-- 04. QUERIES  (analytics + resource optimization)
-- Run AFTER files 05, 06 and 07. Some queries use today's date.
-- =====================================================
USE smart_hospital_db;

-- ---------- RESOURCE OPTIMIZATION ----------

-- Q1. Bed occupancy by department and which departments need more beds
SELECT dept_name, total_beds, occupied, available, maintenance, occupancy_percent, load_status
FROM vw_bed_occupancy
ORDER BY occupancy_percent DESC;

-- Q2. Currently admitted patients
SELECT * FROM vw_current_inpatients ORDER BY days_admitted DESC;

-- Q3. Free beds ready to use right now
SELECT b.bed_id, d.dept_name, b.bed_type, b.daily_charge
FROM beds b
JOIN departments d ON b.dept_id = d.dept_id
WHERE b.status = 'AVAILABLE'
ORDER BY d.dept_name, b.bed_type;

-- Q4. Bed utilization by bed type (GENERAL / PRIVATE / ICU)
SELECT bed_type, COUNT(*) AS total_beds,
       SUM(status = 'OCCUPIED') AS occupied,
       ROUND(SUM(status = 'OCCUPIED') * 100 / NULLIF(SUM(status <> 'MAINTENANCE'), 0), 1) AS occupancy_percent
FROM beds
GROUP BY bed_type;

-- Q5. Average length of stay per department (discharged patients)
SELECT dp.dept_name, COUNT(*) AS discharged_patients,
       ROUND(AVG(DATEDIFF(a.discharge_date, a.admit_date)), 1) AS avg_stay_days
FROM admissions a
JOIN doctors d       ON a.doctor_id = d.doctor_id
JOIN departments dp  ON d.dept_id = dp.dept_id
WHERE a.status = 'DISCHARGED'
GROUP BY dp.dept_name
ORDER BY avg_stay_days DESC;

-- Q6. Doctor workload ranking (RANK window function)
SELECT doctor_name, department, shift, completed_visits, current_inpatients,
       RANK() OVER (ORDER BY completed_visits DESC) AS workload_rank
FROM vw_doctor_workload;

-- Q7. Peak OPD hours - when to keep more doctors available
SELECT HOUR(appointment_time) AS hour_of_day, COUNT(*) AS appointments
FROM appointments
WHERE status IN ('COMPLETED', 'NO_SHOW')
GROUP BY HOUR(appointment_time)
ORDER BY appointments DESC;

-- Q8. No-show rate (wasted doctor time)
SELECT COUNT(*) AS finished_appointments,
       SUM(status = 'NO_SHOW') AS no_shows,
       ROUND(SUM(status = 'NO_SHOW') * 100.0 / NULLIF(COUNT(*), 0), 1) AS no_show_percent
FROM appointments
WHERE status IN ('COMPLETED', 'NO_SHOW');

-- ---------- PATIENT ANALYTICS ----------

-- Q9. 30-day readmissions (CTE + LAG window function)
WITH discharged AS (
    SELECT patient_id, admit_date, discharge_date
    FROM admissions
    WHERE discharge_date IS NOT NULL
),
ordered AS (
    SELECT patient_id, admit_date,
           LAG(discharge_date) OVER (
               PARTITION BY patient_id ORDER BY admit_date
           ) AS previous_discharge
    FROM discharged
)
SELECT p.full_name, o.previous_discharge, o.admit_date,
       DATEDIFF(o.admit_date, o.previous_discharge) AS days_between
FROM ordered o
JOIN patients p ON o.patient_id = p.patient_id
WHERE o.previous_discharge IS NOT NULL
  AND DATEDIFF(o.admit_date, o.previous_discharge) BETWEEN 0 AND 30;

-- Q10. Patient risk level (uses functions)
SELECT full_name, fn_patient_age(patient_id) AS age, fn_patient_risk(patient_id) AS risk_level
FROM patients
ORDER BY FIELD(fn_patient_risk(patient_id), 'HIGH', 'MEDIUM', 'LOW'), age DESC;

-- Q11. Most common diagnoses
SELECT diagnosis, COUNT(*) AS cases FROM admissions GROUP BY diagnosis ORDER BY cases DESC;

-- Q12. Patients by age group
SELECT CASE
           WHEN fn_patient_age(patient_id) < 13 THEN 'Child (0-12)'
           WHEN fn_patient_age(patient_id) < 18 THEN 'Teen (13-17)'
           WHEN fn_patient_age(patient_id) < 60 THEN 'Adult (18-59)'
           ELSE 'Senior (60+)'
       END AS age_group,
       COUNT(*) AS patients
FROM patients
GROUP BY age_group;

-- ---------- REVENUE ANALYTICS ----------

-- Q13. Revenue by department (OPD + IPD)
SELECT * FROM vw_department_revenue ORDER BY total_revenue DESC;

-- Q14. OPD vs IPD billing
SELECT CASE WHEN appointment_id IS NOT NULL THEN 'OPD' ELSE 'IPD' END AS bill_type,
       COUNT(*) AS bills, SUM(amount) AS total_amount
FROM bills
GROUP BY bill_type;

-- Q15. Monthly collected revenue with growth (CTE + LAG)
WITH monthly AS (
    SELECT DATE_FORMAT(bill_date, '%Y-%m') AS ym,
           SUM(amount) AS revenue
    FROM bills
    WHERE payment_status = 'PAID'
    GROUP BY DATE_FORMAT(bill_date, '%Y-%m')
),
growth AS (
    SELECT ym, revenue,
           LAG(revenue) OVER (ORDER BY ym) AS previous_month
    FROM monthly
)
SELECT ym AS month, revenue, previous_month,
       ROUND(
           (revenue - previous_month) * 100.0 /
           NULLIF(previous_month, 0), 2
       ) AS growth_percent
FROM growth
ORDER BY ym;

-- Q16. Money stuck in pending bills
SELECT * FROM vw_pending_bills ORDER BY amount DESC;

-- =====================================================
-- NEW: PHARMACY ANALYTICS (medicines, prescriptions)
-- =====================================================

-- Q17. Medicine stock alerts: expired, low stock, expiring within 30 days
SELECT medicine_name, category, stock_quantity, expiry_date, days_to_expiry, stock_status
FROM vw_medicine_stock_alert
WHERE stock_status <> 'OK'
ORDER BY FIELD(stock_status, 'EXPIRED', 'LOW STOCK', 'EXPIRING SOON'), days_to_expiry;

-- Q18. Most prescribed medicines (units and value)
SELECT m.medicine_name, SUM(pr.quantity) AS units_prescribed,
       SUM(pr.quantity * m.unit_price) AS total_value
FROM prescriptions pr
JOIN medicines m ON pr.medicine_id = m.medicine_id
GROUP BY m.medicine_id, m.medicine_name
ORDER BY units_prescribed DESC;

-- Q19. Prescription value by medicine category (not actual pharmacy sales)
SELECT m.category, SUM(pr.quantity) AS units, SUM(pr.quantity * m.unit_price) AS prescription_value
FROM prescriptions pr
JOIN medicines m ON pr.medicine_id = m.medicine_id
GROUP BY m.category
ORDER BY prescription_value DESC;

-- Q20. Full prescription history of one patient with cost (uses function)
SELECT prescription_date, doctor_name, medicine_name, quantity,
       fn_prescription_cost(prescription_id) AS cost
FROM vw_prescription_details
WHERE patient = 'Ravi Teja'
ORDER BY prescription_date;

-- Q21. Which doctors prescribe the most?
SELECT d.doctor_name, COUNT(*) AS prescriptions, SUM(pr.quantity) AS total_units
FROM prescriptions pr
JOIN doctors d ON pr.doctor_id = d.doctor_id
GROUP BY d.doctor_id, d.doctor_name
ORDER BY prescriptions DESC;

-- Q22. Medicine spend per patient (window function: share of total)
SELECT p.full_name,
       SUM(pr.quantity * m.unit_price) AS medicine_spend,
       ROUND(SUM(pr.quantity * m.unit_price) * 100 / SUM(SUM(pr.quantity * m.unit_price)) OVER (), 1) AS share_percent
FROM prescriptions pr
JOIN medicines m ON pr.medicine_id = m.medicine_id
JOIN patients p  ON pr.patient_id = p.patient_id
GROUP BY p.patient_id, p.full_name
ORDER BY medicine_spend DESC;

-- =====================================================
-- NEW: PATIENT SATISFACTION ANALYTICS (patient_feedback)
-- =====================================================

-- Q23. Overall satisfaction: average rating and % of happy patients (4 or 5 stars)
SELECT COUNT(*) AS feedbacks,
       ROUND(AVG(rating), 2) AS average_rating,
       ROUND(SUM(rating >= 4) * 100.0 / NULLIF(COUNT(*), 0), 1) AS happy_percent
FROM patient_feedback;

-- Q24. Rating distribution
SELECT rating, COUNT(*) AS patients, REPEAT('*', rating) AS stars
FROM patient_feedback
GROUP BY rating
ORDER BY rating DESC;

-- Q25. Doctor satisfaction ranking (RANK window function)
SELECT doctor_name, department, feedback_count, avg_rating, satisfaction,
       RANK() OVER (ORDER BY avg_rating DESC) AS rating_rank
FROM vw_doctor_feedback
WHERE feedback_count > 0;

-- Q26. Satisfaction by department
SELECT dp.dept_name, COUNT(*) AS feedbacks, ROUND(AVG(f.rating), 2) AS avg_rating
FROM patient_feedback f
JOIN appointments a ON f.appointment_id = a.appointment_id
JOIN doctors d      ON a.doctor_id = d.doctor_id
JOIN departments dp ON d.dept_id = dp.dept_id
GROUP BY dp.dept_name
ORDER BY avg_rating DESC;

-- Q27. Workload vs satisfaction: busy doctors with low ratings need attention
SELECT w.doctor_name, w.department, w.completed_visits, f.avg_rating, f.satisfaction
FROM vw_doctor_workload w
JOIN vw_doctor_feedback f ON w.doctor_id = f.doctor_id
WHERE w.completed_visits >= 3 AND f.avg_rating < 3.5;

-- Q28. Low ratings (2 stars or less) for follow-up with the patient
SELECT p.full_name, p.phone, d.doctor_name, f.rating, f.feedback_date
FROM patient_feedback f
JOIN patients p     ON f.patient_id = p.patient_id
JOIN appointments a ON f.appointment_id = a.appointment_id
JOIN doctors d      ON a.doctor_id = d.doctor_id
WHERE f.rating <= 2;

-- Q29. Feedback response rate: completed visits that got a rating
SELECT COUNT(*) AS completed_visits,
       COUNT(f.feedback_id) AS feedback_received,
       ROUND(COUNT(f.feedback_id) * 100.0 / NULLIF(COUNT(*), 0), 1) AS response_percent
FROM appointments a
LEFT JOIN patient_feedback f ON a.appointment_id = f.appointment_id
WHERE a.status = 'COMPLETED';

-- Q30. Completed visits where the patient has not given feedback yet
SELECT a.appointment_id, p.full_name, p.phone, a.appointment_date
FROM appointments a
JOIN patients p ON a.patient_id = p.patient_id
LEFT JOIN patient_feedback f ON a.appointment_id = f.appointment_id
WHERE a.status = 'COMPLETED' AND f.feedback_id IS NULL;
