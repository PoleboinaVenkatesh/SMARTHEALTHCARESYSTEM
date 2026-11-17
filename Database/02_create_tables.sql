-- =====================================================
-- 02. CREATE TABLES  (10 tables)
-- =====================================================
USE smart_hospital_db;

CREATE TABLE departments (
    dept_id   INT AUTO_INCREMENT PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL UNIQUE,
    floor_no  INT NOT NULL
);

CREATE TABLE doctors (
    doctor_id        INT AUTO_INCREMENT PRIMARY KEY,
    doctor_name      VARCHAR(100) NOT NULL,
    dept_id          INT NOT NULL,
    specialization   VARCHAR(100) NOT NULL,
    consultation_fee DECIMAL(8,2) NOT NULL CHECK (consultation_fee > 0),
    shift            ENUM('MORNING','EVENING','NIGHT') NOT NULL,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name  VARCHAR(100) NOT NULL,
    gender     ENUM('M','F','O') NOT NULL,
    dob        DATE NOT NULL,
    city       VARCHAR(50) NOT NULL,
    phone      VARCHAR(15) NOT NULL
);

-- Hospital beds: the main "resource" we optimize
CREATE TABLE beds (
    bed_id       INT AUTO_INCREMENT PRIMARY KEY,
    dept_id      INT NOT NULL,
    bed_type     ENUM('GENERAL','PRIVATE','ICU') NOT NULL,
    daily_charge DECIMAL(8,2) NOT NULL CHECK (daily_charge > 0),
    status       ENUM('AVAILABLE','OCCUPIED','MAINTENANCE') DEFAULT 'AVAILABLE',
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

-- OPD (outpatient) visits
CREATE TABLE appointments (
    appointment_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id       INT NOT NULL,
    doctor_id        INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    status           ENUM('SCHEDULED','COMPLETED','CANCELLED','NO_SHOW') DEFAULT 'SCHEDULED',
    UNIQUE KEY uq_appointments_patient_appointment (patient_id, appointment_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id)
);

-- IPD (inpatient) admissions
CREATE TABLE admissions (
    admission_id      INT AUTO_INCREMENT PRIMARY KEY,
    patient_id        INT NOT NULL,
    doctor_id         INT NOT NULL,
    bed_id            INT NOT NULL,
    admit_date        DATE NOT NULL,
    discharge_date    DATE NULL,
    diagnosis         VARCHAR(150) NOT NULL,
    treatment_charges DECIMAL(10,2) NOT NULL DEFAULT 0,
    status            ENUM('ADMITTED','DISCHARGED') DEFAULT 'ADMITTED',
    CHECK (discharge_date IS NULL OR discharge_date >= admit_date),
    UNIQUE KEY uq_admissions_patient_admission (patient_id, admission_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)  REFERENCES doctors(doctor_id),
    FOREIGN KEY (bed_id)     REFERENCES beds(bed_id)
);

-- A bill belongs to EITHER an appointment (OPD) OR an admission (IPD)
CREATE TABLE bills (
    bill_id        INT AUTO_INCREMENT PRIMARY KEY,
    patient_id     INT NOT NULL,
    appointment_id INT NULL,
    admission_id   INT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    payment_status ENUM('PAID','PENDING') DEFAULT 'PENDING',
    bill_date      DATE NOT NULL,
    CHECK (amount > 0),
    CHECK ((appointment_id IS NOT NULL AND admission_id IS NULL)
        OR (appointment_id IS NULL AND admission_id IS NOT NULL)),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    -- Composite foreign keys ensure the bill patient matches the linked visit/admission.
    FOREIGN KEY (patient_id, appointment_id)
        REFERENCES appointments(patient_id, appointment_id),
    FOREIGN KEY (patient_id, admission_id)
        REFERENCES admissions(patient_id, admission_id)
);

-- =====================================================
-- NEW TABLES: pharmacy and patient satisfaction
-- =====================================================

-- Medicine inventory (one batch per medicine, for simplicity)
CREATE TABLE medicines (
    medicine_id    INT AUTO_INCREMENT PRIMARY KEY,
    medicine_name  VARCHAR(100) NOT NULL UNIQUE,
    category       VARCHAR(50)  NOT NULL,
    unit_price     DECIMAL(8,2) NOT NULL CHECK (unit_price > 0),
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    expiry_date    DATE NOT NULL
);

-- Medicines prescribed by doctors to patients
CREATE TABLE prescriptions (
    prescription_id   INT AUTO_INCREMENT PRIMARY KEY,
    patient_id        INT NOT NULL,
    doctor_id         INT NOT NULL,
    medicine_id       INT NOT NULL,
    quantity          INT NOT NULL CHECK (quantity > 0),
    prescription_date DATE NOT NULL,
    FOREIGN KEY (patient_id)  REFERENCES patients(patient_id),
    FOREIGN KEY (doctor_id)   REFERENCES doctors(doctor_id),
    FOREIGN KEY (medicine_id) REFERENCES medicines(medicine_id)
);

-- Patient satisfaction: one rating (1 to 5) per completed appointment
CREATE TABLE patient_feedback (
    feedback_id    INT AUTO_INCREMENT PRIMARY KEY,
    patient_id     INT NOT NULL,
    appointment_id INT NOT NULL UNIQUE,
    rating         INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    feedback_date  DATE NOT NULL,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    -- Feedback must belong to the same patient as the appointment.
    FOREIGN KEY (patient_id, appointment_id)
        REFERENCES appointments(patient_id, appointment_id)
);
