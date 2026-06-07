FROM python:3.10-slim

WORKDIR /app

# Install Chrome for Selenium UI tests
RUN apt-get update && apt-get install -y \
    wget gnupg curl unzip ca-certificates \
    && wget -q -O /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb \
    && apt-get install -y /tmp/chrome.deb \
    && rm /tmp/chrome.deb \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

RUN mkdir -p /app/logs

EXPOSE 5000

CMD ["python", "app.py"]
