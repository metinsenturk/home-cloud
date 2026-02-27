#!/usr/bin/env python3
"""
Database seeding script for Datasette example database.
Creates sample tables with data to demonstrate Datasette functionality.
Also downloads popular sample SQLite databases.
"""
import sqlite3
import sys
from pathlib import Path
from urllib.request import urlretrieve
from urllib.error import URLError


# Sample databases to download
SAMPLE_DATABASES = [
    {
        "name": "chinook.db",
        "url": "https://github.com/lerocha/chinook-database/raw/master/ChinookDatabase/DataSources/Chinook_Sqlite.sqlite",
        "description": "Music store database with artists, albums, tracks, and sales"
    },
    {
        "name": "northwind.db",
        "url": "https://raw.githubusercontent.com/jpwhite3/northwind-SQLite3/main/dist/northwind.db",
        "description": "Classic sales database with customers, orders, and products"
    },
    {
        "name": "fixtures.db",
        "url": "https://latest.datasette.io/fixtures.db",
        "description": "Datasette's official test database with various data types"
    }
]


def download_database(name, url, description, target_dir):
    """
    Download a SQLite database from a URL.
    
    Args:
        name: The filename to save as
        url: The URL to download from
        description: Description of the database
        target_dir: Directory to save the file in
    
    Returns:
        bool: True if successful, False otherwise
    """
    target_path = target_dir / name
    
    # Skip if already exists
    if target_path.exists():
        print(f"  ⊙ {name} already exists, skipping...")
        return True
    
    print(f"  → Downloading {name}...")
    print(f"    {description}")
    
    try:
        urlretrieve(url, target_path)
        file_size = target_path.stat().st_size / (1024 * 1024)  # Convert to MB
        print(f"    ✓ Downloaded {name} ({file_size:.2f} MB)")
        return True
    except URLError as e:
        print(f"    ✗ Failed to download {name}: {e}")
        return False
    except Exception as e:
        print(f"    ✗ Unexpected error downloading {name}: {e}")
        return False


def create_example_database(target_dir):
    """Create and populate the example database."""
    db_path = target_dir / "example.db"
    
    print(f"Creating database at {db_path}...")
    
    # Connect to database (creates if doesn't exist)
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Create people table
        print("Creating 'people' table...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS people (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                role TEXT NOT NULL,
                city TEXT NOT NULL
            )
        """)
        
        # Create projects table with foreign key
        print("Creating 'projects' table...")
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS projects (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                status TEXT NOT NULL,
                owner_id INTEGER NOT NULL,
                FOREIGN KEY(owner_id) REFERENCES people(id)
            )
        """)
        
        # Insert sample people
        print("Inserting sample data into 'people'...")
        people_data = [
            ('Ada Lovelace', 'Analyst', 'London'),
            ('Grace Hopper', 'Engineer', 'New York'),
            ('Linus Torvalds', 'Maintainer', 'Helsinki')
        ]
        cursor.executemany(
            "INSERT INTO people (name, role, city) VALUES (?, ?, ?)",
            people_data
        )
        
        # Insert sample projects
        print("Inserting sample data into 'projects'...")
        projects_data = [
            ('Query Explorer', 'active', 1),
            ('API Catalog', 'planning', 2),
            ('SQLite Metrics', 'active', 3)
        ]
        cursor.executemany(
            "INSERT INTO projects (name, status, owner_id) VALUES (?, ?, ?)",
            projects_data
        )
        
        # Commit changes
        conn.commit()
        
        # Verify creation
        cursor.execute("SELECT COUNT(*) FROM people")
        people_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM projects")
        projects_count = cursor.fetchone()[0]
        
        print(f"  ✓ example.db created successfully!")
        print(f"    - People: {people_count} rows")
        print(f"    - Projects: {projects_count} rows")
        return True
        
    except sqlite3.Error as e:
        print(f"  ✗ Database error: {e}", file=sys.stderr)
        return False
    finally:
        conn.close()


def main():
    """Main function to create example database and download sample databases."""
    data_dir = Path("/data")
    
    print("════════════════════════════════════════════════")
    print("  Datasette Database Setup")
    print("════════════════════════════════════════════════")
    print()
    
    # Create example database
    print("→ Creating example database...")
    example_success = create_example_database(data_dir)
    print()
    
    # Download sample databases
    print("→ Downloading sample databases...")
    download_results = []
    for db in SAMPLE_DATABASES:
        success = download_database(
            name=db["name"],
            url=db["url"],
            description=db["description"],
            target_dir=data_dir
        )
        download_results.append(success)
    
    print()
    print("════════════════════════════════════════════════")
    print("  Summary")
    print("════════════════════════════════════════════════")
    
    # Count successes
    total_downloads = len(SAMPLE_DATABASES)
    successful_downloads = sum(download_results)
    
    if example_success:
        print("  ✓ example.db: Created")
    else:
        print("  ✗ example.db: Failed")
    
    print(f"  ✓ Sample databases: {successful_downloads}/{total_downloads} downloaded")
    print()
    print("Available databases:")
    print("  - http://datasette.${DOMAIN}/example")
    
    for db in SAMPLE_DATABASES:
        db_name = db["name"].replace(".db", "")
        print(f"  - http://datasette.${{DOMAIN}}/{db_name}")
    
    print()
    
    # Return success if at least example.db was created
    return 0 if example_success else 1


if __name__ == "__main__":
    sys.exit(main())
