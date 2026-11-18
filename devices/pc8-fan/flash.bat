@REM PC8 Fan - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run pc8-fan.yaml --device 192.168.20.191
@REM esphome run pc8-fan.yaml --device COM3
