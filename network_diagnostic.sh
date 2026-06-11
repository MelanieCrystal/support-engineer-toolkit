#!/bin/bash

# ============================================================
# Support Engineer Toolkit — Network Diagnostic Script
# ============================================================
# What it does:
#   Runs key Linux networking commands on a given host and
#   prints a structured diagnostic report — the kind you'd
#   run at the start of any support ticket.
#
# How to run:
#   chmod +x network_diagnostic.sh
#   ./network_diagnostic.sh google.com
#
# What it checks:
#   1. Ping        — is the host reachable? what's the latency?
#   2. DNS lookup  — what IP does this domain resolve to?
#   3. Traceroute  — how many hops to reach it? where is it slow?
#   4. curl        — does the HTTP/HTTPS endpoint respond?
#   5. Port check  — is a specific port open?
# ============================================================


# --- Colours ---
GREEN="\033[92m"
YELLOW="\033[93m"
RED="\033[91m"
CYAN="\033[96m"
BOLD="\033[1m"
RESET="\033[0m"

# --- The host to diagnose (passed as argument) ---
HOST=$1

# If no host was given, show usage instructions
if [ -z "$HOST" ]; then
  echo ""
  echo "  Usage: ./network_diagnostic.sh <hostname or IP>"
  echo "  Example: ./network_diagnostic.sh google.com"
  echo ""
  exit 1
fi

# --- Helper: print a section header ---
section() {
  echo ""
  echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}${BOLD}  $1${RESET}"
  echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

# --- Helper: print a result line ---
result() {
  echo -e "  ${GREEN}▶${RESET} $1"
}

# --- Helper: print a warning line ---
warn() {
  echo -e "  ${YELLOW}⚠️  $1${RESET}"
}

# --- Helper: print an error line ---
fail() {
  echo -e "  ${RED}❌ $1${RESET}"
}


# ============================================================
# REPORT HEADER
# ============================================================
echo ""
echo -e "${BOLD}============================================================${RESET}"
echo -e "${BOLD}  🛠  SUPPORT ENGINEER TOOLKIT — Network Diagnostic Report${RESET}"
echo -e "${BOLD}============================================================${RESET}"
echo -e "  Host      : ${CYAN}$HOST${RESET}"
echo -e "  Timestamp : $(date)"
echo -e "  Machine   : $(hostname)"


# ============================================================
# 1. PING CHECK
# Is the host reachable? What is the round-trip latency?
# ============================================================
section "1 — PING CHECK (is the host reachable?)"

# Send 4 ping packets and capture the output
PING_OUTPUT=$(ping -c 4 "$HOST" 2>&1)
PING_EXIT=$?

if [ $PING_EXIT -eq 0 ]; then
  # Extract the average latency from the ping summary line
  AVG_LATENCY=$(echo "$PING_OUTPUT" | grep -oP 'avg = \K[0-9.]+' 2>/dev/null || \
                echo "$PING_OUTPUT" | grep -oP 'min/avg/max.*= [0-9.]+/\K[0-9.]+')
  result "Host is reachable ✅"
  result "Average latency: ${AVG_LATENCY}ms"

  # Warn if latency is high (over 100ms)
  if [ ! -z "$AVG_LATENCY" ] && (( $(echo "$AVG_LATENCY > 100" | bc -l 2>/dev/null) )); then
    warn "Latency is above 100ms — could indicate geographic distance or network congestion"
  fi

  echo ""
  echo "$PING_OUTPUT"
else
  fail "Host is NOT reachable via ping"
  warn "This could mean: host is down, ICMP is blocked by firewall, or wrong hostname"
fi


# ============================================================
# 2. DNS LOOKUP
# What IP address does this domain resolve to?
# ============================================================
section "2 — DNS LOOKUP (what IP does this domain resolve to?)"

# Check if dig is available
if command -v dig &> /dev/null; then
  DNS_RESULT=$(dig +short "$HOST" 2>&1)
  if [ -z "$DNS_RESULT" ]; then
    fail "DNS lookup returned no result — domain may not exist or DNS is misconfigured"
  else
    result "DNS resolved successfully ✅"
    result "IP address(es): $DNS_RESULT"
    echo ""
    echo "  Full dig output:"
    dig "$HOST"
  fi
else
  # Fall back to nslookup if dig is not installed
  warn "dig not found — using nslookup instead"
  nslookup "$HOST"
fi


# ============================================================
# 3. TRACEROUTE
# How many hops to reach the host? Where does it slow down?
# ============================================================
section "3 — TRACEROUTE (path to the host)"
warn "This may take up to 30 seconds..."

# Use traceroute if available, otherwise tracepath
if command -v traceroute &> /dev/null; then
  traceroute -m 15 "$HOST" 2>&1
elif command -v tracepath &> /dev/null; then
  tracepath "$HOST" 2>&1
else
  fail "Neither traceroute nor tracepath is installed"
  warn "Install with: sudo apt install traceroute"
fi


# ============================================================
# 4. HTTP CHECK WITH CURL
# Does the host respond over HTTP/HTTPS?
# What are the response headers?
# ============================================================
section "4 — HTTP CHECK (curl response)"

# curl -s = silent (no progress bar)
# curl -o /dev/null = discard body, we only want headers + timing
# curl -w = write out custom format with timing breakdown
CURL_OUTPUT=$(curl -s -o /dev/null -w "\
  HTTP Status     : %{http_code}\n\
  DNS Lookup      : %{time_namelookup}s\n\
  TCP Connect     : %{time_connect}s\n\
  TLS Handshake   : %{time_appconnect}s\n\
  Time to 1st byte: %{time_starttransfer}s\n\
  Total Time      : %{time_total}s\n\
  Final URL       : %{url_effective}\n" \
  --connect-timeout 5 "https://$HOST" 2>&1)

CURL_EXIT=$?

if [ $CURL_EXIT -eq 0 ]; then
  result "curl succeeded ✅"
  echo ""
  echo "$CURL_OUTPUT"
else
  fail "curl failed (exit code $CURL_EXIT)"
  warn "Trying plain HTTP instead of HTTPS..."
  curl -v --connect-timeout 5 "http://$HOST" 2>&1 | head -30
fi


# ============================================================
# 5. PORT CHECK
# Is port 80 (HTTP) and 443 (HTTPS) open?
# ============================================================
section "5 — PORT CHECK (is HTTP/HTTPS port open?)"

check_port() {
  local port=$1
  # Use timeout + bash TCP redirect to check if port is open
  # /dev/tcp is a bash built-in — no extra tools needed
  if timeout 3 bash -c "echo >/dev/tcp/$HOST/$port" 2>/dev/null; then
    result "Port $port is OPEN ✅"
  else
    fail "Port $port is CLOSED or filtered"
  fi
}

check_port 80
check_port 443


# ============================================================
# REPORT FOOTER
# ============================================================
echo ""
echo -e "${BOLD}============================================================${RESET}"
echo -e "${BOLD}  Report complete.${RESET}"
echo -e "  ${YELLOW}Tip: Save this output with:${RESET}"
echo -e "  ${CYAN}./network_diagnostic.sh $HOST > report_$HOST.txt${RESET}"
echo -e "${BOLD}============================================================${RESET}"
echo ""
