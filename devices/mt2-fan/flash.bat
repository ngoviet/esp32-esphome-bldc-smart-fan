@REM MT2 Fan (dung lai 18/11/2026) - OTA Flash
cd /d %~dp0
set ESPHOME_ESP_IDF_PREFIX=C:\ESPHome\idf
esphome run mt2-fan.yaml --device 192.168.20.189
@REM esphome run mt2-fan.yaml --device COM3
