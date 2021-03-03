FROM python:3.7-slim-stretch

WORKDIR /app/vassar_resources

COPY ./. /app/vassar_resources

RUN pip3 install --no-cache-dir -r ./requirements.txt