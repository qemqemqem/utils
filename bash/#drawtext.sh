#!/bin/bash

QUERY="$1"

# echo "Search term: $QUERY"

# Fetch the image URLs from the Google Custom Search JSON API
# echo "https://www.googleapis.com/customsearch/v1?q=$QUERY&key=$API_KEY&cx=$CX&searchType=image"
ENCODED_QUERY=$(urlencode "$QUERY")
RESULTS=$(curl -s "https://www.googleapis.com/customsearch/v1?q=$ENCODED_QUERY&key=$API_KEY&cx=$CX&searchType=image")

# Check if results were fetched successfully
if [ -z "$RESULTS" ]; then
    echo "$RESULTS"
    ERROR_MESSAGE=$(echo "$RESULTS" | jq -r '.error.message')
    ERROR_CODE=$(echo "$RESULTS" | jq -r '.error.code')
    echo "Error from Google Custom Search (Code $ERROR_CODE): $ERROR_MESSAGE"
    exit 1
fi

# Extract the first image URL ending in ".png" or ".jpg"
IMAGE_URL=$(echo "$RESULTS" | grep -oP 'https://[^"]+\.(png|jpg)' | head -1)

if [ -z "$IMAGE_URL" ]; then
    echo "No suitable image found."
    exit 1
fi

# Display the image in the terminal
curl -s "$IMAGE_URL" | catimg -
