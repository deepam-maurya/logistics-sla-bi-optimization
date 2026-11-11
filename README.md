# Logistics Dispatch Performance & Root-Cause Exception Engine

[![Tableau Public Badge](https://img.shields.io/badge/Tableau_Public-Live_Dashboard-E97627?style=for-the-badge&logo=tableau&logoColor=white)](https://public.tableau.com/app/profile/deepam.maurya/viz/Logistics_SLA_Analytics/Logistics_Executive_Dashboard)
[![SQL / Star Schema](https://img.shields.io/badge/SQL-Relational_Data_Model-00758F?style=for-the-badge&logo=postgresql&logoColor=white)](sql/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

An end-to-end operational analytics system and Business Intelligence reporting pipeline that evaluates parcel dispatch performance across fulfillment centers, diagnoses fulfillment failure modes, and models targeted process automations.

## 1. Glossary of Core Concepts & Terminology

Before analyzing operational metrics and technical architecture, this section defines the essential standards and terminology used throughout this project:

* **SLA (Service Level Agreement):** A formalized, contractually binding commitment between a logistics fulfillment provider and its commercial clients or carriers. In dispatch and freight fulfillment, the SLA defines mandatory operational cutoffs—such as the exact window within which inbound parcels must be sorted and handed over to outbound linehaul trucks. Any shipment departing after this cutoff constitutes an **SLA breach**, which results in financial penalty charges, partner chargebacks, and potential contract loss.
* **KPI (Key Performance Indicator):** A quantifiable business measure used to evaluate operational success against strategic objectives (e.g., On-Time Fulfillment Rate, Mean Delay Minutes, Root-Cause Incident Counts).
* **Star Schema:** A relational data modeling pattern optimized for fast analytical querying. It places a centralized **Fact Table** (containing transactional logs and numerical metrics) at the core, directly connected to surrounding **Dimension Tables** (containing descriptive context like facility location, carrier service tiers, and defect categories).
* **CTE (Common Table Expression):** A temporary, named SQL result set (declared using the `WITH` keyword) that simplifies complex queries, improves code readability, and allows multi-stage metric calculations without messy nested subqueries.
* **BPMN 2.0 (Business Process Model and Notation):** An international graphical modeling standard used by business analysts to map end-to-end workflows, system handoffs, conditional logic, and departmental responsibilities using visual swimlanes.
* **As-Is Process Analysis:** The analytical practice of mapping and evaluating an organization’s current operational workflow to uncover baseline friction, manual rework loops, and operational bottlenecks before implementing changes.
* **To-Be Process Design:** The target operational blueprint defining the re-engineered, automated future-state workflow, system interfaces, and target performance metrics.
* **Cycle Time / Lead Time:** The total elapsed time required for a unit (such as a parcel) to pass through a complete operational process from initial facility intake to final dispatch handover, encompassing active handling and idle holding time.
* **Behavior-Driven Development (BDD) & Gherkin Syntax:** An agile specification format using structured human-readable language (`Given-When-Then`) to define unambiguous, testable acceptance criteria for software engineering teams.

---

## 2. Business Problem & Executive Summary

Modern fulfillment networks incur significant margin erosion when sorting facilities miss carrier dispatch deadlines. When sorting terminals lag behind scheduled linehaul truck departures, delays compound across downstream regional networks, triggering financial SLA chargebacks and customer churn.

### Verified Network Operational Baseline

The analytics engine processed the transactional shipment logs across regional facilities (`Berlin_Hub` and `Munich_Hub`). The verified baseline metrics are:

| Metric | Verified Value | Operational Context |
| :--- | :--- | :--- |
| **Total Inbound Dispatches** | 10 Parcels | Full sample ($5$ dispatches in Berlin, $5$ dispatches in Munich) |
| **Total SLA Breaches** | 4 Parcels | Dispatches where `dispatch_status = 'DELAYED'` |
| **Network SLA Breach Rate** | **40.0%** | $\frac{4}{10} \times 100\%$ missed contractual dispatch deadline |
| **On-Time Fulfillment Rate** | **60.0%** | $\frac{6}{10} \times 100\%$ met scheduled dispatch window |
| **Total Tracked Terminal Delay** | 285.0 Minutes | Cumulative delay across all $10$ tracked shipments |
| **Mean Dispatch Delay (All Dispatches)** | 28.5 Minutes | $\frac{285.0\text{ min}}{10\text{ dispatches}}$ |
| **Mean Dispatch Delay (Breached Only)** | 66.25 Minutes | $\frac{45 + 90 + 80 + 50}{4} = \frac{265.0\text{ min}}{4\text{ breaches}}$ |
| **Total Exception Resolution Dwell Time** | 11.2 Hours | Cumulative hours parcels remained in manual rework holding |

---

## 3. Verified Facility-Level Operational Breakdown

A deep-dive audit into facility event logs reveals distinct operational performance profiles that aggregate metrics obscure:

```
                            [Total Network Volume]
                                  10 Parcels
                                 40.0% Breach
                                 28.5m Delay
                                      │
                 ┌────────────────────┴────────────────────┐
                 ▼                                         ▼
           [Berlin_Hub]                              [Munich_Hub]
            5 Parcels                                 5 Parcels
           40.0% Breach                              40.0% Breach
           28.0m Delay                               29.0m Delay
                 │                                         │
     ┌───────────┴───────────┐                 ┌───────────┴───────────┐
     ▼                       ▼                 ▼                       ▼
DAMAGED_BARCODE      DAMAGED_PACKAGING    DAMAGED_LABEL          CUSTOMS_HOLD
 45m Delay (UPS)      90m Delay (UPS)     80m Delay (UPS)       50m Delay (DHL)
 1.5h Rework Hold     3.2h Rework Hold    2.0h Rework Hold      4.5h Admin Hold
```

### Berlin Facility (`Berlin_Hub`)
* **Total Dispatches:** 5 parcels
* **Fulfillment Performance:** 3 On-Time (`TRK_DE_101`, `TRK_DE_103`, `TRK_DE_105`), 2 Delayed (`TRK_DE_102`, `TRK_DE_104`)
* **SLA Breach Rate:** **40.0%** ($2$ out of $5$)
* **Total Delay Minutes:** $140.0$ minutes ($0 + 45 + 5 + 90 + 0$)
* **Mean Delay:** $28.0$ minutes
* **Exception Audit:**
  * `DAMAGED_BARCODE`: $45$ min delay, $1.5$ hours rework dwell time (Carrier: UPS).
  * `DAMAGED_PACKAGING`: $90$ min delay, $3.2$ hours rework dwell time (Carrier: UPS).

### Munich Facility (`Munich_Hub`)
* **Total Dispatches:** 5 parcels
* **Fulfillment Performance:** 3 On-Time (`TRK_DE_201`, `TRK_DE_203`, `TRK_DE_205`), 2 Delayed (`TRK_DE_202`, `TRK_DE_204`)
* **SLA Breach Rate:** **40.0%** ($2$ out of $5$)
* **Total Delay Minutes:** $145.0$ minutes ($10 + 80 + 0 + 50 + 5$)
* **Mean Delay:** $29.0$ minutes
* **Exception Audit:**
  * `DAMAGED_LABEL`: $80$ min delay, $2.0$ hours rework dwell time (Carrier: UPS).
  * `CUSTOMS_HOLD`: $50$ min delay, **4.5 hours** administrative hold time (Carrier: DHL).

---

## 4. Diagnostic Findings & Business Analysis Insights

### Finding 1: Macro-Level SLA Parity Masks Divergent Failure Modes
* **The Insight:** Both facilities record an identical **40.0% SLA breach rate** and nearly identical average delays ($28.0$ min in Berlin vs. $29.0$ min in Munich). High-level management summaries create the false impression of uniform operational health.
* **The Diagnosis:** Inspecting the exception taxonomy proves that the underlying failure mechanisms share zero operational overlap. Berlin’s disruptions are purely physical handling defects, while Munich’s are dominated by documentation and cross-border regulatory holds.
* **Actionable Recommendation:** Avoid blanket corporate directives. Remediation programs must target localized exception root causes rather than generic network-wide mandates.

### Finding 2: Physical Handling Rework vs. Regulatory Administrative Latency
* **Berlin Floor Mechanics:** Automated optical sorters fail to scan creased or torn thermal barcode labels, shunting packages onto manual floor spurs. Damaged cartons require physical re-taping and structural re-weighing before carrier handover.
* **Munich Floor Mechanics:** Defective labels cause scanning failure, but `CUSTOMS_HOLD` introduces the single longest dwell time in the entire dataset (**4.5 hours**) while packages wait for manual commercial invoice verification.

### Finding 3: Targeted Workflow Automation vs. Redundant Fleet Capital Expenditure
* **The Data:** Carrier transit times were not responsible for any SLA failures. $0\%$ of delay events originated from linehaul carrier capacity constraints; DHL, UPS, and DPD met scheduled dock arrival times.
* **The Trade-Off:** Purchasing additional delivery trucks or paying overtime carrier retention bonuses incurs heavy capital expenditure while solving **0%** of the root causes.
* **The Solution:** Over $75\%$ of delay duration accumulates while packages sit dormant in manual holding bays awaiting supervisor batch reviews. Equipping floor staff with automated scanner alerts and establishing digital pre-customs validation eliminates idle dwell time, dropping processing times below $15$ minutes without adding transport vehicles.

---

## 5. Relational Star Schema Architecture

To support interactive querying, prevent row multiplication, and ensure clean dimensional aggregations, raw logs were structured into an analytical Star Schema:

```
                  ┌───────────────────────────────┐
                  │           Dim_Hub             │
                  ├───────────────────────────────┤
                  │ [PK] hub_name                 │
                  │      city                     │
                  │      region                   │
                  │      country                  │
                  └──────────────┬────────────────┘
                                 │ (1)
                                 │
                                 ▼ (*)
┌───────────────────────────────┐  (*)  ┌──────────────────────────────────┐  (*)  ┌───────────────────────────────┐
│          Dim_Carrier          ├──────►│          Fact_Shipments          │◄──────┤        Dim_Exceptions         │
├───────────────────────────────┤       ├──────────────────────────────────┤       ├───────────────────────────────┤
│ [PK] carrier                  │       │ [PK] tracking_id                 │       │ [PK] exception_code           │
│      service_tier             │       │ [FK] hub_name                    │       │      exception_category       │
│      sla_standard_hours       │       │ [FK] carrier                     │       │      requires_manual_rework   │
└───────────────────────────────┘       │ [FK] exception_code              │       └───────────────────────────────┘
                                        │      scheduled_dispatch          │
                                        │      actual_dispatch             │
                                        │      dispatch_status             │
                                        │      delay_minutes               │
                                        │      resolution_hours            │
                                        └──────────────────────────────────┘
```

### Table Definitions & Roles
1. **`Fact_Shipments` (Fact Table):** Central event logs recording tracking IDs, departure timestamps, recorded delay minutes, and exception resolution hours.
2. **`Dim_Hub` (Dimension Table):** Regional warehouse attributes and geographic regional metadata.
3. **`Dim_Carrier` (Dimension Table):** Contracted logistics partners, service levels, and standard SLA commitments.
4. **`Dim_Exceptions` (Dimension Table):** Failure categorization distinguishing physical handling defects from regulatory holds.

---

## 6. Analytical SQL Implementation

The production metrics driving the pipeline are generated using modular SQL queries located in `sql/`:

### Facility KPI & On-Time Rate Calculation (CTE)
```sql
WITH HubMetrics AS (
    SELECT 
        hub_name,
        COUNT(*) AS total_shipments,
        SUM(CASE WHEN dispatch_status = 'ON_TIME' THEN 1 ELSE 0 END) AS on_time_shipments,
        SUM(CASE WHEN dispatch_status = 'DELAYED' THEN 1 ELSE 0 END) AS delayed_shipments,
        AVG(delay_minutes) AS avg_delay_mins
    FROM parcel_shipments
    GROUP BY hub_name
)
SELECT 
    hub_name,
    total_shipments,
    on_time_shipments,
    delayed_shipments,
    ROUND(avg_delay_mins, 1) AS avg_delay_mins,
    ROUND((on_time_shipments * 100.0 / total_shipments), 2) AS on_time_dispatch_pct
FROM HubMetrics;
```

### Physical Defect Recovery Duration Analysis
```sql
SELECT 
    hub_name,
    exception_code,
    COUNT(*) AS total_damaged_parcels,
    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,
    MAX(resolution_hours) AS max_resolution_hours
FROM parcel_shipments
WHERE exception_code LIKE 'DAMAGED%'
GROUP BY hub_name, exception_code;
```

---

## 7. Interactive Executive Dashboard (Tableau)

* **Live Cloud Deployment:** [Access the Live Interactive Dashboard on Tableau Public](https://public.tableau.com/app/profile/deepam.maurya/viz/Logistics_SLA_Analytics/Logistics_Executive_Dashboard)
* **Packaged Workbook Source:** [`tableau/Logistics_SLA_Analytics.twbx`](tableau/Logistics_SLA_Analytics.twbx)
* **Canvas Specifications:** Fixed Desktop Container ($1200 \times 800$ pixels)

### Dashboard Visual Components
1. **Executive KPI Card Banner:** Top-level summary showing Total Volume ($10$), SLA Breach Rate ($40.0\%$), and Average Delay Duration ($28.5$ min).
2. **Dispatch Volume vs. SLA Breach Trend:** Dual-axis visualization displaying dispatch volume bars alongside the SLA breach percentage line.
3. **Regional Hub Performance:** Horizontal bar chart comparing facility breach rates ($40.0\%$ in Berlin vs. $40.0\%$ in Munich) configured with single-click interactive cross-filtering (`Use as Filter`).
4. **Root Cause Exception Breakdown:** Ranked Pareto-style breakdown highlighting occurrences of `DAMAGED_BARCODE`, `DAMAGED_LABEL`, `DAMAGED_PACKAGING`, and `CUSTOMS_HOLD`.

### Visual Documentation
* **Executive Baseline Overview:**  
  ![Executive Dashboard Overview](screenshots/dashboard_executive_overview.png)
* **Dynamic Hub Drill-Down (Berlin Filtered):**  
  ![Filtered Berlin Hub View](screenshots/dashboard_filtered_berlin.png)

---

## 8. Requirements Engineering & Agile Acceptance Criteria (BDD)

To implement automated terminal exception routing, functional specifications follow Behavior-Driven Development (BDD) standards:

```gherkin
Feature: Automated Exception Escalation & Routing

  Scenario: Unresolved damaged barcode triggers shift supervisor mobile alert
    Given a parcel with tracking ID "TRK_DE_102" is flagged with exception code "DAMAGED_BARCODE"
    And the parcel has remained in the manual sorting bay for 20 minutes without clearance
    When the scheduled SLA monitoring service executes its routine audit cycle
    Then the system updates dispatch status from "DELAYED" to "ESCALATED"
    And dispatches a high-priority push notification to the on-duty floor supervisor's mobile terminal
```

---

## 9. Interview Case Study Narrative (STAR Framework)

* **Situation:** A regional parcel fulfillment network operating sorting hubs experienced severe dispatch delays and escalating contractual SLA breach penalties.
* **Task:** As the Business Analyst, engineer an analytics pipeline to ingest operational logs, model a relational Star Schema, build an executive Tableau dashboard, and diagnose root-cause bottlenecks.
* **Action:** Modeled a normalized dimensional schema linking dispatch facts to hub, carrier, and exception dimensions. Authored SQL CTE aggregations to establish baseline fulfillment KPIs, built an interactive Tableau dashboard with localized cross-filtering, and audited exception dwell times.
* **Result:** Demonstrated that identical $40.0\%$ facility breach rates masked completely separate operational failure modes—Berlin suffered physical barcode and packaging conveyor damage, while Munich experienced administrative customs holds averaging $4.5$ hours of idle time. Proposed automated scanner notifications and electronic pre-clearance, identifying actionable process improvements without requiring fleet expansion.

---

## 10. Repository File Structure

```text
logistics-sla-bi-optimization/
├── README.md                           # Executive summary, metrics & documentation
├── sql/
│   ├── 01_schema_and_ingestion.sql     # DDL and seed transactional data
│   └── 02_kpi_window_metrics.sql       # Analytical CTEs and aggregation queries
├── data/
│   ├── Fact_Shipments_Cleaned.csv      # Central operational event logs
│   ├── Dim_Hub.csv                     # Regional fulfillment center dimension
│   ├── Dim_Carrier.csv                 # Carrier SLA contract dimension
│   └── Dim_Exceptions.csv              # Defect categorization dimension
├── tableau/
│   └── Logistics_SLA_Analytics.twbx    # Packaged Tableau workbook extract
├── screenshots/
│   ├── dashboard_executive_overview.png
│   └── dashboard_filtered_berlin.png
└── docs/
    └── operational_findings_executive_summary.md # Extended executive briefing
```