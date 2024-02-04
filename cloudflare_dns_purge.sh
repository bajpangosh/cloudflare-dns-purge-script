#!/bin/bash

# Cloudflare API Token and Zone ID
API_TOKEN="YOUR_CLOUDFLARE_API_TOKEN"
ZONE_ID="YOUR_CLOUDFLARE_ZONE_ID"

# Display current DNS records
echo "Current DNS records:"
DNS_RECORDS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records" \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Content-Type: application/json")

# Check if there was an error in fetching DNS records
if [ "$(echo "$DNS_RECORDS" | jq -r '.success')" != "true" ]; then
    ERROR_MESSAGE=$(echo "$DNS_RECORDS" | jq -r '.errors[0].message')
    echo "Error fetching DNS records: $ERROR_MESSAGE"
    exit 1
fi

# Check if there are any records to display
RECORD_COUNT=$(echo "$DNS_RECORDS" | jq -r '.result | length')
if [ "$RECORD_COUNT" -eq 0 ]; then
    echo "No DNS records found for the specified zone."
    exit 1
fi

# Display DNS records
echo "$DNS_RECORDS" | jq -r '.result[] | "\(.id) - \(.name) - \(.type)"'

# User confirmation
read -p "Are you sure you want to delete all DNS records for the selected domain? (yes/no): " confirmation
if [ "$confirmation" != "yes" ]; then
    echo "Operation canceled."
    exit 1
fi

# Deleting DNS records
DELETED_RECORDS=()
for ID in $(echo "$DNS_RECORDS" | jq -r '.result[].id'); do
    DELETE_RESPONSE=$(curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/${ZONE_ID}/dns_records/${ID}" \
        -H "Authorization: Bearer ${API_TOKEN}" \
        -H "Content-Type: application/json")
    DELETED_RECORDS+=("$ID - $DELETE_RESPONSE")
done

# Display deleted DNS records
echo "Deleted DNS records:"
for ENTRY in "${DELETED_RECORDS[@]}"; do
    echo "$ENTRY"
done

echo "Total number of DNS records deleted: ${#DELETED_RECORDS[@]}"
