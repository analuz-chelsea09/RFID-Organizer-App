// Shared BLE identifiers. These must match the Arduino sketch's
// rfidService / *Characteristic UUIDs exactly.
//
// Keeping these in one place avoids the main.dart / scan_page.dart
// duplicate top-level const collision that used to break compilation.

const serviceUuid = "28103970-5798-444e-be77-7e2ca6a88b3a";
const uidCharUuid = "19708951-d3cd-449b-8dd0-3cbdcc13498d";
const nameCharUuid = "2a153df6-cd10-4d17-b4c3-d6c5cfbd8a17";
const statusCharUuid = "7362ff42-a7bd-409e-a536-ad8f88d55f4d";
const controlCharUuid = "0307855a-4743-407d-b51b-b7b6c42893ee";

// nameCharacteristic on the mc is a BLEStringCharacteristic with a
// fixed buffer size of 20 bytes. Keep this in sync with the sketch.
const maxTagNameBytes = 20;
