FROM freqtradeorg/freqtrade:latest

# Install PostgreSQL driver for database connectivity
RUN pip install --no-cache-dir psycopg2-binary

# Metadata labels
LABEL maintainer="homecloud@localhost"
LABEL description="Freqtrade with PostgreSQL support (psycopg2-binary)"
LABEL version="extended"
LABEL base-image="freqtradeorg/freqtrade:latest"

# Preserve original entrypoint from base image
# Our entrypoint.py script is mounted via volume, not baked into image
ENTRYPOINT ["freqtrade"]
CMD ["trade"]
