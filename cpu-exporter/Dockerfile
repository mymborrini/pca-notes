FROM python:3.12-slim

WORKDIR /usr/src/cpu-exporter/

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY ./cpu-exporter.py .

EXPOSE 8000

CMD ["python", "cpu-exporter.py"]