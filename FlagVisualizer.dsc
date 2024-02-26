##
## This file contains the task scripts specific to the Kingdoms flag visualizer- a tool which
## graphically displays Denizen data structures in a highly readable format to reduce confusion
## when searching through flags.
##
## @Author: Zyad (@itszyad / ITSZYAD#9280)
## @Date: Mar 2023
## @Script Ver: v1.6
##
##ignorewarning color_code_misformat
## ------------------------------------------END HEADER-------------------------------------------


FlagVisualizer:
    type: task
    debug: false
    definitions: flag|flagName|recursionDepth
    description:
    - Displays a user-friendly, easy-to-read view of the given data (def: 'flag').
    - Optionally, you may specify a name for that data (def: 'flagName').
    - Note: Do not tamper with 'recursionDepth'. It is just a safeguard to ensure infinite recursion errors do not occur.

    script:
    ## Displays a user-friendly, easy-to-read view of the given data (def: 'flag').
    ## Optionally, you may specify a name for that data (def: 'flagName').
    ##
    ## Note: Do not tamper with 'recursionDepth'. It is just a safeguard to ensure infinite
    ## recursion errors do not occur.
    ##
    ## flag     : [Object]
    ## flagName : [ElementTag<String>]

    - define recursionDepth <[recursionDepth].if_null[0]>
    - define tabWidth <[recursionDepth].mul[4]>
    - define flagName "Unnamed Flag" if:<[flagName].exists.not>

    - if <[recursionDepth]> > 49:
        - narrate format:admincallout "Recursion depth exceeded 50! Killing queue: <script.queues.get[1]>"
        - determine cancelled

    - if !<[flag].exists>:
        - determine cancelled

    - if <[flag].as[entity].exists>:
        - define name <[flag].name.color[aqua]>
        - define uuid <[flag].uuid>

        - if <[flag].object_type.to_uppercase.equals[NPC]>:
            - define id <[flag].id>
            - determine passively "<[name]> <element[[uuid]].color[light_purple].on_hover[<[uuid].color[light_purple]>]> <element[[id]].color[light_purple].on_hover[<[id].color[light_purple]>]>"

        - else:
            - determine passively "<[name]> <element[[uuid]].color[light_purple].on_hover[<[uuid].color[light_purple]>]>"

    - else if <[flag].time_zone_id.exists>:

        # TODO: Make this work with whatever timezone the server is in.
        - define ESTTime <[flag].to_zone[America/New_York]>
        - define formattedTime <[ESTTime].format[YYYY-MM-dd/hh:mm]>

        - determine passively <[flag].color[light_purple].on_hover[<[formattedTime]> EST]>

    - else if <[flag].object_type> == Item:
        - define itemPropertiesList <[flag].property_map>

        - if !<[itemPropertiesList].is_empty>:
            - define formattedItemProperties <list[]>

            - foreach <[itemPropertiesList]>:
                - define formattedItemProperties:->:<element[<[key]><&co> <[value]>]>

            - define formattedItemProperties <[formattedItemProperties].separated_by[<n>]>

            - determine passively "<element[i<&at><[flag].material.name>].color[aqua]> <element[[nbt]].color[light_purple].on_hover[<[formattedItemProperties]>]>"

        - determine passively <element[i<&at><[flag].material.name>].color[aqua]>

    - else if <[flag].object_type> == Chunk:
        - define cornerOne <[flag].cuboid.corners.get[1].simple.split[,].remove[last].remove[2].separated_by[,]>
        - define cornerTwo <[flag].cuboid.corners.get[2].simple.split[,].remove[last].remove[2].separated_by[,]>
        - define coordRange "<[cornerOne]> -<&gt> <[cornerTwo]>"

        - determine passively "<[flag].color[aqua]> <element[[range]].color[light_purple].on_hover[<[coordRange]>]>"

    - else if <[flag].object_type> == Binary:

        # 7 more characters included in the substring method to account for 'binary@'
        # I really don't want to split it out then re-add it...
        - define truncatedBinary <[flag].as[element].substring[1,107]>

        - if <[flag].as[element].length> > 100:
            - define truncatedBinary <element[<[truncatedBinary]> <element[[...]].color[light_purple].on_hover[<element[Raw binary truncated at 100 characters].color[light_purple]>]>]>

        - determine passively "<[truncatedBinary]> <element[[length]].color[light_purple].on_hover[<[flag].length.color[light_purple]>]>"

    - else if <[flag].object_type> == Map:
        - narrate <proc[MakeTabbed].context[<element[MAP :: <[flagName].color[green]> (Size: <[flag].size.color[yellow]>)].italicize.color[gray]>|<[tabWidth]>]>
        - define tabWidth:+:4

        - foreach <[flag]>:

            # # Ensures only 10 items are written from the map
            # # as to avoid chat spam
            # - if <[loop_index]> >= 10:
            #     - narrate "<proc[MakeTabbed].context[And <[flag].size.sub[10]> more...]>"
            #     - foreach stop

            - run FlagVisualizer def.flag:<[value]> def.flagName:<[key]> def.recursionDepth:<[recursionDepth].add[1]> save:Recur

            - if <entry[Recur].created_queue.determination.get[1].as[list].size.if_null[0]> == 1:
                - define line <list[<[key].color[aqua].italicize><&co> ]>
                - define line:->:<entry[Recur].created_queue.determination.get[1].color[white]>
                - narrate <proc[MakeTabbed].context[<[line].unseparated>|<[tabWidth]>].as[element]>

    - else if <[flag].object_type> == List:
        - narrate <proc[MakeTabbed].context[<element[LIST :: <[flagName].color[green]> (Size: <[flag].size.color[yellow]>)].italicize.color[gray]>|<[tabWidth]>]>
        - define longestNumber <[flag].size>
        - define tabWidth:+:4

        - foreach <[flag]>:

            # # Ensures only 20 items are written from the list
            # # as to avoid chat spam
            # - if <[loop_index]> >= 20:
            #     - narrate "<proc[MakeTabbed].context[And <[flag].size.sub[20]> more...]>"
            #     - foreach stop

            - run FlagVisualizer def.flag:<[value]> def.flagName:<[loop_index]> def.recursionDepth:<[recursionDepth].add[1]> save:Recur

            - if <entry[Recur].created_queue.determination.get[1].as[list].size.if_null[0]> == 1:
                - define formattedIndex <[loop_index].pad_left[<[longestNumber].length>].with[0]>
                - narrate <proc[MakeTabbed].context[<element[<[formattedIndex].color[gray]>: <entry[Recur].created_queue.determination.get[1].color[white]>]>|<[tabWidth]>]>

    - else:
        - determine passively <[flag]>


MakeTabbed:
    type: procedure
    debug: false
    definitions: element|tabLevel
    script:
    - define tabbedList <list[<element[¦   ].repeat[<[tabLevel].div_int[4]>]>|<[element]>]>
    - define unseparatedTab <[tabbedList].unseparated>
    - define chatWidth 320

    - if <[unseparatedTab].text_width> <= <[chatWidth]>:
        - determine <[unseparatedTab]>

    - define currWidth 0
    - define formattedTab <list[]>
    - define sep <[unseparatedTab].split[]>
    - define skip false

    - foreach <[sep]>:
        - if <[value]> == §:
            - define skip true

        - if <[skip]> && <[value]> == ]:
            - define skip false

        - if <[currWidth].add[<[value].text_width>]> >= <[chatWidth]>:
            - define currWidth 0
            - define formattedTab:->:<n>
            - define formattedTab:->:<element[¦   ].repeat[<[tabLevel].div_int[4]>]>
            - define currWidth:+:<element[    ].repeat[<[tabLevel].div_int[4]>].text_width>

        - if !<[skip]>:
            - define currWidth:+:<[value].text_width>

        - define formattedTab:->:<[value]>

    - determine <[formattedTab].unseparated>
