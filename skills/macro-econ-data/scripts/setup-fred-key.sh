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

# Persist the key
echo ""
echo "Where should the key be saved?"
echo "  1) Shell config ($SHELL_RC)"
echo "  2) .env file in current project ($(pwd)/.env)"
echo "  3) Custom file path"
echo "  4) Don't save (current session only)"
echo ""
read -rp "Choose [1-4]: " choice
choice="${choice:-1}"

case "$choice" in
  1)
    if [[ -n "$SHELL_RC" ]]; then
      echo "" >> "$SHELL_RC"
      echo "# FRED API key (macro-econ-data skill)" >> "$SHELL_RC"
      echo "export FRED_API_KEY=\"$key\"" >> "$SHELL_RC"
      echo "Added to $SHELL_RC. Run 'source $SHELL_RC' or open a new terminal."
    else
      echo "Could not detect shell config file. Add manually:"
      echo "  export FRED_API_KEY=\"$key\""
    fi
    ;;
  2)
    env_file="$(pwd)/.env"
    if [[ -f "$env_file" ]] && grep -q "^FRED_API_KEY=" "$env_file"; then
      sed -i '' "s/^FRED_API_KEY=.*/FRED_API_KEY=\"$key\"/" "$env_file"
      echo "Updated FRED_API_KEY in $env_file"
    else
      echo "FRED_API_KEY=\"$key\"" >> "$env_file"
      echo "Added FRED_API_KEY to $env_file"
    fi
    echo "Note: make sure .env is in your .gitignore."
    ;;
  3)
    read -rp "Enter file path: " custom_path
    custom_path="${custom_path/#\~/$HOME}"
    echo "export FRED_API_KEY=\"$key\"" >> "$custom_path"
    echo "Added to $custom_path"
    ;;
  4)
    echo "Key exported for current session only. It will be lost when the shell exits."
    ;;
  *)
    echo "Invalid choice. Key exported for current session only."
    ;;
esac

echo ""
echo "Setup complete. All macro-econ-data endpoints are now available."
