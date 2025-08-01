@echo off
cd %cd%
docker-compose -f docker-compose-rabbitmq.yml down -v