FROM debian:sid
RUN rm /etc/apt/sources.list.d/*
RUN echo 'deb http://mirror.kku.ac.th/debian/ sid main contrib non-free' > /etc/apt/sources.list

RUN apt update && apt upgrade -y && \
    apt install -y python3 python3-dev python3-pip python3-venv \
    locales && \
    apt autoclean && apt -y autoremove && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i '/th_TH.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

RUN python3 -m venv /venv
ENV PYTHON=/venv/bin/python3

RUN $PYTHON -m pip install wheel poetry

WORKDIR /app
COPY poetry.lock pyproject.toml README.md /app/
COPY . /app

RUN . /venv/bin/activate \
    && poetry config virtualenvs.create false \
    && poetry install --no-interaction --only main



EXPOSE 8000
CMD [ "/venv/bin/python3", "-m", "fastapi", "run", "flasx/main.py" ]

