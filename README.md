# MD_water_services_SQL
A real-world SQL analysis project simulating water infrastructure challenges in the fictional region of Maji Ndogo. Over four stages, this project explores how structured data, insightful queries, and audit-driven thinking can uncover deep truths about public water systems — and inform life-changing decisions.

Project Overview
🔹 PART 1 – Data Cleaning & Initial Exploration
Cleaned employee emails using SQL string functions.

Standardized phone_number entries.

Assessed staffing per town.

Ranked top 3 field employees by visit count.

🔹 PART 2 – Water Access Analysis
Summed people served by each water source.

Analyzed queue times across days and hours.

Created improvement ranking using RANK() window functions.

Generated location-wise breakdowns.

🔹 PART 3 – Auditing & ERD Modeling
Designed a simplified ERD connecting key entities.

Identified mismatches and anomalies in visits, employee, and source records.

Validated relational integrity.

Prepared a normalized schema view for future use.

🔹 PART 4 – Final Reporting & Recommendations
Town-level reporting on visits and record frequency.

Identified worst-performing employees.

Queue time heatmaps by weekday and hour.

Final recommendations based on data.

| Metric                           | Value / Insight                      |
| -------------------------------- | ------------------------------------ |
| Total People Surveyed            | 27M+                                 |
| Most Used Water Source           | Shared Tap (12M+ users)              |
| Avg. Queue Time (All Sources)    | \~18 minutes                         |
| Busiest Queue Days               | Sunday, Monday                       |
| Peak Queue Hours                 | 6:00 AM – 9:00 AM                    |
| Worst-performing Employee Visits | 4 and 6 site visits (IDs 20 & 22)    |
| Highest-Impact Fix               | Shared tap restoration and expansion |


🧠 ERD Summary
Main Tables:

employee

visits

water_source

location

Key Relationships:

visits.assigned_employee_id → employee.employee_id

visits.source_id → water_source.source_id

location joins via location_id

(See reports/ERD_model_explanation.md for full breakdown.)

🚀 How to Use This Repo
Clone the repository

Open .sql files in MySQL Workbench (or equivalent)

Run scripts in order: Part 1 → Part 4

View summarized insights in reports/

Use slides/maji_ndogo_summary_slides.pdf for presentations or stakeholders

🛠️ Tools Used
MySQL / SQL Workbench

Visual Studio Code (for SQL & Markdown)

Canva / PowerPoint (for slides)

GitHub (project hosting and versioning)

🔚 Recommendations
🌊 Prioritize shared tap repairs and morning collection support

🛠 Fix broken in-home taps for immediate household relief

🧑‍🤝‍🧑 Reassign or upskill underperforming employees

🧼 Focus on well decontamination where needed

📈 Implement real-time queue monitoring and dashboarding

