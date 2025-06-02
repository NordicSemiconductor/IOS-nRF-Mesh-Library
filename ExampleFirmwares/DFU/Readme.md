# Device Firmware Update

This folder contains test firmware for testing DFU over Bluetooth Mesh compiled on nRF Connect SDK version 2.9 with later changes (git tag: 3f1d572d52826009aac75ff65f5413ba1a74014e).

## Supported devices

The test firmware was compiled for nRF52840 DK and nRF54L15 DK.

## Content

* **dfu_blinky_3.0.0.zip** - a minimal test firmware of 27 KB, best for testing DFU due to it's small size. It's a simple Hello World app and will make the DK to blink. It is compiled for nRF52840 DK.

* nRF Connect SDK 2.9
   * **dfu_distr_nrf54L_0.9** - firmware for nRF54L15 DK with Distributor sample WITHOUT *LE Pairing Responder* model.
   * **dfu_distr_nrf54L_1.0.1** - firmware for nRF54L15 DK with Distributor sample WITH *LE Pairing Responder* model.
   * **dfu_distr_nrf54L_2.0.1** - firmware for nRF54L15 DK with Distributor sample WITH *LE Pairing Responder* model and Update URI.
   * **dfu_distr_nrf52840_1.0** - firmware for nRF52840 DK with Distributor sample WITH *LE Pairing Responder* model.
   * **dfu_distr_nrf52840_2.0** - firmware for nRF52840 DK with Distributor sample WITH *LE Pairing Responder* model and Update URI.
   * **dfu_distr_nrf54L_1.0** - firmware for nRF54L15 DK with Target sample.
   * **dfu_distr_nrf54L_2.0** - firmware for nRF54L15 DK with Target sample and Update URI.
   * **dfu_distr_nrf52840_1.0** - firmware for nRF54L15 DK with Target sample.
   * **dfu_distr_nrf52840_1.1** - firmware for nRF54L15 DK with Target sample and Update URI.
   * **dfu_distr_nrf52840_2.0** - firmware for nRF54L15 DK with Target sample and Update URI.

## Update URI

A Node can provide an Update URI in its Firmware Information. A Distributor or an Initiator can use this URI to check and download the firmware update.

The firmware is compiled so that the Update URI on selected firmware is set to https://192.168.0.173:8000. Check out *server.py* to start a local HTTPS server.

### Local HTTPS Server

Make sure your computer IP Address is 192.168.0.173 or compile your own firmware providing a different address in:
https://github.com/nrfconnect/sdk-nrf/blob/3d75f3562e4f8c16491b8c51f250a9cb1b2232b5/samples/bluetooth/mesh/dfu/common/src/dfu_target.c#L35-L38

```c
static struct bt_mesh_dfu_img dfu_imgs[] = { {
	.fwid = &fwid,
	.fwid_len = sizeof(fwid),
	.uri = "https://192.168.0.173:8000"
} };
```

Copy the content of *server* folder to a local folder on your computer and start `python server.py`.

### Server endpoints

The Mesh DFU specification defines 2 endpoints: `/check` and `/get` with `cfwid` parameter sent as GET. The value of the parameter should be the Firmware ID in HEX.

### Server response

The `/check` endpoint should return a JSON file with format specified in the Mesh DFU specification, i.e.:

```json
"manifest": {
    "firmware": {
        "firmware_id": "59000200000000000000",
        "dfu_chain_size": 1,
        "firmware_image_file_size": 341466
    }
}
```

The `/get` endpoint should return a ZIP file created automatically when compiling the project, which includes the binary file, a *manifest.json* file and *ble_mesh_metadata.json* file.
