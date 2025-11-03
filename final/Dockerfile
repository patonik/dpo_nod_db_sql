FROM python:3.12-slim

WORKDIR /app

COPY main.py .

RUN pip install --no-cache-dir psycopg2-binary & pip install --no-cache-dir prettytable

CMD ["bash", "-c", "echo 'run application using \"python3 main.py\"' && tail -f /dev/null"]