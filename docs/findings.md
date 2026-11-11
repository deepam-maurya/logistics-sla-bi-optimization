# Executive Operational Findings & SLA Bottleneck Analysis

**Project:** Logistics SLA & Dispatch Bottleneck Engine  
**Artifact Stack:** PostgreSQL / SQLiteOnline, Tableau Desktop Public, BPMN 2.0  
**Target Roles:** Junior Business Analyst / Operations Analyst / Process Analyst  

---

## 1. Executive Summary & Baseline Metrics

This analysis evaluates parcel dispatch performance across regional distribution centers (Berlin Hub and Munich Hub) based on shipment event logs structured into a normalized dimensional Star Schema (`Fact_Shipments` joined to `Dim_Hub`, `Dim_Carrier`, and `Dim_Exceptions`).

### Network Baseline (Aggregated View)
* **Total Network Volume:** $10$ parcel dispatches
* **SLA Breach Rate:** $40.0\%$ ($4$ contract breaches out of $10$ total dispatches)
* **On-Time Fulfillment Rate:** $60.0\%$ ($6$ on-time dispatches within operational grace windows)
* **Mean Dispatch Delay (All Dispatches):** $28.5$ minutes
* **Mean Dispatch Delay (Breached Only):** $66.25$ minutes
* **Total Tracked Terminal Delay:** $285.0$ minutes

---

## 2. Core Operational Findings

### Finding 1: Aggregate SLA Parity Masks Divergent Failure Modes
* **Observed Data:** Both **Berlin_Hub** and **Munich_Hub** record an identical **$40.0\%$ SLA breach rate** ($2$ delayed shipments per $5$ dispatches) and comparable average delays ($28.0$ minutes vs. $29.0$ minutes).
* **Analytical Diagnosis:** Macro-level operational metrics create a false assumption of uniform operational health. Relying solely on aggregated executive KPIs obscures the fact that the underlying failure mechanisms at the two facilities are entirely distinct and non-overlapping.
* **Business Takeaway:** Blanket operational policies across an entire logistics network will fail. Remediation initiatives must be targeted to specific station-level exception categories rather than generalized operational mandates.

---

### Finding 2: Physical Handling Defects vs. Regulatory Documentation Latency
Drilling down and cross-filtering the data by facility isolates the operational root causes unique to each hub:

#### Berlin Facility (`Berlin_Hub`): Mechanical & Physical Defects
* **Primary Root Causes:**
  * `DAMAGED_BARCODE`: $45$ min delay ($1.5$ hrs manual inspection hold time)
  * `DAMAGED_PACKAGING`: $90$ min delay ($3.2$ hrs repackaging hold time)
* **Operational Bottleneck:** Conveyor optical sorters fail to scan creased or low-resolution barcodes, diverting parcels to manual holding bays. Crushed or damaged cartons require physical re-taping and structural re-weighing before outbound carrier handover.
* **Impact Area:** Inbound package handling, sorter optical calibration, and packaging supplier material quality.

#### Munich Facility (`Munich_Hub`): Documentation & Compliance Friction
* **Primary Root Causes:**
  * `DAMAGED_LABEL`: $80$ min delay ($2.0$ hrs relabeling hold time)
  * `CUSTOMS_HOLD`: $50$ min delay (**$4.5$ hrs** administrative clearance hold time)
* **Operational Bottleneck:** Defective shipping labels prevent outbound routing scans, while cross-border documentation discrepancies (`CUSTOMS_HOLD`) cause severe idle time while awaiting manual paperwork reconciliation.
* **Impact Area:** Upstream EDI data transmission, automated invoice validation, and international shipping clearance.

---

### Finding 3: Targeted Process Automation vs. Redundant Fleet Capital Expenditure
* **Observed Data:** Carrier transit times were not responsible for SLA breaches; $0\%$ of delivery delays originated from linehaul truck shortages or carrier capacity constraints (DHL, UPS, and DPD departed on time when handed freight).
* **Cost-Benefit Evaluation:**
  * Expanding carrier fleets or paying contracted carrier overtime premiums would incur substantial capital expenditure while solving **$0\%$** of fulfillment bottlenecks.
  * Over **$75\%$** of delay time accumulates while shipments sit idle in physical holding lanes awaiting manual supervisor batch audits.
* **Remediation Strategy:** 
  * Implementing automated barcode re-scan loops and pushing instant exception notifications to handheld mobile terminals reduces floor dwell time from hours to under $15$ minutes.
  * Pre-validating customs paperwork via digital EDI integration clears regulatory holds prior to physical sorting dock arrival.

---

## 3. Data Architecture Summary (Star Schema)

The analytical queries and visual dashboard operate on a normalized dimensional Star Schema:

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

---

## 4. Interview Talking Points (STAR Method)

Use this narrative framework during case study interviews and technical screening rounds:

### Situation
> *"In a multi-hub retail distribution network, operations faced rising SLA breach penalties and customer complaints caused by dispatch delays at regional sorting centers."*

### Task
> *"As the Business Analyst, my objective was to ingest dispatch logs, construct an analytical star schema, build an interactive executive dashboard, and identify the root causes driving fulfillment delays."*

### Action
> *"I built a dimensional model linking dispatch events to hub, carrier, and exception dimensions. In Tableau, I authored KPI measures for SLA breach rates and delay duration, set up cross-filtering across hubs, and isolated failure categories. When high-level metrics showed an identical 40% breach rate across both facilities, I performed a root-cause breakdown to analyze the underlying exception data."*

### Result
> *"I demonstrated that Berlin's bottlenecks were 100% physical conveyor and packaging defects, whereas Munich's were caused by customs documentation holds averaging 4.5 hours of idle time. I proposed targeted process automations—automated scanner alerts and digital EDI pre-clearance—preventing unnecessary transportation fleet spend and modeling an estimated 30%+ reduction in sorting floor lead times."*

---

## 5. Core Business Analysis Concepts Reference

| BA Concept | Category | Application in This Project |
| :--- | :--- | :--- |
| **As-Is Process Analysis** | Process Modeling | Documenting the current manual sorting floor rework bays and unmonitored holding cages. |
| **To-Be Process Design** | Process Re-engineering | Specifying automated optical re-scans and real-time mobile push notifications to floor technicians. |
| **Cycle & Lead Time Analysis** | Performance Metrics | Tracking parcel dwell time, delay minutes, and manual exception resolution hours. |
| **Bottleneck Analysis** | Operations Analysis | Isolating unreadable barcodes and administrative customs holds as throughput constraints. |
| **Root Cause Analysis (RCA)** | Problem Solving | Decomposing the aggregate 40% SLA breach rate into distinct station-level defect types. |
| **Business Requirements (BRD)** | Requirements Engineering | Outlining the operational objectives and financial impact of reducing sorting delay penalties. |
| **Product Specifications (PRD)** | Agile Product Delivery | Defining functional requirements, scanner data contracts, and mobile app notification behavior. |
| **Acceptance Criteria (BDD / Gherkin)** | Quality Assurance | Writing testable `Given-When-Then` criteria for automated exception ticket routing. |

---

## 6. Portfolio & Repository Asset Directory

* **Packaged Analytics Workbook:** `tableau/Logistics_SLA_Analytics.twbx`
* **Live Dashboard URL:** `https://public.tableau.com/app/profile/<your_profile>/viz/LogisticsSLA...`
* **Executive Overview Screenshot:** `screenshots/dashboard_executive_overview.png`
* **Filtered Interaction Screenshot:** `screenshots/dashboard_filtered_berlin.png`
* **Relational Data Files:** `data/Fact_Shipments_Cleaned.csv`, `data/Dim_Hub.csv`, `data/Dim_Carrier.csv`, `data/Dim_Exceptions.csv`