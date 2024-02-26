##
## Scripts in this file are responsible for handling CISK's inline commands, which are contained
## with angle brackets, like Denizen's.
##
## @Author: Zyad (@itszyad / ITSZYAD#9280)
## @Date: Apr 2023
## @Script Ver: v2.0
##
## ------------------------------------------END HEADER-------------------------------------------

GenerateRecursiveStructures_CISK:
    type: task
    debug: false
    definitions: splitted
    script:
    - define persistent <map[]>
    - define lineList <list[]>
    - define totalLoops 0
    - define bracketDepth 0

    - foreach <[splitted]> as:token:
        - define prevToken <[splitted].get[<[loop_index].sub[1]>]> if:<[loop_index].is[MORE].than[1]>
        - define nextToken <[splitted].get[<[loop_index].add[1]>]> if:<[loop_index].is[LESS].than[<[splitted].size>]>

        - define prevToken <element[]> if:<[loop_index].is[OR_LESS].than[1]>
        - define nextToken <element[]> if:<[loop_index].is[OR_MORE].than[<[splitted].size>]>

        - if <[loop_index]> < <[persistent].get[commandSize].add[2].if_null[<[loop_index]>]>:
            - foreach next

        - if <[token]> == <&lt> && !<[prevToken].ends_with[\]>:
            - run CommandMapGenerator_CISK def.splitted:<[splitted].get[<[loop_index]>].to[last]> save:command
            - define persistent.commandMap <entry[command].created_queue.determination.get[1].get[commandMap]>
            - define persistent.commandSize <entry[command].created_queue.determination.get[1].get[commandSize]>

            - define lineList:->:<[persistent].get[commandMap]>

        - else:
            - if <[token]> != <&gt>:
                - define lineList:->:<[token]>

    - determine <[lineList]>


CommandMapGenerator_CISK:
    type: task
    debug: false
    definitions: splitted
    script:
    - define commandSize 0
    - define commandMap <map[]>
    - define persistent <map[]>

    - foreach <[splitted]> as:token:
        - define prevToken <[splitted].get[<[loop_index].sub[1]>]> if:<[loop_index].is[MORE].than[1]>
        - define nextToken <[splitted].get[<[loop_index].add[1]>]> if:<[loop_index].is[LESS].than[<[splitted].size>]>

        - define prevToken <element[]> if:<[loop_index].is[OR_LESS].than[1]>
        - define nextToken <element[]> if:<[loop_index].is[OR_MORE].than[<[splitted].size>]>

        - define commandSize:++

        - if <[loop_index]> < <[persistent].get[skipAmount].add[1].if_null[<[loop_index]>]>:
            - foreach next

        - else if <[token]> == <&co>:
            - if <[nextToken]> != <&lt>:
                - define commandMap.attributes:->:<map[<[prevToken]>=<[nextToken]>]>

            - else:
                - run CommandMapGenerator_CISK def.splitted:<[splitted].get[<[loop_index].add[1]>].to[last]> save:recur_split
                - define nestedCommand <entry[recur_split].created_queue.determination.get[1].get[commandMap]>
                - define persistent.skipAmount <entry[recur_split].created_queue.determination.get[1].get[commandSize].add[<[loop_index]>]>
                - define commandMap.attributes:->:<map[<[prevToken]>=<[nestedCommand]>]>

                - foreach next

        - else if <[token]> == <&lt> && !<[prevToken].ends_with[\]>:
            - if <[commandMap].get[name].exists>:
                - run CommandMapGenerator_CISK def.splitted:<[splitted].get[<[loop_index]>].to[last]> save:recur_split
                - define nestedCommand <entry[recur_split].created_queue.determination.get[1].get[commandMap]>
                - define persistent.skipAmount <entry[recur_split].created_queue.determination.get[1].get[commandSize].add[<[loop_index].sub[1]>]>
                - define commandMap.attributes:->:<map[null=<[nestedCommand]>]>

                - foreach next

            - else:
                - define commandMap.name:<[nextToken]>

        - else if <[token]> != <&sp> && <[prevToken]> != <&co> && <[nextToken]> != <&co> && <[commandMap.name]> != <[token]> && !<[token].is_in[<&gt>|<&lt>]>:
            - define commandMap.attributes:->:<map[null=<[token]>]>

        - else if <[token]> == <&gt>:
            - determine <map[commandMap=<[commandMap]>;commandSize=<[commandSize]>]>


CommandDelegator_CISK:
    type: task
    debug: false
    GetRecursiveStructure:
    - if <[splitted].exists>:
        - run GenerateRecursiveStructures_CISK def.splitted:<[splitted]> save:line

    - else:
        - run GenerateRecursiveStructures_CISK save:line

    - define line <entry[line].created_queue.determination.get[1]>

    script:
    - inject <script.name> path:GetRecursiveStructure if:<[commandMap].exists.not>
    - define evaluatedLine <list[]>

    - adjust <queue> linked_player:<[player]>
    - adjust <queue> linked_npc:<[npc]> if:<[npc].exists>

    - foreach <[line]> as:token:
        - if <[token].object_type.to_uppercase> == MAP:
            - define commandMap <[token]>
            - define commandName <[commandMap].get[name]>
            - define commandScript <script[<[commandName]>Command_CISK]>

            - run CommandMapEvaluator_CISK defmap:<queue.definition_map> save:eval_commandMap
            - define commandResult <entry[eval_commandMap].created_queue.determination.get[1].if_null[N/A]>
            - define evaluatedLine:->:<[commandResult]> if:<[commandResult].equals[N/A].not>

        - else:
            - define evaluatedLine:->:<[token]>

    - determine <[evaluatedLine]>


CommandMapEvaluator_CISK:
    type: task
    debug: false
    definitions: commandMap|commandScript
    GenerateAttributeShorthands:
    - define attrSubs <map[]>

    - foreach <[commandScript].data_key[commandData.attributeSubs]> as:subList key:key:
        - foreach <[subList].as[list]> as:sub:
            - define attrSubs.<[sub]>:<[key]>

    script:
    - define commandName <[commandMap].get[name]>
    - define commandScript <[commandScript].if_null[<script[<[commandName]>Command_CISK]>]>
    - inject <script.name> path:GenerateAttributeShorthands if:<[commandScript].data_key[commandData.attributeSubs].exists>

    - adjust <queue> linked_player:<[player]>
    - adjust <queue> linked_npc:<[npc]> if:<[npc].exists>

    - if <[commandScript].data_key[PreEvaluationCode].exists>:
        - inject <[commandScript].name> path:PreEvaluationCode

    - foreach <[commandMap]> key:datapoint:
        - if <[datapoint]> == attributes:
            - foreach <[value]> as:attrPair:
                - define attrKeyRaw <[attrPair].keys.get[1]>
                - define attrKey <[attrKeyRaw]>
                - define attrKey <[attrSubs].get[<[attrKeyRaw]>]> if:<[attrSubs].exists.and[<[attrSubs].contains[<[attrKeyRaw]>]>]>
                - define attrVal <[attrPair].values.get[1]>

                - if <[attrVal].object_type.to_uppercase> == MAP:
                    - run CommandMapEvaluator_CISK def.commandMap:<[attrVal]> def.player:<[player]> save:recur

                    - define nestedCommandResult <entry[recur].created_queue.determination.get[1]>
                    - define attrVal <[nestedCommandResult]>
                    - define commandMap.<[datapoint]>:<-:<[attrPair]>
                    - define commandMap.<[datapoint]>:->:<map[<[attrKey]>=<[nestedCommandResult]>]>

                - inject <[commandScript].name>

    - inject <[commandScript].name> path:PostEvaluationCode

################################################################################################
## Below are three examples of the Denizen representation of some CISK commands. Those being: ##
## <wait>, <dataget> and <datastore>.                                                         ##
##                                                                                            ##
## CISK has dozens of other commands, but I will only show these two since they get the point ##
## across of how CISK's command handler works.                                                ##
################################################################################################

ProduceFlaggableObject_CISK:
    type: task
    debug: false
    definitions: text
    script:
    - choose <[text]>:
        - case player:
            - determine <player>

        - case npc:
            - determine <npc>

        - default:
            - if <[text].starts_with[item]>:
                - define itemRef <[text].split[@].get[2]>
                - determine <item[<[itemRef]>]>


# Example Usage:
# <wait 2>
# <wait 3.5>
WaitCommand_CISK:
    type: task
    PostEvaluationCode:
    - flag <[player]> KQuests.temp.wait.amount:<[waitAmount].round_to_precision[0.01]>
    - flag <[player]> KQuests.temp.wait.override:true if:<[waitOverride].exists.and[<[waitOverride].equals[true]>]>

    script:
    - if <[attrVal].div[2].exists>:
        - define waitAmount <[attrVal]>

    - else if <[attrVal]> == override:
        - define waitOverride true


# Example Usage:
# <dataget t:npc n:x def:0>
# <dataget t:player n:y>
DatagetCommand_CISK:
    type: task
    debug: false
    commandData:
        attributeSubs:
            target: t|tr
            name: n

    PostEvaluationCode:
    - run ProduceFlaggableObject_CISK def.text:<[dataTarget]> save:realTarget

    - define realTarget <entry[realTarget].created_queue.determination.get[1]>
    - define data <[realTarget].flag[KQuests.data.<[dataName]>.value]>

    - determine <[data]>

    script:
    - choose <[attrKey]>:
        - case target:
            - define dataTarget <[attrVal]>

        - case name:
            - define dataName <[attrVal]>


# Example Usage:
# <datastore t:npc n:x v:10>
# <datastore t:player n:y v:Hello persistent>
# <datastore t:npc n:name v:<state get player name>>
DatastoreCommand_CISK:
    type: task
    debug: false
    commandData:
        attributeSubs:
            target: t|tr
            name: n
            value: v

    PostEvaluationCode:
    - run ProduceFlaggableObject_CISK def.text:<[dataTarget]> save:realTarget
    - define realTarget <entry[realTarget].created_queue.determination.get[1]>
    - flag <[realTarget]> KQuests.data.<[dataName]>.value:<[dataValue]>
    - flag <[realTarget]> KQuests.data.<[dataName]>.persistent:true if:<[dataPersistent].if_null[false].equals[true]>

    script:
    - choose <[attrKey]>:
        - case target:
            - define dataTarget <[attrVal]>

        - case name:
            - define dataName <[attrVal]>

        - case value:
            - define dataValue <[attrVal]>

        - case null:
            - if <[attrVal]> == persistent:
                - define dataPersistent true
