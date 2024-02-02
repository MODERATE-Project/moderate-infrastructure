FROM python:3.10-slim-bookworm

ENV POETRY_VERSION=1.7.1 \
    PATH_APP=/app

RUN pip install -U pip setuptools poetry==${POETRY_VERSION}
WORKDIR ${PATH_APP}
COPY . .
RUN poetry build
RUN pip install -U ./dist/*.whl
