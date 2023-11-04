# Snap Captions Davinci Resolve

- A Custom and more caption style. **Welcome to contribute**

## Install

> Rightnow I only test on Windows, that mean this Just work. If you use other OS (MacOS, Linux, 
TempleOS, etc...) refer read the docs below provide by author OR you know what you doing.

```pwsh
git clone https://github.com/ongedit/snap-captions/
cd snap-captions
cp "Snap Captions.lua" "$env:appdata\Blackmagic Design\DaVinci Resolve\Support\Fusion\Scripts\Comp\"
ii *.ttf
ii '.\Snap Captions Index.drb'
```

OR

```pwsh
./install.ps1
```

It will open some Windows font install just click install or just open the bin and change the font you want.

Maybe Davici Resolve didn't loading the new font, So just re-open it

Copy Snap Captions bin into the power bin for easy import or just click this `.drb` file every time you new project

## Dev 

1. Open the "Snap Captions Index.drb"
2. Open timeline, change stuff, rename
3. Delete all text in Snap Caption bin
4. Select all the text on timeline
5. Drag and drop to Snap Caption bin

## Docs

- Snap Caption script v1.2
- https://mediable.notion.site/Snap-Captions-Install-Guide-f39ead46635148d9bd4c4e1052c43d19 
