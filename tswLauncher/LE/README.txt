LocaleEmulator

To solve the mojibake issue of Chinese version TSWs on a non-Chinese OS. Copied from the latest release of https://github.com/xupefei/Locale-Emulator-Core

The Loader.dll library file was slightly modified so that it loads "LE\LocaleEmulator.dll" instead of "LocaleEmulator.dll," because the LocaleEmulator-related files are put in the "LE" subfolder.
