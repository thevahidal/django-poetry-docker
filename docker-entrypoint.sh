#!/usr/bin/env bash

echo "Waiting for database..."
while ! nc -z ${SQL_HOST} ${SQL_PORT}; do sleep 1; done
echo "Connected to database."

python manage.py migrate --noinput
if [ $? -ne 0 ]; then
	echo "Migration failed." >&2
	exit 1
fi

# if arguments passed, execute them
# bring up an instance of project otherwise
if [[ $# -gt 0 ]]; then
	INPUT=$@
	sh -c "$INPUT"
else
	mkdir -p /var/log/projectname

	if [ "$DEBUG" = "True" ]; then
		python manage.py collectstatic --noinput
	fi

	echo "Starting Gunicorn..."
	exec gunicorn projectname.wsgi:application -c gunicorn.conf.py
fi
