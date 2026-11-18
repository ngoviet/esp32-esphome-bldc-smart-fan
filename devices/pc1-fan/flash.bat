@REM PC1 Fan - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run pc1-fan.yaml --device 192.168.20.179
@REM esphome run pc1-fan.yaml --device COM3
