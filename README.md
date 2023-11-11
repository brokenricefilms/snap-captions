# Snap Captions Davinci Resolve

https://github.com/ongedit/snap-captions/assets/40050527/2fd8f8e1-ae44-43c3-8195-e00a936687ec

- Add more text styles for Snap Captions
- What's Snap Captions? -> https://youtu.be/fOQ7VA7nwxM?si=jyKmQOjcm1zv6g1A
- Welcomed to contribute
- Buy Author a coffee: <https://ko-fi.com/mediable>

## Install

> Right now I only test on Windows, which means this Just works. If you use other OS (MacOS, Linux, 
TempleOS, etc...) Refer read the docs below provided by the author OR you know what you doing.

> Copy and paste in PowerShell
```pwsh
git clone https://github.com/ongedit/snap-captions/
cd snap-captions
cp "Snap Captions.lua" "$env:appdata\Blackmagic Design\DaVinci Resolve\Support\Fusion\Scripts\Comp\"
ii ./fonts/
```

OR

```pwsh
./install.ps1
```

1. Open the [fonts/](./fonts/) folder 
1. Select all
1. Right click
1. Select install
1. Make sure Davinci Resolve isn't opening (because it's needs loading the font)
1. Open the `Snap Captions Index.drb`


Copy the Snap Captions bin into the power bin for easy import or just click this `.drb` file every time you new project

## Dev 

1. Open the "Snap Captions Index.drb"
2. Open timeline, change stuff, rename
3. Delete all text in the Snap Caption bin
4. Select all the text on the timeline
5. Drag and drop to Snap Caption bin

## Docs

- Snap Caption script v1.3
- Link to Snap Captions <https://ko-fi.com/s/67e49a15e7>
- https://mediable.notion.site/Snap-Captions-Install-Guide-f39ead46635148d9bd4c4e1052c43d19 
