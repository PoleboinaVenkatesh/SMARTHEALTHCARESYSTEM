# Smart Healthcare Analytics & Hospital Resource Optimization

## 1. Project overview

This is a MySQL 8.0 database project for analyzing hospital operations and
supporting better use of hospital resources. It combines operational data
with analytical queries, views, stored procedures, and user-defined functions.

The project covers five analysis areas:

1. Hospital resource optimization
2. Patient analytics
3. Revenue analytics
4. Pharmacy analytics
5. Patient satisfaction analytics

## 2. Objectives

- Monitor bed occupancy and identify departments under high or low load.
- Review current inpatients, free beds, and patient length of stay.
- Analyze appointment patterns, doctor workload, and no-show rates.
- Identify repeat admissions and patient risk levels.
- Review department revenue, monthly collections, and pending bills.
- Monitor medicine stock, expiry dates, and prescription patterns.
- Measure patient feedback and compare doctor satisfaction ratings.

## 3. Technology

| Component | Technology |
|---|---|
| Database | MySQL 8.0 |
| SQL environment | MySQL Workbench |
| Query language | SQL |
| Database objects | Tables, views, stored procedures, functions |
| Analysis techniques | Joins, aggregates, CTEs, window functions, date functions |

## 4. Database tables

The schema script creates these 10 tables:

| Table | Purpose |
|---|---|
| `departments` | Hospital departments |
| `doctors` | Doctors associated with departments |
| `patients` | Patient demographic and identifying details |
| `beds` | Beds, bed types, department allocation and availability |
| `appointments` | Outpatient (OPD) appointments |
| `admissions` | Inpatient (IPD) admissions and discharge information |
| `bills` | OPD/IPD billing and payment status |
| `medicines` | Medicine inventory and expiry information |
| `prescriptions` | Medicines prescribed to patients |
| `patient_feedback` | Patient ratings associated with completed appointments |

Primary keys identify individual records. Foreign keys connect related records.
The schema also uses constraints to help prevent invalid relationships and
values. In particular, billing records link to the relevant visit/admission,
and feedback is tied to the corresponding patient's appointment.

## 5. SQL file guide and execution order

Run the files in this order in MySQL Workbench:

| Order | File | What it does |
|---:|---|---|
| 1 | `01_create_database.sql` | Creates/recreates `smart_hospital_db` |
| 2 | `02_create_tables.sql` | Creates the relational tables |
| 3 | `03_insert_data.sql` | Inserts the sample records |
| 4 | `07_functions.sql` | Creates the user-defined functions |
| 5 | `05_views.sql` | Creates reusable analytical views |
| 6 | `06_procedures.sql` | Creates workflow procedures |
| 7 | `04_queries.sql` | Runs the 30 analytical queries |

### MySQL Workbench steps

1. Open MySQL Workbench.
2. Connect to your MySQL Server connection.
3. Select **File → Open SQL Script** and choose the first file.
4. Click the lightning-bolt **Execute** button.
5. Review the **Action Output** panel for errors.
6. Repeat for each file in the order above.
7. For `04_queries.sql`, scroll through the script and inspect each Result Grid.

### Important

- The database creation script drops and recreates the project database. Back up
  any data you need before executing it.
- Run the sample-data script once only on a freshly created schema.
- If you need a clean reset, execute files 01, 02, and 03 again in order, then
  recreate functions, views, and procedures.

## 6. Analytical query catalogue

The `04_queries.sql` file contains 30 queries grouped as follows.

### A. Resource optimization

| Query | Analysis |
|---|---|
| Q1 | Bed occupancy by department and departments that may need more beds |
| Q2 | Patients currently admitted |
| Q3 | Free beds ready for use |
| Q4 | Bed utilization by bed type (GENERAL / PRIVATE / ICU) |
| Q5 | Average length of stay by department for discharged patients |
| Q6 | Doctor workload ranking |
| Q7 | Peak outpatient appointment hours |
| Q8 | Appointment no-show rate |

### B. Patient analytics

| Query | Analysis |
|---|---|
| Q9 | 30-day readmissions using a CTE and `LAG()` |
| Q10 | Patient risk level using a stored function |
| Q11 | Most common diagnoses |
| Q12 | Patient distribution by age group |

### C. Revenue analytics

| Query | Analysis |
|---|---|
| Q13 | Revenue by department (OPD + IPD) |
| Q14 | OPD compared with IPD billing |
| Q15 | Monthly collected revenue and growth |
| Q16 | Pending bills / outstanding amounts |

### D. Pharmacy analytics

| Query | Analysis |
|---|---|
| Q17 | Expired, low-stock and soon-to-expire medicines |
| Q18 | Most prescribed medicines by units and value |
| Q19 | Prescription value by medicine category |
| Q20 | One patient's prescription history and cost |
| Q21 | Doctors with the highest prescription counts |
| Q22 | Medicine spend per patient and share of total |

**Note:** Q19 reports prescription value by category; it should not be
interpreted as confirmed pharmacy sales.

### E. Patient satisfaction

| Query | Analysis |
|---|---|
| Q23 | Average satisfaction and percentage of happy patients |
| Q24 | Patient rating distribution |
| Q25 | Doctor satisfaction ranking |
| Q26 | Satisfaction by department |
| Q27 | Doctor workload compared with satisfaction |
| Q28 | Low ratings requiring follow-up |
| Q29 | Feedback response rate |
| Q30 | Completed appointments without feedback |

## 7. Views

The views in `05_views.sql` provide reusable result sets:

| View | Purpose |
|---|---|
| `vw_bed_occupancy` | Department bed occupancy and load status |
| `vw_current_inpatients` | Patients currently in hospital |
| `vw_doctor_workload` | Workload summary for doctors |
| `vw_department_revenue` | Department revenue from paid OPD/IPD bills |
| `vw_pending_bills` | Bills that are not yet paid |
| `vw_medicine_stock_alert` | Medicine expiry and low-stock alerts |
| `vw_prescription_details` | Prescription details with names and cost |
| `vw_doctor_feedback` | Doctor patient-satisfaction summary |

Example:

```sql
USE smart_hospital_db;

SELECT * FROM vw_bed_occupancy;
SELECT * FROM vw_current_inpatients;
SELECT * FROM vw_pending_bills;
SELECT * FROM vw_medicine_stock_alert;
SELECT * FROM vw_doctor_feedback;
```

## 8. Stored procedures

The procedures in `06_procedures.sql` represent common hospital workflows.

| Procedure | Purpose |
|---|---|
| `sp_book_appointment` | Books an outpatient appointment and checks doctor booking conflicts |
| `sp_complete_appointment` | Completes an appointment and creates its OPD bill |
| `sp_admit_patient` | Admits a patient using an available suitable bed |
| `sp_discharge_patient` | Discharges a patient, frees the bed and creates an IPD bill |
| `sp_pay_bill` | Marks a pending bill as paid |
| `sp_add_prescription` | Adds a prescription after stock/expiry checks and updates stock |
| `sp_restock_medicine` | Restocks a medicine batch |
| `sp_add_feedback` | Records feedback for an eligible completed appointment |

Use the parameter order shown in the procedure definitions and the example
`CALL` statements at the bottom of the SQL file. Test workflow procedures on
sample/test records so that you do not unintentionally change data you need.

## 9. User-defined functions

The functions in `07_functions.sql` provide reusable calculations:

| Function | Purpose |
|---|---|
| `fn_patient_age` | Calculates a patient's age |
| `fn_bed_occupancy_percent` | Calculates department bed occupancy percentage |
| `fn_length_of_stay` | Calculates admission length of stay |
| `fn_free_beds` | Counts currently free beds in a department |
| `fn_patient_risk` | Returns a patient risk category based on the function's defined rules |
| `fn_prescription_cost` | Calculates prescription quantity multiplied by unit price |
| `fn_doctor_avg_rating` | Calculates a doctor's average patient rating |
| `fn_medicine_days_left` | Calculates days remaining until medicine expiry |

Example:

```sql
SELECT patient_id, fn_patient_age(patient_id)
FROM patients;

SELECT doctor_id, fn_doctor_avg_rating(doctor_id)
FROM doctors;
```

## 10. SQL concepts demonstrated

- DDL: `CREATE DATABASE`, `CREATE TABLE`, `CREATE VIEW`
- DML: `INSERT`, `UPDATE`
- Constraints: primary key, foreign key, unique, check, not null
- Joins: combining related hospital entities
- Aggregates: `COUNT()`, `SUM()`, `AVG()`, `MIN()`, `MAX()`
- Grouping: `GROUP BY`, `HAVING`
- CTEs: `WITH`
- Window functions: `RANK()`, `LAG()`, and analytical calculations
- Conditional logic: `CASE`
- Null handling: `COALESCE()` and `NULLIF()`
- Programmable SQL: stored procedures and user-defined functions

## 11. Troubleshooting

### Error 1452: Cannot add or update a child row

A foreign-key value in the child table does not match a parent record. Check
that the referenced patient, appointment, or admission exists before inserting
the related bill or feedback row. Confirm the actual IDs with `SELECT` queries.

### Error 1146: Table doesn't exist

Check that the correct database is selected:

```sql
USE smart_hospital_db;
SHOW TABLES;
```

### Error 1304: Procedure/function already exists

The object may already have been created. Check the object list and avoid
re-running only part of a script without understanding which statements have
already succeeded. Recreating the database and running all files in order is
the clean-reset approach, but it deletes existing project data.

### No result appears

For a `SELECT`, look at the Result Grid. For `CREATE`, `INSERT`, `UPDATE`,
procedure, or function statements, check the Action Output panel for the
execution status and affected rows.

## 12. Suggested portfolio description

**Smart Healthcare Analytics & Hospital Resource Optimization — MySQL**

Designed a relational hospital database with 10 tables covering departments,
doctors, patients, beds, appointments, admissions, billing, medicines,
prescriptions, and patient feedback. Developed 30 SQL analysis queries,
8 views, 8 stored procedures, and 8 user-defined functions to study bed
utilization, patient trends, revenue, pharmacy inventory, and satisfaction.

## 13. Scope and limitations

This is a learning and portfolio project built around sample data. It is not a
production hospital information system. Real deployment would require
security controls, access roles, audit logging, privacy safeguards, backups,
clinical validation, and testing with real operational requirements.

The SQL files are prepared for MySQL 8.0 syntax. They have not been validated
against the user's local MySQL Server in this package; successful execution
must be confirmed in MySQL Workbench.
