import requests
import time

# ============================================================
# Support Engineer Toolkit — API Health Checker
# ============================================================
# What it does:
#   Checks a list of API endpoints and reports whether each
#   one is UP, SLOW, or DOWN — with response time in ms.
#
# How to run:
#   python api_health_checker.py
# ============================================================

# --- Colour codes for terminal output ---
GREEN  = "\033[92m"   # ✅ UP
YELLOW = "\033[93m"   # ⚠️  SLOW
RED    = "\033[91m"   # ❌ DOWN
RESET  = "\033[0m"    # back to normal colour

# --- How slow is "slow"? (in milliseconds) ---
SLOW_THRESHOLD_MS = 500

# --- The list of APIs to check ---
# Add or remove any URLs you want to test
ENDPOINTS = [
    "https://jsonplaceholder.typicode.com/posts",
    "https://jsonplaceholder.typicode.com/users",
    "https://httpbin.org/get",
    "https://httpbin.org/delay/1",       # this one is intentionally slow
    "https://httpbin.org/status/404",    # this one returns a 404
    "https://this-api-does-not-exist.xyz",  # this one will fail completely
]


def check_endpoint(url):
    """
    Sends a GET request to the given URL.
    Returns a dict with: url, status_code, response_time_ms, result
    result can be: "UP", "SLOW", "DOWN", or "ERROR"
    """
    try:
        start_time = time.time()                        # record start time
        response = requests.get(url, timeout=5)         # send the request (5s timeout)
        end_time = time.time()                          # record end time

        response_time_ms = (end_time - start_time) * 1000  # convert to milliseconds

        # Decide if it's UP, SLOW, or a bad status code
        if response.status_code == 200 and response_time_ms < SLOW_THRESHOLD_MS:
            result = "UP"
        elif response.status_code == 200 and response_time_ms >= SLOW_THRESHOLD_MS:
            result = "SLOW"
        else:
            result = f"DOWN (HTTP {response.status_code})"

        return {
            "url": url,
            "status_code": response.status_code,
            "response_time_ms": round(response_time_ms),
            "result": result
        }

    except requests.exceptions.ConnectionError:
        # The server couldn't be reached at all
        return {"url": url, "status_code": None, "response_time_ms": None, "result": "ERROR — Connection refused"}

    except requests.exceptions.Timeout:
        # The request took too long
        return {"url": url, "status_code": None, "response_time_ms": None, "result": "ERROR — Timed out"}

    except Exception as e:
        # Catch anything else unexpected
        return {"url": url, "status_code": None, "response_time_ms": None, "result": f"ERROR — {str(e)}"}


def print_report(results):
    """
    Prints a clean, colour-coded report to the terminal.
    """
    print("\n" + "=" * 65)
    print("  🛠  SUPPORT ENGINEER TOOLKIT — API Health Check Report")
    print("=" * 65)

    for r in results:
        result = r["result"]
        url    = r["url"]
        time_ms = f'{r["response_time_ms"]}ms' if r["response_time_ms"] else "—"

        if result == "UP":
            icon  = "✅"
            color = GREEN
        elif result == "SLOW":
            icon  = "⚠️ "
            color = YELLOW
        else:
            icon  = "❌"
            color = RED

        # Print: icon | url | response time | result
        print(f"{icon}  {color}{url:<50}{RESET}  {time_ms:<10}  {color}{result}{RESET}")

    print("=" * 65)

    # Summary line
    up    = sum(1 for r in results if r["result"] == "UP")
    slow  = sum(1 for r in results if r["result"] == "SLOW")
    down  = len(results) - up - slow

    print(f"\n  Summary:  {GREEN}{up} UP{RESET}  |  {YELLOW}{slow} SLOW{RESET}  |  {RED}{down} DOWN/ERROR{RESET}")
    print()


def main():
    print(f"\nChecking {len(ENDPOINTS)} endpoints...\n")

    results = []
    for url in ENDPOINTS:
        print(f"  Checking {url} ...")
        result = check_endpoint(url)
        results.append(result)

    print_report(results)


if __name__ == "__main__":
    main()
