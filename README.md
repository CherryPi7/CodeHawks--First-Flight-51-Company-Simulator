
  <img src="https://img.shields.io/badge/CodeHawks-First_Flight_51-8A2BE2?style=for-the-badge&logo=hawk&logoColor=white" alt="CodeHawks Badge"/>
  <img src="https://img.shields.io/badge/Vyper-1.4.0-4B8BBE?style=for-the-badge&logo=ethereum&logoColor=white" alt="Vyper"/>
  <img src="https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white" alt="Python"/>
  <img src="https://img.shields.io/badge/Boa-Testing_Framework-FFB000?style=for-the-badge&logo=pytest&logoColor=white" alt="Boa Testing"/>
  <img src="https://img.shields.io/badge/Status-Verified_Secure-2ecc71?style=for-the-badge&logo=shield&logoColor=white" alt="Status"/>
</p>



# 🪶 CodeHawks — Company Simulator (PoC)

**Audit Type:** CodeHawks First Flight #51  
**Finding:** Dust investment mints 0 shares  
**Severity:** Medium (Funds permanently lost via donation)  
**Fix:** Add `assert desired > 0` + refund logic  

---

- 📂 **PoCs:** `tests/poc/`  
- 🧩 **Finding:** Dust ETH accepted, 0 shares minted → silent donation  
- 🧠 **Mitigation:** Guard check + refund remainder  
- 📜 **Auditor:** [@CherryPi7](https://github.com/CherryPi7)
- 🐦 **Contest:** [CodeHawks – Company Simulator](https://codehawks.cyfrin.io/c/first-flight-51)

