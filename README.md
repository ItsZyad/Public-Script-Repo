# Zyad's Work Samples

If you've been linked this repo then it means I've likely shown interest in working on your Denizen scripting project, and I wanted to showcase some of things I've created before!

Most (if not all) of the scripts shown here are from a very long-term project that I've been working on for over three and a half years called Kingdoms. Kingdoms is a massive undertaking which intends to turn your Minecraft server into a realistic, medieval-themed political strategy game with city building and battle mechanics akin to Manor Lords and international politics and story elements that draw inspiration from Paradox titles like Victoria III. While Kingdoms as a whole is (at this time) still private, the scripts shown here are not. Some of them are dev tools that work standalone, while others can make sense on their own (and serve as good personal showcases) but will not function if ran on a server by themselves. So feel free to look around, read through, or even copy some of the code in this repo, or you can read the short blurbs below which will summarize each of the scripts one-by-one in plain English.

## FlagVisualizer.dsc
*Free to use - Download Encouraged (Don't forget to credit!)*

The flag visualizer was something I came up with after the Kingdoms codebase started ballooning in size in early 2022. I needed a way to keep track of the growing number (and size) of flags saved on my test server, and the default Denizen view just wasn't cutting it for me anymore. The flag visualizer simplifies complex flag submaps into a cascade view with sub-mapped relations clearly shown with nesting levels (see below).

< insert picture >

The script works by having a number of default formatting options for atomic data types like ElementTags, BinaryTags, ItemTags etc. When it comes to Lists and Maps, the script will run itself recursively, adding an extra 4 spaces of indentation with each call. There is also a helper procedure at the bottom of the file which adds the indentation, as well as word wrap for lines that run off the default 320px size of the Minecraft chat, which helps with readability.

Two Notes, however:
1. If you want to download this script it is HIGHLY RECOMMENDED that you use it alongside a client-side mod that increases your chat history size like [MoreChatHistory](https://modrinth.com/mod/morechathistory). Vanilla Minecraft's default chat history size is just a pitiful 100 messages, and this will not be enough for even moderately-sized flags.
2. I usually use this script alongside a command called `/seeflag` which tab-completes the flag and sub flag names as you're typing them. But I chose to omit the command script because the tab complete code is kind of a monstrosity (but if you reeeaally want it you can let me know).

## CISKCommandHandler.dsc
*Free to view - Won't make sense without its companion scripts...*

These scripts form the basis of (in my opinion) the coolest and most technically impressive sub-system in Kingdoms: CISK (or the **C**ommon **I**nterface for **S**torywriting in **K**ingdoms). A large part of Kingdoms is going to be its quests system. I was originally going to write quests and dialogue for this game using regular-old Denizen interact scripts before quickly realizing that I have no storywriting skills whatsoever. I needed to find a way to allow other people to write story and quest lines for me without teaching every single one of them how to use Denizen. CISK was the answer; a highly-simplified Denizen-like scripting language with any feature not related to story writing stripped away.

This module contains the scripts which form the lexer, parser, and (a small portion of the) executor for CISK's in-line commands. It works by separating each line into space (or bracket) separated chunks - otherwise known as 'lexmes'. These lexemes are then passed off to another script that decides which order these lexmes should be interpreted in by organizing them into a syntax tree, before sending them off to a final script that will then recognize any commands contained within the tree structure and run them accordingly.

*Never thought I'd stumble my way into making a scripting language... in another scripting language...*

## PackageIndexer.dsc
*Free to view - Won't make sense without its companion scripts...*

The package indexer is a pretty straight-forward bit of code and is part of a larger Kingdoms sub-system called KPM (or the Kingdoms Package Manager)*, which is designed to allow players to insert their own bits of Denizen code into the game to mod it. The indexer simply runs through the root `../Kingdoms/addons` directory and takes stock of all the addons/packages that are present on the server. It generates a unique SHA-256 Hash for each addon, records some additional information and flags all that onto the server on start-up.

While they may not have as much to look at as CISK, I think the `SeekFolders_KPM` task is pretty neat, while the indexer itself is a pretty good showcase of sufficiency in simplicity.

*yes, I know, I love my acronyms :)