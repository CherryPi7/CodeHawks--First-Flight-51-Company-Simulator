[![CodeHawks First Flight](https://img.shields.io/badge/CodeHawks-First_Flight_51-8A2BE2?style=for-the-badge&logo=hawk&logoColor=white)](https://codehawks.cyfrin.io/)

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

