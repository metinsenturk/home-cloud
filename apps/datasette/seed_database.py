#!/usr/bin/env python3
"""
Database seeding script for Datasette example database.
Creates sample tables with data to demonstrate Datasette functionality.
"""
import sqlite3
import sys
from pathlib import Path


def create_database():
    """Create and populate the example database."""
    db_path = Path("/data/example.db")
    
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
        
        print(f"✓ Database created successfully!")
        print(f"  - People: {people_count} rows")
        print(f"  - Projects: {projects_count} rows")
        
    except sqlite3.Error as e:
        print(f"✗ Database error: {e}", file=sys.stderr)
        return 1
    finally:
        conn.close()
    
    return 0


if __name__ == "__main__":
    sys.exit(create_database())
