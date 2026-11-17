-- =====================================================
-- 07. FUNCTIONS
-- =====================================================
USE smart_hospital_db;

DELIMITER $$

-- Function 1: Age of a patient
CREATE FUNCTION fn_patient_age(p_patient_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_age INT;
    SELECT MAX(TIMESTAMPDIFF(YEAR, dob, CURDATE()))
    INTO v_age FROM patients WHERE patient_id = p_patient_id;
    RETURN COALESCE(v_age, 0);
END$$

-- Function 2: Bed occupancy % of a department (maintenance beds are not counted)
CREATE FUNCTION fn_bed_occupancy_percent(p_dept_id INT)
RETURNS DECIMAL(5,1)
READS SQL DATA
BEGIN
    DECLARE v_pct DECIMAL(5,1);
    SELECT ROUND(SUM(status = 'OCCUPIED') * 100 / NULLIF(SUM(status <> 'MAINTENANCE'), 0), 1)
    INTO v_pct FROM beds WHERE dept_id = p_dept_id;
    RETURN COALESCE(v_pct, 0);
END$$

-- Function 3: Length of stay in days (till today if still admitted)
CREATE FUNCTION fn_length_of_stay(p_admission_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    SELECT MAX(DATEDIFF(COALESCE(discharge_date, CURDATE()), admit_date))
    INTO v_days FROM admissions WHERE admission_id = p_admission_id;
    RETURN COALESCE(v_days, 0);
END$$

-- Function 4: Number of beds currently free in a department
CREATE FUNCTION fn_free_beds(p_dept_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_free INT;
    SELECT COUNT(*) INTO v_free FROM beds WHERE dept_id = p_dept_id AND status = 'AVAILABLE';
    RETURN v_free;
END$$

-- Function 5: Patient risk level
--   HIGH   : age 60+ AND two or more admissions
--   MEDIUM : age 60+ OR  two or more admissions
--   LOW    : otherwise
CREATE FUNCTION fn_patient_risk(p_patient_id INT)
RETURNS VARCHAR(6)
READS SQL DATA
BEGIN
    DECLARE v_age  INT;
    DECLARE v_adm  INT;

    SET v_age = fn_patient_age(p_patient_id);
    SELECT COUNT(*) INTO v_adm FROM admissions WHERE patient_id = p_patient_id;

    RETURN CASE
        WHEN v_age >= 60 AND v_adm >= 2 THEN 'HIGH'
        WHEN v_age >= 60 OR  v_adm >= 2 THEN 'MEDIUM'
        ELSE 'LOW'
    END;
END$$

-- Function 6: Cost of one prescription (quantity x unit price)
CREATE FUNCTION fn_prescription_cost(p_prescription_id INT)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_cost DECIMAL(10,2);
    SELECT MAX(pr.quantity * m.unit_price) INTO v_cost
    FROM prescriptions pr
    JOIN medicines m ON pr.medicine_id = m.medicine_id
    WHERE pr.prescription_id = p_prescription_id;
    RETURN COALESCE(v_cost, 0);
END$$

-- Function 7: Average patient rating of a doctor (0 if no feedback)
CREATE FUNCTION fn_doctor_avg_rating(p_doctor_id INT)
RETURNS DECIMAL(3,2)
READS SQL DATA
BEGIN
    DECLARE v_avg DECIMAL(3,2);
    SELECT ROUND(AVG(f.rating), 2) INTO v_avg
    FROM patient_feedback f
    JOIN appointments a ON f.appointment_id = a.appointment_id
    WHERE a.doctor_id = p_doctor_id;
    RETURN COALESCE(v_avg, 0);
END$$

-- Function 8: Days left before a medicine expires (negative = expired)
CREATE FUNCTION fn_medicine_days_left(p_medicine_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_days INT;
    SELECT MAX(DATEDIFF(expiry_date, CURDATE()))
    INTO v_days FROM medicines WHERE medicine_id = p_medicine_id;
    RETURN COALESCE(v_days, 0);
END$$

DELIMITER ;

-- Usage:
-- SELECT fn_bed_occupancy_percent(1);               -- Cardiology
-- SELECT fn_free_beds(3);                           -- General Medicine
-- SELECT full_name, fn_patient_risk(patient_id) FROM patients;
-- SELECT admission_id, fn_length_of_stay(admission_id) FROM admissions;
-- SELECT fn_prescription_cost(1);
-- SELECT doctor_name, fn_doctor_avg_rating(doctor_id) FROM doctors;
-- SELECT medicine_name, fn_medicine_days_left(medicine_id) FROM medicines;
