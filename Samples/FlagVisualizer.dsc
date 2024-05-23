##
## This file contains the task scripts specific to the Kingdoms flag visualizer- a tool which
## graphically displays Denizen data structures in a highly readable format to reduce confusion
## when searching through flags.
##
## @Author: Zyad (@itszyad / ITSZYAD#9280)
## @Date: Mar 2023
## @Script Ver: v1.8.1
##
##ignorewarning color_code_misformat
## ------------------------------------------END HEADER-------------------------------------------


FlagVisualizer:
    type: task
    debug: false
    definitions: flag[Object]|flagName[ElementTag(String)]
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

    - define flagName "Unnamed Flag" if:<[flagName].exists.not>

    - narrate <element[                                                     ].strikethrough>
    - inject FlagVisualizer_Recur

    - if <script.queues.get[1].determination.get[1].exists>:
        - narrate <element[<[flagName]>: ].color[green].italicize><script.queues.get[1].determination.get[1]>

    - narrate <element[                                                     ].strikethrough>


FlagVisualizer_Recur:
    type: task
    debug: false
    definitions: flag[Object]|flagName[ElementTag(String)]|recursionDepth[ElementTag(Integer)]
    script:
    - define recursionDepth <[recursionDepth].if_null[0]>
    - define tabWidth <[recursionDepth].mul[4]>

    # I like just keeping this around just because I'm paranoid. As far as I know, this has never
    # crashed my server, and you can increase the limit/remove it if you like.
    - if <[recursionDepth]> > 49:
        - narrate "Recursion depth exceeded 50! Killing queue: <script.queues.get[1]>"
        - determine cancelled

    - if !<[flag].exists>:
        - determine cancelled

    - choose <[flag].object_type>:
        - case Time:
            - define serverTimeZone <util.time_now.time_zone_name>
            - define LocalTime <[flag].to_local>
            - define formattedTime <[LocalTime].format[YYYY-MM-dd/hh:mm]>

            - determine passively <[flag].color[light_purple].on_hover[<[formattedTime]> <[serverTimeZone]>]>

        - case Duration:
            - determine passively <[flag].formatted.color[aqua]>

        - case Item:
            - define itemPropertiesList <[flag].property_map>

            - if !<[itemPropertiesList].is_empty>:
                - define formattedItemProperties <list[]>

                - foreach <[itemPropertiesList]>:
                    - define formattedItemProperties:->:<element[<[key]><&co> <[value]>]>

                - define formattedItemProperties <[formattedItemProperties].separated_by[<n>]>

                - determine passively "<element[i<&at><[flag].material.name>].color[aqua]> <element[[nbt]].color[light_purple].on_hover[<[formattedItemProperties]>]>"

            - determine passively <element[i<&at><[flag].material.name>].color[aqua]>

        - case Location:
            - determine passively <element[l<&at>].color[gray]><[flag].simple.split[,].remove[last].separated_by[<element[,].color[gray]>]><element[<&at>].color[gray]><[flag].world.name>

        - case Chunk:
            - define cornerOne <[flag].cuboid.corners.get[1].simple.split[,].remove[last].remove[2].separated_by[, ]>
            - define cornerTwo <[flag].cuboid.corners.last.simple.split[,].remove[last].remove[2].separated_by[, ]>
            - define coordRange "<[cornerOne]> -<&gt> <[cornerTwo]>"

            - determine passively "<[flag].color[aqua]> <element[[range]].color[light_purple].on_hover[<[coordRange]>]>"

        - case Cuboid:
            - define cornerOne <[flag].corners.get[1].simple.split[,].remove[last].separated_by[,]>
            - define cornerTwo <[flag].corners.last.simple.split[,].remove[last].separated_by[,]>
            - define coordRange "<[cornerOne]> <element[-<&gt>].color[gray]> <[cornerTwo]>"

            - determine passively <element[cu<&at>].color[gray]><[coordRange].replace[,].with[<element[,].color[gray]>]><element[<&at>].color[gray]><[flag].world.name>

        - case Polygon:
            - if <[flag].corners.size> > 10:
                - define formattedCorners <[flag].corners.get[1].to[10]>

            - else:
                - define formattedCorners <[flag].corners>

            - define formattedCorners <[formattedCorners].parse_tag[<[parse_value].x>/<[parse_value].z>].separated_by[<element[,].color[gray]>]>
            - define determination <element[po<&at>].color[gray]><[formattedCorners]>
            - define determination <element[po<&at>].color[gray]><[formattedCorners]><element[[...]].color[light_purple].on_hover[Corner List Truncated]> if:<[flag].corners.size.is[MORE].than[10]>

            - determine passively "<[determination]> <element[[Max Y]].color[light_purple].on_hover[<[flag].max_y>]> <element[[Min Y]].color[light_purple].on_hover[<[flag].min_y>]>"

        - case Binary:
            # 7 more characters included in the substring method to account for 'binary@'
            # I really don't want to split it out then re-add it...
            - define truncatedBinary <[flag].as[element].substring[1,107]>

            - if <[flag].as[element].length> > 100:
                - define truncatedBinary <element[<[truncatedBinary]> <element[[...]].color[light_purple].on_hover[<element[Raw binary truncated at 100 characters].color[light_purple]>]>]>

            - determine passively "<[truncatedBinary]> <element[[length]].color[light_purple].on_hover[<[flag].length.color[light_purple]>]>"

        - case Map:
            - narrate <proc[MakeTabbed].context[<element[MAP :: <[flagName].color[green]> (Size: <[flag].size.color[yellow]>)].italicize.color[gray]>|<[tabWidth]>]>
            - define tabWidth:+:4

            - foreach <[flag]>:

                # # Ensures only 10 items are written from the map
                # # as to avoid chat spam
                # - if <[loop_index]> >= 10:
                #     - narrate "<proc[MakeTabbed].context[And <[flag].size.sub[10]> more...]>"
                #     - foreach stop

                - run FlagVisualizer_Recur def.flag:<[value]> def.flagName:<[key]> def.recursionDepth:<[recursionDepth].add[1]> save:Recur

                - if <entry[Recur].created_queue.determination.get[1].as[list].size.if_null[0]> == 1:
                    - define line <list[<[key].color[aqua].italicize><&co> ]>
                    - define line:->:<entry[Recur].created_queue.determination.get[1].color[white]>
                    - narrate <proc[MakeTabbed].context[<[line].unseparated>|<[tabWidth]>].as[element]>

        - case List:
            - narrate <proc[MakeTabbed].context[<element[LIST :: <[flagName].color[green]> (Size: <[flag].size.color[yellow]>)].italicize.color[gray]>|<[tabWidth]>]>
            - define longestNumber <[flag].size>
            - define tabWidth:+:4

            - foreach <[flag]>:

                # # Ensures only 20 items are written from the list
                # # as to avoid chat spam
                # - if <[loop_index]> >= 20:
                #     - narrate "<proc[MakeTabbed].context[And <[flag].size.sub[20]> more...]>"
                #     - foreach stop

                - run FlagVisualizer_Recur def.flag:<[value]> def.flagName:<[loop_index]> def.recursionDepth:<[recursionDepth].add[1]> save:Recur

                - if <entry[Recur].created_queue.determination.get[1].as[list].size.if_null[0]> == 1:
                    - define formattedIndex <[loop_index].pad_left[<[longestNumber].length>].with[0]>
                    - narrate <proc[MakeTabbed].context[<element[<[formattedIndex].color[gray]>: <entry[Recur].created_queue.determination.get[1].color[white]>]>|<[tabWidth]>]>

        - default:
            - if <[flag].as[entity].exists>:
                - define name <[flag].name.color[aqua]>
                - define uuid <[flag].uuid>

                - if <[flag].object_type.to_uppercase> == NPC:
                    - define id <[flag].id>
                    - determine passively "<[name]> <element[[uuid]].color[light_purple].on_hover[<[uuid].color[light_purple]>]> <element[[id]].color[light_purple].on_hover[<[id].color[light_purple]>]>"

                - else:
                    - determine passively "<[name]> <element[[uuid]].color[light_purple].on_hover[<[uuid].color[light_purple]>]>"

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
