@echo off

setlocal

REM load environments from .env
for /f "usebackq tokens=1,2 delims==" %%a in (.env) do (
    set "%%a=%%b"
)


REM Generate docker-compose-rabbitmq.yml
set "TEMPLATE_COMPOSE=compose.rabbitmq.template.yml"
set "OUTPUT_COMPOSE=docker-compose-rabbitmq.yml"

REM Copy template to final file
copy /Y "%TEMPLATE_COMPOSE%" "%OUTPUT_COMPOSE%" >nul

REM Add networks section to end of file
echo. >> %OUTPUT_COMPOSE%
echo networks: >> %OUTPUT_COMPOSE%
echo   %DOCKER_NETWORK_NAME%: >> %OUTPUT_COMPOSE%
echo     external: true >> %OUTPUT_COMPOSE%

echo Creating network %DOCKER_NETWORK_NAME% if it is not exists
docker network inspect %DOCKER_NETWORK_NAME% >nul 2>&1 || docker network create %DOCKER_NETWORK_NAME%


set "main_dir=%cd%"
cd %main_dir%

call :create_volumes
call :create_advanced_config
call :run_docker_compose

goto eof

:create_volumes
  cd %main_dir%
  mkdir data
  cd data

  mkdir configs
  mkdir mnesia

  goto :eof

:create_advanced_config
  cd %main_dir%
  set "advanced_config_path=data\configs\advanced.config"
  (
  echo [
  echo   {rabbit, [
  echo     {consumer_timeout, undefined}
  echo   ]}
  echo ].
  ) > "%advanced_config_path%"

  goto :eof

:run_docker_compose
  docker-compose -f docker-compose-rabbitmq.yml up -d

  goto :eof

:eof
  endlocal
  pause
  exit /b