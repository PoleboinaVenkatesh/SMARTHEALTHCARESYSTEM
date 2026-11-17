SMART HOSPITAL ANALYTICS — PROJECT FOLDER GUIDE
================================================

Database/
  01_create_database.sql
  02_create_tables.sql
  03_insert_data.sql
  04_queries.sql
  05_views.sql
  06_procedures.sql
  07_functions.sql

Documentation/
  01_Database_Design.md
  02_Requirements.md
  03_ER_Diagram.mmd
  04_Project_Documentation.md

RUN ORDER IN MYSQL WORKBENCH
----------------------------
1. Database/01_create_database.sql
2. Database/02_create_tables.sql
3. Database/03_insert_data.sql
4. Database/07_functions.sql
5. Database/05_views.sql
6. Database/06_procedures.sql
7. Database/04_queries.sql

IMPORTANT
---------
- The create-database script drops and recreates smart_hospital_db.
- Back up any data before running it.
- Run the insert-data script only once after creating the tables.
- The scripts are prepared for MySQL 8.0 but have not been tested against
  your local MySQL Server in this package.

Open Documentation/04_Project_Documentation.md for the full guide.
Open Documentation/03_ER_Diagram.mmd in a Mermaid-compatible editor to view
the entity-relationship diagram.
