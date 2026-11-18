"""Toggle modem-fan light via ESPHome native API to verify off/on control.

Bật 50% → chờ → tắt → chờ. Dùng chẩn đoán, không phải config.
"""
import asyncio

from aioesphomeapi.client import APIClient


async def main():
    cli = APIClient("192.168.20.187", 6053, None)
    await cli.connect(login=True)

    info = await cli.device_info()
    print("Device:", info.name)

    entities, _ = await cli.list_entities_services()
    for ent in entities:
        if getattr(ent, "object_id", None) == "speed":
            print("Found light entity key:", ent.key)
            print(">> BẬT 50%")
            cli.light_command(key=ent.key, state=True, brightness=0.5)
            await asyncio.sleep(5)
            print(">> TẮT")
            cli.light_command(key=ent.key, state=False)
            await asyncio.sleep(5)
            print("Xong. Anh nhìn quạt: dừng hẳn = OK, vẫn quay = còn bug.")
            break
    else:
        print("!! Không tìm thấy entity light 'speed'")

    await cli.disconnect()


asyncio.run(main())
