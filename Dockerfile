FROM python:3.10-slim-bullseye

ENV PYTHONUNBUFFERED=1
ENV PORT=8000

RUN apt-get update && apt-get install -y libcairo2-dev gcc

WORKDIR /app/

COPY . .

RUN chmod +x /app/entrypoint.sh

RUN pip install -r requirements.txt

EXPOSE ${PORT}

# Use gunicorn as the production server
CMD ["gunicorn", "--bind", "0.0.0.0:${PORT}", "horilla.wsgi:application"]
