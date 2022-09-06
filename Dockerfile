FROM python:3.8


ENV USER=daphne
ENV PASSWORD=xxxxxxxxxxxx
ENV POSTGRES_HOST=daphne-dev-database.csl99y1ur3jh.us-east-2.rds.amazonaws.com
ENV POSTGRES_PORT=5432


ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}


RUN apt-get update
RUN apt-get install -y libpq-dev &&\
    apt-get install gcc

# --> 1. Copy Resources
WORKDIR /app
COPY ./. /app
RUN pip3 install --no-cache-dir -r ./requirements.txt


# Func 1: index vassar database
WORKDIR /app/db_utility
CMD python3 index.py

# Func 2: recreate database
WORKDIR /app/aws
CMD python3 recreate.py



