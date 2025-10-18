FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install gunicorn (if not in requirements.txt)
RUN pip install --no-cache-dir gunicorn

# Copy app code
COPY app.py .
COPY templates/ templates/

# Expose Flask port
EXPOSE 5001

# Run the application
CMD ["gunicorn", "--workers", "2", "--bind", "0.0.0.0:5001", "app:app"]
