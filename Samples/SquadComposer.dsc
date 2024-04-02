##
## Scripts in this file relate to the squad composer window of the squad manager. This lets players
## create new squads to add to a certain SM.
##
## @Author: Zyad (@itszyad / ITSZYAD#9280)
## @Date: Jun 2023
## @Script Ver: v1.0
##
##ignorewarning invalid_data_line_quotes
## ------------------------------------------END HEADER-------------------------------------------

SquadCompositionOneSoldier_Item:
    type: item
    material: leather_helmet
    display name: <italic><bold>Add One Swordsman
    mechanisms:
        hides: all
    flags:
        displayItem: true
        amount: 1
        unitType: swordsmen


SquadCompositionFiveSoldiers_Item:
    type: item
    material: chainmail_helmet
    display name: <gray><italic><bold>Add Five Swordsmen
    mechanisms:
        hides: all
    flags:
        displayItem: true
        amount: 5
        unitType: swordsmen


SquadCompositionOneArcher_Item:
    type: item
    material: bow
    display name: <italic><bold>Add One Archer
    mechanisms:
        hides: all
    flags:
        displayItem: true
        amount: 1
        unitType: archers


SquadCompositionFiveArchers_Item:
    type: item
    material: bow
    display name: <gray><italic><bold>Add Five Archers
    mechanisms:
        hides: all
    flags:
        displayItem: true
        amount: 5
        unitType: archers


SquadCompositionCancel_Item:
    type: item
    material: player_head
    display name: <red><bold>Cancel
    mechanisms:
        skull_skin: 5ecfabf0-5253-47b0-a44d-9a0c924081b9|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYmViNTg4YjIxYTZmOThhZDFmZjRlMDg1YzU1MmRjYjA1MGVmYzljYWI0MjdmNDYwNDhmMThmYzgwMzQ3NWY3In19fQ==


SquadCompositionAccept_Item:
    type: item
    material: player_head
    display name: <green><bold>Accept
    mechanisms:
        skull_skin: afb405c1-16ea-4a23-883f-97867e7db3f9|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvYTc5YTVjOTVlZTE3YWJmZWY0NWM4ZGMyMjQxODk5NjQ5NDRkNTYwZjE5YTQ0ZjE5ZjhhNDZhZWYzZmVlNDc1NiJ9fX0=


SquadCompositionInfo_Item:
    type: item
    material: player_head
    display name: <gold><bold>Squad Info
    lore:
        - Total Manpower Required<&co>
        - <bold>0
    mechanisms:
        skull_skin: da4d885d-2505-4f25-bfee-a0de07950191|eyJ0ZXh0dXJlcyI6eyJTS0lOIjp7InVybCI6Imh0dHA6Ly90ZXh0dXJlcy5taW5lY3JhZnQubmV0L3RleHR1cmUvZDAxYWZlOTczYzU0ODJmZGM3MWU2YWExMDY5ODgzM2M3OWM0MzdmMjEzMDhlYTlhMWEwOTU3NDZlYzI3NGEwZiJ9fX0=


SquadComposition_Interface:
    type: inventory
    inventory: chest
    gui: true
    title: Compose a Squad
    slots:
    - [SquadCompositionOneSoldier_Item] [SquadCompositionFiveSoldiers_Item] [SquadInfoSeparator_Item] [] [] [] [] [] []
    - [] [] [SquadInfoSeparator_Item] [] [] [] [] [] []
    - [] [] [SquadInfoSeparator_Item] [] [] [] [] [] []
    - [] [] [SquadInfoSeparator_Item] [] [] [] [] [] []
    - [] [] [SquadInfoSeparator_Item] [] [] [] [] [] []
    - [SquadCompositionCancel_Item] [SquadCompositionAccept_Item] [SquadCompositionInfo_Item] [] [] [] [] [] []


SquadComposition_Handler:
    type: world
    events:
        on player clicks item in SquadComposition_Interface:
        - ratelimit <player> 1t

        - if <context.item.has_flag[displayItem]>:
            - determine passively cancelled
            - adjust <player> item_on_cursor:<context.item>

        - else if <player.item_on_cursor.has_flag[displayItem]> && <context.click> == LEFT && <context.item.material.name> == air:
            - define placeItem <player.item_on_cursor>
            - define squadInfoItemSlot <context.inventory.find_item[SquadCompositionInfo_Item]>
            - define squadInfoItem <context.inventory.slot[<[squadInfoItemSlot]>]>
            - flag <player> datahold.armies.manpower:<player.flag[datahold.armies.manpower].if_null[0].add[<[placeItem].flag[amount]>]>
            - flag <player> datahold.armies.squadComp:->:<map[unit=<[placeItem].flag[unitType]>;amount=<[placeItem].flag[amount]>]>

            - inventory adjust slot:<[squadInfoItemSlot]> "lore:Total Manpower Required:|<bold><player.flag[datahold.armies.manpower].if_null[0]>" destination:<context.inventory>
            - adjust def:placeItem display:<[placeItem].display.split[ ].remove[1].space_separated>

            - flag <[placeItem]> displayItem:!

            - inventory set slot:<context.slot> origin:<[placeItem]> destination:<context.inventory>
            - determine cancelled

        on player right clicks in SquadComposition_Interface:
        - ratelimit <player> 1t

        - if <player.item_on_cursor.material.name> != air:
            - adjust <player> item_on_cursor:<item[air]>
            - determine cancelled

        - else if <context.item.material.name> != air:
            - define squadInfoItemSlot <context.inventory.find_item[SquadCompositionInfo_Item]>
            - define squadInfoItem <context.inventory.slot[<[squadInfoItemSlot]>]>
            - flag <player> datahold.armies.manpower:<player.flag[datahold.armies.manpower].if_null[0].sub[<context.item.flag[amount]>]>
            - flag <player> datahold.armies.squadComp:<-:<map[unit=<[squadInfoItem].flag[unitType]>;amount=<[squadInfoItem].flag[amount]>]>

            - inventory adjust slot:<[squadInfoItemSlot]> "lore:Total Manpower Required:|<bold><player.flag[datahold.armies.manpower].if_null[0]>" destination:<context.inventory>
            - inventory set slot:<context.slot> origin:air destination:<context.inventory>

            - determine cancelled

        on player clicks SquadCompositionAccept_Item in SquadComposition_Interface:
        - define SMLocation <player.flag[datahold.armies.squadManagerLocation]>
        - define kingdom <player.flag[kingdom]>
        - define squadList <proc[GetKingdomSquads].context[<[kingdom]>]>
        - define squadLimit <proc[GetSquadLimit].context[<[SMLocation]>]>
        - define stationCapacity <proc[GetStationingCapacity].context[<[SMLocation]>]>
        - define squadSizeLimit <proc[GetMaxSquadSize].context[<[SMLocation]>]>
        - define totalManpower <player.flag[datahold.armies.manpower]>

        - if <[squadList].size> >= <[squadLimit]>:
            - narrate format:callout "These barracks already have the maximum amount of squads stationed in them! You must upgrade it first."
            - determine cancelled

        - if <[squadList].size> >= <[stationCapacity]>:
            - narrate format:callout "These barracks do not have the capacity to hold a squad of this size. You must add more beds first."
            - determine cancelled

        - if <[totalManpower]> > <[squadSizeLimit]>:
            - narrate format:callout "These barracks can only hold <[squadSizeLimit].color[red]> soldiers per squad."
            - determine cancelled

        - define squadComp <player.flag[datahold.armies.squadComp]>
        - define unitTypes <[squadComp].parse_tag[<[parse_value].get[unit]>]>
        - define squadCompSorted <map[]>

        - foreach <[squadComp]>:
            - define squadCompSorted.<[value].get[unit]>:+:<[value].get[amount]>

        - definemap squadMap:
            npcList: <list[]>
            squadComp: <[squadCompSorted]>
            totalManpower: <[totalManpower]>
            hasSpawned: false

        - run flagvisualizer def.flag:<[squadMap]> def.flagName:squadMap

        - flag <player> datahold.armies.squadMap:<[squadMap]>
        - flag <player> noChat.armies.namingSquad
        - narrate format:callout "Please provide your squad a name (you can use spaces). Or type 'cancel':"
        - inventory close

        on player chats flagged:noChat.armies.namingSquad:
        - if <context.message.to_lowercase> == cancel:
            - narrate format:callout "Squad creation cancelled."
            - flag <player> datahold.armies.namingSquad:!
            - flag <player> noChat.armies:!
            - determine cancelled

        - define kingdom <player.flag[kingdom]>
        - define displayName <context.message>
        - define SMLocation <player.flag[datahold.armies.squadManagerLocation]>
        - define squadMap <player.flag[datahold.armies.squadMap]>

        - run CreateSquadReference def.kingdom:<[kingdom]> def.SMLocation:<[SMLocation]> def.displayName:<[displayName]> def.totalManpower:<[squadMap].get[totalManpower]> def.squadComp:<[squadMap].get[squadComp]>

        - flag <player> datahold.armies.namingSquad:!
        - flag <player> noChat.armies:!
        - determine cancelled

        on player clicks SquadCompositionCancel_Item in SquadComposition_Interface:
        - flag <player> datahold.armies.manpower:!
        - flag <player> datahold.armies.squadComp:!
        - inventory open d:SquadManager_Interface

        on player closes SquadComposition_Interface:
        - flag <player> datahold.armies.manpower:!
        - flag <player> datahold.armies.squadComp:!
