##
## [KPM]
## Scripts in this file are involved in managing and generating general information about addons
## either on server start or when KPM is reloaded.
##
## @Author: Zyad (@itszyad / ITSZYAD#9280)
## @Date: Dec 2023
## @Script Ver: v1.0
##
## ------------------------------------------END HEADER-------------------------------------------

PackageIndexer_KPM:
    type: task
    debug: false
    script:
    ## Main script which indexes all Kingdoms addons currently installed in the
    ## '../Kingdoms/addons' folder.
    ##
    ## The indexing process involves looping through all Kingdoms addons, reading their contents,
    ## creating a SHA-256 hash unique to each addon, and adding a server-side flag indicating
    ## each addon's existence and associated information.
    ##
    ## >>> [Void]

    - foreach <util.list_files[../Kingdoms/addons]> as:subdirectory:
        - if !<util.has_file[../Kingdoms/addons/<[subdirectory]>/package.yml]>:
            - foreach next

        - run SeekFolders_KPM def.subdirectory:../Kingdoms/addons/<[subdirectory]> save:result
        - define result <entry[result].created_queue.determination.get[1]>

        # If the helper task returned both lists empty it means that the loop just came across a
        # regular file in the addons folder- which should be ignored.
        - if <[result].get[dirList].include[<[result].get[contentList]>].size> == 0:
            - foreach next

        - define dirList <[result].get[dirList].parse_tag[<[parse_value].split[/].remove[1|2|3].separated_by[/]>]>
        - define resultString <[result].get[contentList].unseparated>
        - define addonHash <[resultString].utf8_encode.gzip_compress.hash[SHA256]>

        # Loading YAML file and check if the name and hash of the addon is recurrent.
        - ~yaml load:../Kingdoms/addons/<[subdirectory]>/package.yml id:descriptor
        - define addonName <yaml[descriptor].read[package.name]>

        - narrate format:notice "Reading addon: <[addonName].underline>..."

        - if <server.flag[addons.addonList].keys.if_null[<list[]>].contains[<[addonName]>]>:
            - run GenerateKingdomsDebug def.category:GenericError def.message:<element[Found two addons with the same provided name in their package.yml. Addons will not be indexed if there is an existing addon with an identical name. Skipping...]> def.silent:true
            - narrate format:warning "Found two addons with the same provided name in their package.yml. Addons will not be indexed if there is an existing addon with an identical name. Skipping..."
            - foreach next

        - run IsPackageDescriptorValid_KPM def.descriptor:<yaml[descriptor].read[]> def.path:../Kingdoms/addons/<[subdirectory]> save:isDescValid
        - define isDescValid <entry[isDescValid].created_queue.determination.get[1]>

        - if !<[isDescValid]>:
            # IsPackageDescriptorValid_KPM will generate an exact error message detailing which
            # property of the descriptor is wrong. This message is just some boilerplate.
            - narrate format:warning "Skipping addon: <[addonName].color[red]> until all errors in its package.yml are fixed..."
            - yaml unload id:descriptor
            - foreach next

        - narrate format:notice "Indexing addon..."

        - define truncatedHash <[addonHash].as[element].substring[8,16]>
        - definemap addonInfo:
            name: <[addonName]>
            hash: <[addonHash]>
            authors: <yaml[descriptor].read[package.authors]>
            version: <yaml[descriptor].read[package.version]>
            rootDir: <element[Kingdoms/addons/<[subdirectory]>]>
            allFiles: <[dirList]>
            loaded: false
            __descriptor: <yaml[descriptor].read[]>

        - flag server addons.addonList.<[addonName]>:<[addonInfo]>
        - ~yaml unload id:descriptor

    - foreach <server.flag[addons.addonList]> as:addonInfo key:addonName:
        - define rootDir <[addonInfo].get[rootDir]>
        - define descriptor <[addonInfo].get[__descriptor]>

        - run PackageDependencyChecker_KPM def.descriptor:<[descriptor]> def.path:<[rootDir]>

        - flag server addons.addonList.<[addonName]>.missingDependencies:<server.flag[datahold.KPM.missingDependencies.<[addonName]>].if_null[<list[]>]>
        - flag server addons.addonList.<[addonName]>.__descriptor:!
        - flag server datahold.KPM.missingDependencies.<[addonName]>:!


SeekFolders_KPM:
    type: task
    debug: false
    definitions: subdirectory
    script:
    ## Recursively seeks through the provided subdirectory to help KPM generate signatures for
    ## different add-ons and create a map of which files are where.
    ##
    ## subdirectory : [ElementTag<String>]
    ##
    ## >>> [MapTag<
    ##         <ListTag<ElementTag<String>>>,
    ##         <ListTag<ElementTag<String>>>
    ##     >]

    - define contentList <list[]>
    - define dirList <list[]>

    - foreach <util.list_files[<[subdirectory]>].if_null[<list[]>]> as:item:

        # If the current item is a folder
        - if <util.list_files[<[subdirectory]>/<[item]>].if_null[<list[]>].size> > 0:
            - run <script.name> def.subdirectory:<[subdirectory]>/<[item]> save:result
            - define result <entry[result].created_queue.determination.get[1]>

            - define contentList <[contentList].include[<[result].get[contentList]>]>
            - define dirList <[dirList].include[<[result].get[dirList].if_null[<list[]>]>]>

        # TODO: Figure out if making it ignore all files but .dsc is actually a good design choice
        # TODO/ or if this whille bite me in the ass later...
        - else if <[item].split[.].get[2].to_lowercase.is_in[dsc]>:
            - yaml load:<[subdirectory]>/<[item]> id:script

            - define contentList:->:<yaml[script].to_text>
            - define dirList:->:<element[<[subdirectory]>/<[item]>]>

            - yaml unload id:script

    - definemap output:
        contentList: <[contentList]>
        dirList: <[dirList]>

    - determine <[output]>


PackageIndexer_Handler:
    type: world
    debug: false
    events:
        on server start priority:2:
        - if <server.has_flag[addons.addonList]>:
            - flag server addons.addonList:!

        - ~run PackageIndexer_KPM

        on shutdown:
        - flag server addons.addonList:!
        # TODO: Add script which deletes all addon folders from working scripts folder.
