@REM T31 Fan - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run t31-fan.yaml --device 192.168.20.177
@REM esphome run t31-fan.yaml --device COM3
