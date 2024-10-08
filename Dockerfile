# `python-base` sets up all our shared environment variables
FROM python:3.10-slim as python-base

# python
ENV PYTHONUNBUFFERED=1 \
  # prevents python creating .pyc files
  PYTHONDONTWRITEBYTECODE=1 \
  \
  # pip
  PIP_NO_CACHE_DIR=off \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  PIP_DEFAULT_TIMEOUT=100 \
  \
  # poetry
  # https://python-poetry.org/docs/configuration/#using-environment-variables
  POETRY_VERSION=1.3.0 \
  # make poetry install to this location
  POETRY_HOME="/opt/poetry" \
  # make poetry create the virtual environment in the project's root
  # it gets named `.venv`
  POETRY_VIRTUALENVS_IN_PROJECT=true \
  # do not ask any interactive question
  POETRY_NO_INTERACTION=1 \
  \
  # paths
  # this is where our requirements + virtual environment will live
  PYSETUP_PATH="/opt/pysetup" \
  VENV_PATH="/opt/pysetup/.venv"

# prepend venv to path
ENV PATH="$VENV_PATH/bin:$PATH"

# `builder-base` stage is used to build deps + create our virtual environment
FROM python-base as builder-base
RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  # deps for installing poetry
  curl \
  # deps for building python deps
  build-essential \
  libpq-dev \
  gcc

RUN pip install "poetry==$POETRY_VERSION"

# prepend poetry to path
ENV PATH="$POETRY_HOME/bin:$PATH"

# copy project requirement files here to ensure they will be cached.
WORKDIR $PYSETUP_PATH
COPY poetry.lock pyproject.toml ./

# install runtime deps - uses $POETRY_VIRTUALENVS_IN_PROJECT internally
RUN poetry install --only main

# `production` image used for runtime
FROM python-base as production

WORKDIR /app

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
  netcat-traditional \
  libpq-dev \
  gettext

COPY --from=builder-base $PYSETUP_PATH $PYSETUP_PATH
COPY . .

COPY ./docker-entrypoint.sh .
COPY ./gunicorn.conf.py .
RUN chmod +x ./docker-entrypoint.sh

ENTRYPOINT ["/app/docker-entrypoint.sh"]
