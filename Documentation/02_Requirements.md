# Project Requirements
## Project
Smart Healthcare Analytics & Hospital Resource Optimization

## 1. Business problem
Hospitals need a structured way to track patients, doctors, appointments,
admissions, beds, billing, medicines, prescriptions, and patient feedback.
This project creates a relational database and SQL analysis layer to explore
these operations and identify opportunities to improve resource utilization.

## 2. Project objectives
- Track hospital departments, doctors, patients, appointments, and admissions.
- Monitor bed availability, occupancy, and utilization.
- Analyze patient visits, diagnoses, and readmissions.
- Summarize OPD/IPD billing, collections, and pending amounts.
- Monitor medicine stock, expiry, and prescription patterns.
- Analyze patient feedback and doctor satisfaction.

## 3. Functional requirements
1. Store department and doctor details.
2. Store patient details.
3. Maintain bed type, department, daily charge, and availability status.
4. Record appointments with doctor, date, time, and status.
5. Record admissions, allocated beds, diagnosis, and discharge details.
6. Generate bills for either an appointment or an admission.
7. Maintain medicine inventory and prescriptions.
8. Store patient feedback for appointments.
9. Produce analytical reports using SQL queries and views.
10. Support common workflows using stored procedures.
11. Reuse calculations through user-defined functions.

## 4. Non-functional requirements
- Use relational constraints to maintain referential integrity.
- Use clear table and column names.
- Use MySQL 8.0-compatible SQL.
- Organize SQL scripts and documentation in separate folders.
- Keep sample data suitable for demonstrating project queries.
- Use test data when experimenting with procedures that modify records.

## 5. Technology requirements
- MySQL Server 8.0 or later
- MySQL Workbench
- Windows, macOS, or Linux computer capable of running MySQL Server

## 6. Scope
This is an educational SQL portfolio project using sample data. It is not a
production clinical or hospital information system.
