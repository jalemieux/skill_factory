#!/usr/bin/env bash
# Setup FRED API key for macro-econ-data skill
# FRED is free — sign up at https://fred.stlouisfed.org/docs/api/api_key.html
set -euo pipefail

SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
  SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
  SHELL_RC="$HOME/.bashrc"
elif [[ -f "$HOME/.bash_profile" ]]; then
  SHELL_RC="$HOME/.bash_profile"
fi

# Check if already set
if [[ -n "${FRED_API_KEY:-}" ]]; then
  echo "FRED_API_KEY is already set: ${FRED_API_KEY:0:4}...${FRED_API_KEY: -4}"
  echo "To verify it works:"
  echo "  curl -s \"https://api.stlouisfed.org/fred/series?series_id=PCEPI&api_key=\$FRED_API_KEY&file_type=json\" | head -c 200"
  exit 0
fi

# Prompt for key
echo "=== FRED API Key Setup ==="
echo ""
echo "PCE (Personal Consumption Expenditures) data requires a free FRED API key."
echo ""
echo "Steps:"
echo "  1. Go to https://fredaccount.stlouisfed.org/apikeys"
echo "  2. Create an account (or log in)"
echo "  3. Request an API key"
echo "  4. Paste it below"
echo ""
read -rp "Enter your FRED API key: " key

if [[ -z "$key" ]]; then
  echo "No key entered. Exiting."
  exit 1
fi

# Validate the key
echo "Validating key..."
response=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://api.stlouisfed.org/fred/series?series_id=PCEPI&api_key=${key}&file_type=json")

if [[ "$response" != "200" ]]; then
  echo "Key validation failed (HTTP $response). Check your key and try again."
  exit 1
fi

echo "Key is valid."

# Export for current session
export FRED_API_KEY="$key"
echo "Exported FRED_API_KEY for current session."

# Persist to shell config
if [[ -n "$SHELL_RC" ]]; then
  read -rp "Add to $SHELL_RC for future sessions? [Y/n] " persist
  persist="${persist:-Y}"
  if [[ "$persist" =~ ^[Yy] ]]; then
    echo "" >> "$SHELL_RC"
    echo "# FRED API key (macro-econ-data skill)" >> "$SHELL_RC"
    echo "export FRED_API_KEY=\"$key\"" >> "$SHELL_RC"
    echo "Added to $SHELL_RC. Run 'source $SHELL_RC' or open a new terminal."
  fi
else
  echo "Could not detect shell config file. Add this to your shell profile manually:"
  echo "  export FRED_API_KEY=\"$key\""
fi

echo ""
echo "Setup complete. All macro-econ-data endpoints are now available."
