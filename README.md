# 🧠 Adaptive Data Width FIFO for SoC Modules

## 📘 Overview
This project implements an **Adaptive Data Width FIFO (First-In-First-Out) buffer** for **System-on-Chip (SoC)** communication modules.  
Traditional FIFO designs are fixed in data width, leading to inefficient utilization of bandwidth and resources when modules of different bus widths interact.  

This adaptive FIFO automatically adjusts its **data width (8-bit to 32-bit)** based on the connected module interface, improving **throughput** and **resource utilization** while maintaining **functional correctness** and **timing closure**.

---

## ⚙️ Key Features
- ✅ **Adaptive Data Width Conversion** — Dynamically supports 8-bit, 16-bit, and 32-bit SoC interfaces.  
- ✅ **Configurable Depth** — FIFO depth can be modified via parameters for different dataflow requirements.  
- ✅ **Power Optimization** — Includes optional **clock gating / enable logic** for dynamic power saving during idle cycles.  
- ✅ **FIFO Status Registers** — Live depth monitoring via occupancy counter or status flag register.  
- ✅ **Throughput Enhancement (~25%)** — Verified improvement through RTL simulation and waveform analysis.  
- ✅ **Error Detection** — Parity checking logic for data integrity.  
- ✅ **AXI-Stream Compatible Interface** — Can be integrated with standard AXI-Stream modules for SoC verification setups.  

---
