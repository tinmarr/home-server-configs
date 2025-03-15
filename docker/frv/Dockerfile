FROM apache/superset:latest

RUN pip install psycopg2-binary

USER superset
COPY --chown=superset superset_config.py /app/superset_config.py
ENV SUPERSET_CONFIG_PATH /app/superset_config.py
