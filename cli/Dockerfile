FROM python:3.10-bullseye
ENV POETRY_VERSION 1.5
ENV PATH_APP /app
RUN eval "$(curl -Ssf --proto '=https' https://tea.xyz)"
WORKDIR ${PATH_APP}
COPY . .
RUN tea poetry@${POETRY_VERSION} build
RUN pip install -U ./dist/*.whl
