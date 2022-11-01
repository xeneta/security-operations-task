FROM postgres:13
COPY db/rates.sql /opt/db/
COPY rates/ /opt/rates/

ENV POSTGRES_USER postgres
ENV POSTGRES_PASSWORD postgres
ENV PGPASSWORD postgres

WORKDIR /opt/rates

ENV DEBIAN_FRONTEND noninteractive
RUN apt update && apt install -y python3-pip && pip install -U gunicorn && pip install -Ur requirements.txt
EXPOSE 3000