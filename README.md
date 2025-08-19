# Planning Optimization in Agro-Industrial Supply Chain  
## An S&OP Proposal for the Animal Feed Sector

**Conference:** XLV ENCONTRO NACIONAL DE ENGENHARIA DE PRODUÇÃO – *Produção inteligente para um futuro renovável*  
**Location & Date:** Natal, Rio Grande do Norte, Brazil — October 14–17, 2025

### Authors
- **Mayara Guedes Leão** (Universidade Federal de Minas Gerais)  
- **Thaís Madeira da Silva** (Universidade Federal de Minas Gerais)  
- **João Flávio de Freitas Almeida** (Universidade Federal de Minas Gerais)

---

## 1. Background & Objectives

This research presents the development and implementation of a mathematical model for **Sales & Operations Planning (S&OP)** tailored for a two-month horizon in the **animal feed industry**. The main goals include:

- Addressing **demand variability**, **raw material price fluctuations**, and **operational constraints**.
- Modeling industry specifics such as **seasonal supply**, **perishable inputs**, and **high product diversity**.
- Generating optimized plans across **production**, **purchasing**, **transportation**, and **inventory** domains using **linear programming** with the **GLPK solver**.
- Analyzing three scenarios: base case with aggregated data, high-demand case, and raw material price variation.
- Demonstrating faster, automated planning, structured decision-making, and profitability insights versus traditional spreadsheet methods.
- Pointing toward future advances via greater model disaggregation and integration of real company data.

---

## 2. Repository Overview

This repository contains model files and data used in support of the paper:

- **`snp6.mod`** – GLPK model definition file.
- **`snp6.dat`** – Associated data file used by the model.
- **`README.md`** – (This document).
- **GLPK output files**:  
  - `01-Glpk-finaceiro.txt`  
  - `03-Glpk-producao.txt`  
  - `04-Glpk-estoque.txt`  
  - `05-Glpk-materiaPrima.txt`  
  - `06-Glpk-entrega.txt`  
  - `07-Glpk-naoEntrega.txt`  
  - `08-Glpk-consumoProducao.txt`  
  - `09-Glpk-capacidade.txt`  
  - `10-Glpk-capacidadeExtra.txt`  
  - `11-Glpk-transporte.txt`  
  - `12-Glpk-transporteModal.txt`

These outputs represent results from key dimensions: financials, production, stock, raw materials, deliveries, exceptions, consumption, capacities, extra capacity, transport, and transportation modes.

---

## 3. Getting Started

### Prerequisites
- **GLPK** (GNU Linear Programming Kit) installed on your system.
- Compatible environment to run GLPK (via command line or integrated development environment).

### Running the Model
Clone the repository:
```bash
git clone https://github.com/joaoflavioufmg/SOP-racao.git
cd SOP-racao
````

Run the optimization:

```bash
glpsol --model snp6.mod --data snp6.dat --cuts --tmlim 3600
```

Note: this generates results similar to the provided `.txt` files. 

---

## 4. Repository Structure

```
SOP-racao/
├── README.md                   # Project overview (this file)
├── snp6.mod                    # GLPK model file
├── snp6.dat                    # Input data file
├── 01-Glpk-finaceiro.txt       # Financial outputs
├── 03-Glpk-producao.txt        # Production results
├── 04-Glpk-estoque.txt         # Inventory outputs
├── 05-Glpk-materiaPrima.txt    # Raw material planning
├── 06-Glpk-entrega.txt         # Delivery plan
├── 07-Glpk-naoEntrega.txt      # Undelivered items
├── 08-Glpk-consumoProducao.txt # Consumption vs production
├── 09-Glpk-capacidade.txt      # Capacity utilization
├── 10-Glpk-capacidadeExtra.txt # Extra capacity usage
├── 11-Glpk-transporte.txt      # Transport flows
└── 12-Glpk-transporteModal.txt # Transportation modes breakdown
```

---

## 5. How to Interpret the Output Files

Each `.txt` file contains structured results from the model. For instance:

* **Financial outputs**: depict cost breakdowns and financial performance.
* **Production and inventory**: show scheduled outputs and inventory levels over time.
* **Raw materials & transport**: quantify procurement needs and logistics allocations.
* **Capacity & exception reports**: highlight resource constraints and unmet demand.

To convert these into visuals or tables, consider importing them into tools like Excel, Python (e.g. `pandas`), or R.

---

## 6. Future Work & Extensions

Possible extensions include:

* **Higher disaggregation**: modeling by product type, time period, or detailed supply nodes.
* **Real-world company data**: to validate and calibrate model output.
* **Enhanced modeling**: incorporate stochastic demands, multi-period rolling horizons, or integrated cost-service tradeoffs.
* **Automation & pipeline integration**: linking data ingestion, model run, and reporting in seamless workflows.

---

## 7. Contact & Acknowledgments

**Authors & Affiliation:** 
João Flávio F. Almeida (PPGEP-UFMG) Universidade Federal de Minas Gerais (UFMG).
Mayara Guedes Leão: (DEP-UFMG) Universidade Federal de Minas Gerais (UFMG).
Thais Madeira da Silva: (DEP-UFMG) Universidade Federal de Minas Gerais (UFMG).

**Acknowledgments:** Support of UFMG, CAPES, and an the team of the animal feed industry for enabling S&OP modeling and data collection.
*---

---

## 9. References & Citation

If you use or reference this work, please cite it as follows:

> Leão, M. G., da Silva, T. M., & de Freitas Almeida, J. F. (2025). Planning Optimization in Agro-Industrial Supply Chain: An S\&OP Proposal for the Animal Feed Sector. XLV ENEGEP—Produção inteligente para um futuro renovável. Natal, Rio Grande do Norte, October 14–17, 2025.

---


