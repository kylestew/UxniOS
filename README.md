# UxniOS

___A Uxn emulator for iOS___

Learn more about Uxn [here](https://wiki.xxiivv.com/site/uxn.html).

## Supported Devices

|       | Device        | Support                               |
| ----- | ------------- | ------------------------------------- |
| 0x00  | System        | **complete**                          |
| 0x10  | Console       | incomplete: no console in             |
| 0x20  | Screen        | **complete**                          |
| 0x30  | Audio         | incomplete                            |
| 0x40  | Audio         | incomplete                            |
| 0x50  | Audio         | incomplete                            |
| 0x60  | Audio         | incomplete                            |
| 0x90  | ---           |                                       |
| 0x80  | Controller    | incomplete: is this the keyboard? 🤔  |
| 0x90  | Mouse         | _limited: touch screen approximation_ |
| 0xA0  | file          | incomplete                            |
| 0xB0  | datetime      | **complete**                          |
| 0xC0  | ---           |                                       |
| 0xD0  | ---           |                                       |
| 0xE0  | ---           |                                       |
| 0xF0  | ---           |                                       |

## In Progress

- [ ] Sound output
- [ ] Keyboard input
- [ ] Device rotation, better display scaling
- [ ] ROM loading, pausing/restoring state
- [ ] Full mouse support - GUI elements for mouse input

## License Info

___MIT License___

Major portions of the emulator and the base Uxn code are (c) Devine Lu Linvega. The MIT license applies to the extended code I've added in this repo.
