FROM python:3.13.2-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /djangocker

COPY requirements.txt /djangocker/
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . /djangocker/
