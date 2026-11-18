@REM T2 Fan - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run t2-fan.yaml --device 192.168.20.178
@REM esphome run t2-fan.yaml --device COM3
