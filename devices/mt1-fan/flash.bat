@REM MT1 Fan (thay T3 cu) - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run mt1-fan.yaml --device 192.168.20.155
@REM esphome run mt1-fan.yaml --device COM3
