#!/bin/bash
# Database seeding script for Datasette
# Executes the Python seeding script inside the datasette container

set -e  # Exit on error

CONTAINER_NAME="datasette"
SCRIPT_NAME="seed_database.py"

echo "════════════════════════════════════════════════"
echo "  Datasette Database Seeding"
echo "════════════════════════════════════════════════"
echo

# Check if container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "✗ Error: Container '${CONTAINER_NAME}' is not running"
    echo "  Run 'make up-datasette' first"
    exit 1
fi

echo "→ Container '${CONTAINER_NAME}' is running"
echo

# Copy Python script to container
echo "→ Copying seed script to container..."
docker cp "${SCRIPT_NAME}" "${CONTAINER_NAME}:/tmp/${SCRIPT_NAME}"

# Execute the script inside the container
echo "→ Executing seed script..."
echo
docker exec "${CONTAINER_NAME}" python3 "/tmp/${SCRIPT_NAME}"

# Clean up
echo
echo "→ Cleaning up temporary files..."
docker exec "${CONTAINER_NAME}" rm -f "/tmp/${SCRIPT_NAME}"

echo
echo "════════════════════════════════════════════════"
echo "  ✓ Seeding Complete"
echo "════════════════════════════════════════════════"
echo
echo "Access your database at: http://datasette.\${DOMAIN}/example"
echo
