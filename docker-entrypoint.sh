#!/usr/bin/env bash

echo "Waiting for database..."
while ! nc -z ${SQL_HOST} ${SQL_PORT}; do sleep 1; done
echo "Connected to database."

# if arguments passed, execute them
# bring up an instance of project otherwise
mkdir -p /var/log/projectname

python manage.py compilemessages
python manage.py collectstatic --noinput

echo "Starting Gunicorn..."
exec gunicorn projectname.wsgi:application -c gunicorn.conf.py
