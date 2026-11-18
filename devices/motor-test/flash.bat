@echo off
@REM Motor Test - OTA Flash (env Windows sach + IDF cache path ngan), log ra flash.log
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run motor-test.yaml --device 192.168.20.187 > flash.log 2>&1
