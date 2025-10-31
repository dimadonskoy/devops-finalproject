FROM python:3.10-slim

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

RUN pip install --no-cache-dir gunicorn

COPY app.py .

COPY templates/ templates/

EXPOSE 5001

CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5001", "app:app"]
