-- =====================================================
-- 06. STORED PROCEDURES
-- =====================================================
USE smart_hospital_db;

DELIMITER $$

-- Procedure 1: Book an OPD appointment (no double booking of a doctor)
CREATE PROCEDURE sp_book_appointment(
    IN p_patient_id INT,
    IN p_doctor_id  INT,
    IN p_date       DATE,
    IN p_time       TIME
)
BEGIN
    DECLARE v_clash INT DEFAULT 0;

    IF p_date < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment date cannot be in the past';
    END IF;

    SELECT COUNT(*) INTO v_clash
    FROM appointments
    WHERE doctor_id = p_doctor_id AND appointment_date = p_date
      AND appointment_time = p_time AND status IN ('SCHEDULED', 'COMPLETED');

    IF v_clash > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Doctor is already booked at this time';
    END IF;

    INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time)
    VALUES (p_patient_id, p_doctor_id, p_date, p_time);

    SELECT LAST_INSERT_ID() AS appointment_id;
END$$

-- Procedure 2: Complete a visit and create the OPD bill (doctor's fee)
CREATE PROCEDURE sp_complete_appointment(IN p_appointment_id INT)
BEGIN
    DECLARE v_status  VARCHAR(20) DEFAULT NULL;
    DECLARE v_patient INT;
    DECLARE v_fee     DECIMAL(8,2);

    SELECT MAX(a.status), MAX(a.patient_id), MAX(d.consultation_fee)
    INTO v_status, v_patient, v_fee
    FROM appointments a
    JOIN doctors d ON a.doctor_id = d.doctor_id
    WHERE a.appointment_id = p_appointment_id;

    IF v_status IS NULL OR v_status <> 'SCHEDULED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Only a SCHEDULED appointment can be completed';
    END IF;

    UPDATE appointments SET status = 'COMPLETED' WHERE appointment_id = p_appointment_id;

    INSERT INTO bills (patient_id, appointment_id, amount, payment_status, bill_date)
    VALUES (v_patient, p_appointment_id, v_fee, 'PENDING', CURDATE());

    SELECT LAST_INSERT_ID() AS bill_id, v_fee AS amount;
END$$

-- Procedure 3: Admit a patient (bed must be free and belong to the doctor's department)
CREATE PROCEDURE sp_admit_patient(
    IN p_patient_id INT,
    IN p_doctor_id  INT,
    IN p_bed_id     INT,
    IN p_diagnosis  VARCHAR(150)
)
BEGIN
    DECLARE v_bed_status VARCHAR(20) DEFAULT NULL;
    DECLARE v_bed_dept   INT DEFAULT NULL;
    DECLARE v_doc_dept   INT DEFAULT NULL;
    DECLARE v_active     INT DEFAULT 0;
    DECLARE v_new_id     INT;

    SELECT MAX(status), MAX(dept_id) INTO v_bed_status, v_bed_dept
    FROM beds WHERE bed_id = p_bed_id;
    SELECT MAX(dept_id) INTO v_doc_dept
    FROM doctors WHERE doctor_id = p_doctor_id;

    IF v_bed_status IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed not found';
    END IF;
    IF v_bed_status <> 'AVAILABLE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed is not available';
    END IF;
    IF v_doc_dept IS NULL OR v_doc_dept <> v_bed_dept THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bed does not belong to the doctor department';
    END IF;

    SELECT COUNT(*) INTO v_active FROM admissions
    WHERE patient_id = p_patient_id AND status = 'ADMITTED';
    IF v_active > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Patient is already admitted';
    END IF;

    INSERT INTO admissions (patient_id, doctor_id, bed_id, admit_date, diagnosis)
    VALUES (p_patient_id, p_doctor_id, p_bed_id, CURDATE(), p_diagnosis);
    SET v_new_id = LAST_INSERT_ID();

    UPDATE beds SET status = 'OCCUPIED' WHERE bed_id = p_bed_id;

    SELECT v_new_id AS admission_id, p_bed_id AS bed_id;
END$$

-- Procedure 4: Discharge a patient, free the bed and create the IPD bill
--   bill = days stayed (minimum 1) x bed charge + treatment charges
CREATE PROCEDURE sp_discharge_patient(IN p_admission_id INT, IN p_treatment_charges DECIMAL(10,2))
BEGIN
    DECLARE v_status  VARCHAR(20) DEFAULT NULL;
    DECLARE v_admit   DATE;
    DECLARE v_bed     INT;
    DECLARE v_patient INT;
    DECLARE v_rate    DECIMAL(8,2);
    DECLARE v_days    INT;
    DECLARE v_amount  DECIMAL(10,2);

    SELECT MAX(a.status), MAX(a.admit_date), MAX(a.bed_id),
           MAX(a.patient_id), MAX(b.daily_charge)
    INTO v_status, v_admit, v_bed, v_patient, v_rate
    FROM admissions a
    JOIN beds b ON a.bed_id = b.bed_id
    WHERE a.admission_id = p_admission_id;

    IF v_status IS NULL OR v_status <> 'ADMITTED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Admission not found or already discharged';
    END IF;

    IF p_treatment_charges IS NULL OR p_treatment_charges < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Treatment charges cannot be NULL or negative';
    END IF;

    SET v_days   = GREATEST(DATEDIFF(CURDATE(), v_admit), 1);
    SET v_amount = v_days * v_rate + p_treatment_charges;

    UPDATE admissions
    SET discharge_date = CURDATE(), status = 'DISCHARGED', treatment_charges = p_treatment_charges
    WHERE admission_id = p_admission_id;

    UPDATE beds SET status = 'AVAILABLE' WHERE bed_id = v_bed;

    INSERT INTO bills (patient_id, admission_id, amount, payment_status, bill_date)
    VALUES (v_patient, p_admission_id, v_amount, 'PENDING', CURDATE());

    SELECT v_days AS days_stayed, v_amount AS bill_amount;
END$$

-- Procedure 5: Mark a pending bill as paid
CREATE PROCEDURE sp_pay_bill(IN p_bill_id INT)
BEGIN
    UPDATE bills SET payment_status = 'PAID'
    WHERE bill_id = p_bill_id AND payment_status = 'PENDING';

    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bill not found or already paid';
    END IF;

    SELECT * FROM bills WHERE bill_id = p_bill_id;
END$$

-- Procedure 6: Prescribe a medicine (checks expiry and stock, reduces stock)
CREATE PROCEDURE sp_add_prescription(
    IN p_patient_id  INT,
    IN p_doctor_id   INT,
    IN p_medicine_id INT,
    IN p_quantity    INT
)
BEGIN
    DECLARE v_stock  INT DEFAULT NULL;
    DECLARE v_expiry DATE;
    DECLARE v_price  DECIMAL(8,2);
    DECLARE v_new_id INT;

    SELECT stock_quantity, expiry_date, unit_price INTO v_stock, v_expiry, v_price
    FROM medicines WHERE medicine_id = p_medicine_id;

    IF v_stock IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicine not found';
    END IF;
    IF v_expiry < CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicine has expired';
    END IF;
    IF v_stock < p_quantity THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Not enough medicine stock';
    END IF;

    INSERT INTO prescriptions (patient_id, doctor_id, medicine_id, quantity, prescription_date)
    VALUES (p_patient_id, p_doctor_id, p_medicine_id, p_quantity, CURDATE());
    SET v_new_id = LAST_INSERT_ID();

    UPDATE medicines SET stock_quantity = stock_quantity - p_quantity
    WHERE medicine_id = p_medicine_id;

    SELECT v_new_id AS prescription_id, v_price * p_quantity AS total_cost,
           v_stock - p_quantity AS stock_left;
END$$

-- Procedure 7: Restock a medicine with a new batch
--   If the old stock has expired it is discarded; otherwise the quantity is added.
CREATE PROCEDURE sp_restock_medicine(
    IN p_medicine_id INT,
    IN p_quantity    INT,
    IN p_new_expiry  DATE
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;

    SELECT COUNT(*) INTO v_exists FROM medicines WHERE medicine_id = p_medicine_id;
    IF v_exists = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Medicine not found';
    END IF;
    IF p_quantity <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Quantity must be greater than zero';
    END IF;
    IF p_new_expiry <= CURDATE() THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New batch expiry date must be in the future';
    END IF;

    -- stock_quantity must be assigned BEFORE expiry_date (MySQL updates left to right)
    UPDATE medicines
    SET stock_quantity = IF(expiry_date < CURDATE(), p_quantity, stock_quantity + p_quantity),
        expiry_date    = GREATEST(expiry_date, p_new_expiry)
    WHERE medicine_id = p_medicine_id;

    SELECT * FROM vw_medicine_stock_alert WHERE medicine_id = p_medicine_id;
END$$

-- Procedure 8: Record patient feedback (completed appointment of the same patient, once only)
CREATE PROCEDURE sp_add_feedback(
    IN p_patient_id     INT,
    IN p_appointment_id INT,
    IN p_rating         INT
)
BEGIN
    DECLARE v_owner  INT DEFAULT NULL;
    DECLARE v_status VARCHAR(20);
    DECLARE v_given  INT DEFAULT 0;

    SELECT MAX(patient_id), MAX(status) INTO v_owner, v_status
    FROM appointments WHERE appointment_id = p_appointment_id;

    IF v_owner IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment not found';
    END IF;
    IF v_owner <> p_patient_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Appointment does not belong to this patient';
    END IF;
    IF v_status <> 'COMPLETED' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Feedback is allowed only for completed appointments';
    END IF;
    IF p_rating NOT BETWEEN 1 AND 5 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Rating must be between 1 and 5';
    END IF;

    SELECT COUNT(*) INTO v_given FROM patient_feedback WHERE appointment_id = p_appointment_id;
    IF v_given > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Feedback already given for this appointment';
    END IF;

    INSERT INTO patient_feedback (patient_id, appointment_id, rating, feedback_date)
    VALUES (p_patient_id, p_appointment_id, p_rating, CURDATE());

    SELECT LAST_INSERT_ID() AS feedback_id;
END$$

DELIMITER ;

-- Usage:
-- CALL sp_admit_patient(5, 3, 8, 'Fever');          -- Lavanya into General Medicine bed 8
-- CALL sp_discharge_patient(10, 6000.00);           -- discharge admission 10
-- CALL sp_book_appointment(2, 1, '2026-11-20', '10:00:00');
-- CALL sp_complete_appointment(14);
-- CALL sp_pay_bill(14);
-- CALL sp_add_prescription(5, 3, 1, 10);            -- Paracetamol x10 for Lavanya
-- CALL sp_restock_medicine(8, 200, '2027-12-31');    -- restock ORS
-- CALL sp_add_feedback(1, 13, 5);                    -- Ravi Teja rates appointment 13
