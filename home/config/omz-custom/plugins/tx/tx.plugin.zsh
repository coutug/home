tx() {
  if [ -z "$1" ]; then
    echo "Usage: tx <total_price>"
    return 1
  fi
  total_price=$1
  initial_price=$(echo "scale=2; $total_price / 1.14975" | bc)
  echo "Initial price: $initial_price"
  echo "Taxes: $(echo "$1 - $initial_price" | bc)"
}

