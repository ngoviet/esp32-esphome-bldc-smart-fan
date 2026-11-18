@REM Modem Fan - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run modem-fan.yaml --device 192.168.20.187
@REM esphome run modem-fan.yaml --device COM3
