@REM T1 Fan - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run t1-fan.yaml --device 192.168.20.201
@REM esphome run t1-fan.yaml --device COM3
