# 🛠 Support Engineer Toolkit

A hands-on Python toolkit built to automate common support engineering tasks —
API health checks, Linux network diagnostics, and ticket trend analysis.

Built as a learning project during my internship to go deeper on the tools
support engineers use every day.

---

## 📦 What's inside

| Module | What it does |
|---|---|
| `api_health_checker.py` | Checks if a list of API endpoints are UP, SLOW, or DOWN |
| `network_diagnostic.sh` | Runs ip, ping, dig, curl on a host and generates a report |
| `ticket_analyser.py` | Reads a CSV of support tickets and surfaces top error trends |
| `postman/` | Postman collection with automated test scripts for API validation |

---

## 🚀 How to run

### API Health Checker
```bash
pip install requests
python api_health_checker.py
```

### Network Diagnostic
```bash
chmod +x network_diagnostic.sh
./network_diagnostic.sh google.com
```

### Ticket Analyser
```bash
pip install pandas
python ticket_analyser.py --file tickets.csv
```

---

## 🧰 Skills demonstrated

- **Python** — scripting, requests library, pandas, CLI tools
- **REST APIs** — HTTP methods, status codes, response time monitoring
- **Linux networking** — ip, ping, dig, curl, traceroute
- **Postman** — collections, environments, test scripts, Newman CLI
- **Git & GitHub** — version control, documentation, portfolio

---

## 📸 Sample output

```
API Health Check Report
=======================
✅  https://jsonplaceholder.typicode.com/posts   200  |  142ms
⚠️  https://httpbin.org/delay/1                  200  |  1243ms  (SLOW)
❌  https://thisapidoesnotexist.xyz              ERROR  |  Connection refused
```

---

## 📁 Repo structure

```
support-engineer-toolkit/
  api_health_checker.py
  network_diagnostic.sh
  ticket_analyser.py
  tickets_sample.csv
  postman/
    support_toolkit_collection.json
  docs/
    api-health-checker.md
    network-diagnostic.md
    ticket-analyser.md
  README.md
```

---

## 👨‍💻 About this project

I built this during my internship to understand the tools and workflows
support engineers use in real environments. Each module solves a real
problem — checking if APIs are healthy, diagnosing network issues quickly,
and spotting patterns in support ticket data.

---

*Built with Python 3.11 · Tested on Ubuntu 22.04*
