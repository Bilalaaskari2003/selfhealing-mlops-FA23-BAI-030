FROM python:3.10-slim

WORKDIR /app

# Install Chrome for Selenium UI tests
RUN apt-get update && apt-get install -y \
    wget gnupg curl unzip \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" \
       >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create log directory
RUN mkdir -p /app/logs

EXPOSE 5000

CMD ["python", "app.py"]
