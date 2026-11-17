# Database Design
## Smart Healthcare Analytics & Hospital Resource Optimization

## 1. Design approach
The database is relational. Each main business entity is represented by a
table, with primary keys identifying rows and foreign keys connecting related
records. The design separates operational areas such as appointments,
admissions, billing, pharmacy, and patient feedback.

## 2. Entities and key attributes

| Entity / table | Primary key | Important attributes | Purpose |
|---|---|---|---|
| departments | `dept_id` | `dept_name`, `floor_no` | Hospital departments |
| doctors | `doctor_id` | `doctor_name`, `dept_id`, `specialization`, `consultation_fee`, `shift` | Doctors and their department |
| patients | `patient_id` | `full_name`, `gender`, `dob`, `city`, `phone` | Patient information |
| beds | `bed_id` | `dept_id`, `bed_type`, `daily_charge`, `status` | Hospital bed resources |
| appointments | `appointment_id` | `patient_id`, `doctor_id`, date, time, status | OPD appointments |
| admissions | `admission_id` | `patient_id`, `doctor_id`, `bed_id`, admit/discharge dates, diagnosis, charges, status | IPD stays |
| bills | `bill_id` | `patient_id`, `appointment_id`, `admission_id`, amount, payment status, date | OPD or IPD bills |
| medicines | `medicine_id` | `medicine_name`, `category`, `unit_price`, `stock_quantity`, `expiry_date` | Medicine inventory |
| prescriptions | `prescription_id` | `patient_id`, `doctor_id`, `medicine_id`, quantity, date | Prescribed medicines |
| patient_feedback | `feedback_id` | `patient_id`, `appointment_id`, rating, date | Appointment feedback |

## 3. Relationships and cardinalities

- One department can have many doctors; each doctor belongs to one department.
- One department can contain many beds; each bed belongs to one department.
- One patient can have many appointments; each appointment belongs to one patient.
- One doctor can handle many appointments; each appointment references one doctor.
- One patient can have many admissions; each admission references one patient.
- One doctor can manage many admissions; each admission references one doctor.
- One bed can be referenced by many admission records over time; each admission references one bed.
- A patient can have many bills. Each bill is linked to exactly one appointment OR one admission, enforced by a CHECK constraint and composite foreign keys.
- One patient, doctor, or medicine can appear in many prescription records.
- An appointment can have at most one feedback record because `patient_feedback.appointment_id` is UNIQUE. Feedback also references the same patient as the appointment.

## 4. Integrity rules
- Primary keys uniquely identify each record.
- Foreign keys enforce valid relationships.
- Unique constraints prevent duplicate department names, medicine names, and multiple feedback records for one appointment.
- CHECK constraints restrict positive charges and quantities, valid feedback ratings, and valid admission dates.
- A bill must reference either an appointment or an admission, not both.
- Composite foreign keys ensure the patient on a bill or feedback row matches the patient on the related appointment/admission.

## 5. ER diagram
See `ER_Diagram.mmd` in this folder. It uses Mermaid ER diagram syntax and can be previewed in a Mermaid-compatible Markdown editor.

## 6. Important design note
The SQL schema does not include a separate payment transaction table, medicine supplier table,
or multiple medicine batches per product. Medicine inventory is represented as one
record per medicine for this educational project.
