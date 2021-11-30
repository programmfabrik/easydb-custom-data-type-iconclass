class iconclassUpdate

  __start_update: ({server_config, plugin_config}) ->
      # Check if Iconclass-API is fully available. This will take at least 10 seconds. Dont panic.
      testURL = 'https://jsontojsonp.gbv.de/?url=http%3A%2F%2Ficonclass.org%2F1.json'
      availabilityCheck_xhr = new (CUI.XHR)(url: testURL)
      availabilityCheck_xhr.start()
      .done((data, status, statusText) ->
        if data?.n == '1'
          ez5.respondSuccess({
            state: {
                "start_update": new Date().toUTCString()
                "databaseLanguages" : server_config.base.system.languages.database
                "default_language" : server_config.base.system.update_interval_iconclass.default_language
            }
          })
        else
          ez5.respondError("custom.data.type.iconclass.update.error.generic", {error: "Test on iconclass-API was not successfull!"})
      )

  __updateData: ({objects, plugin_config, state}) ->
    that = @
    objectsMap = {}
    iconclassUris = []
    databaseLanguages = state.databaseLanguages
    default_language = state.default_language

    # check and set default-language
    defaultLanguage = false
    if default_language
      if (typeof default_language == 'string' || default_language instanceof String)
        if default_language.length == 2
          defaultLanguage = default_language

    for object in objects
      if not (object.identifier and object.data)
        continue
      ICONCLASSUri = object.data.conceptURI
      if CUI.util.isEmpty(ICONCLASSUri)
        continue
      if not objectsMap[ICONCLASSUri]
        objectsMap[ICONCLASSUri] = [] # It is possible to have more than one object with the same ID in different objects.
      objectsMap[ICONCLASSUri].push(object)
      iconclassUris.push(ICONCLASSUri)

    if iconclassUris.length == 0
      return ez5.respondSuccess({payload: []})

    timeout = plugin_config.update?.timeout or 0
    timeout *= 1000 # The configuration is in seconds, so it is multiplied by 1000 to get milliseconds.

    # unique iconclass-uris
    iconclassUris = iconclassUris.filter((x, i, a) => a.indexOf(x) == i)

    objectsToUpdate = []

    # update the uri's one after the other
    chunkWorkPromise = CUI.chunkWork.call(@,
      items: iconclassUris
      chunk_size: 1
      call: (items) =>
        #for uri in items
        uri = items[0]
        #console.error "uri", uri
        originalUri = items[0]
        uriEncoded = uri.replace(/ /g, "%20")
        uriEncoded = uriEncoded.replace(/,/g, "%2C")
        uri = 'https://jsontojsonp.gbv.de/?url='  + CUI.encodeURIComponentNicely(uriEncoded) + '.json'

        deferred = new CUI.Deferred()
        extendedInfo_xhr = new (CUI.XHR)(url: uri)
        extendedInfo_xhr.start().done((data, status, statusText) ->
          # shouldnt happen, but: skip, if a record was not found (maybe deleted in iconclass, wrong URI ...)
          if data?.n
            # validation-test on data.preferredName (obligatory)
            if data?.txt
              resultsUri = 'http://iconclass.org/' + data.n
              # parse every record of this URI
              for cdataFromObjectsMap, objectsMapKey in objectsMap[originalUri]
                cdataFromObjectsMap = cdataFromObjectsMap.data

                # init updated cdata
                updatedcdata = {}
                # conceptUri
                updatedcdata.conceptURI = 'http://iconclass.org/' + data.n
                # conceptAncestors
                updatedcdata.conceptAncestors = []

                conceptAncestors = []
                # if treeview, add ancestors
                if data?.p?.length > 0
                  # save ancestor-uris to cdata
                  for ancestor in data.p
                    updatedcdata.conceptAncestors.push 'http://iconclass.org/' + ancestor
                    # add own uri to ancestor-uris
                updatedcdata.conceptAncestors.push 'http://iconclass.org/' + data.n

                # conceptName

                # change only, if a frontendLanguage is set AND it is not a manually chosen label
                if cdataFromObjectsMap?.frontendLanguage?.length == 2
                  updatedcdata.frontendLanguage = cdataFromObjectsMap.frontendLanguage
                  if cdataFromObjectsMap?.conceptNameChosenByHand == false || ! cdataFromObjectsMap.hasOwnProperty('conceptNameChosenByHand')
                    updatedcdata.conceptNameChosenByHand = false
                    if data['txt']
                      # if a preflabel exists in given frontendLanguage or without language (person / corporate)
                      if data['txt'][cdataFromObjectsMap.frontendLanguage]
                        if data['txt']?[cdataFromObjectsMap.frontendLanguage]
                          updatedcdata.conceptName = data['txt'][cdataFromObjectsMap.frontendLanguage]

                # if no conceptName is given yet (f.e. via scripted imports..)
                #   --> choose a label and prefer the configured default language
                if ! updatedcdata?.conceptName
                  # defaultLanguage given?
                  if defaultLanguage
                    if data['txt']?[defaultLanguage]
                      updatedcdata.conceptName = data['txt'][defaultLanguage]
                  else
                    if data.txt?.de
                      updatedcdata.conceptName = data.txt.de
                    else if data.txt?.en
                      updatedcdata.conceptName = data.txt.en
                    else
                      updatedcdata.conceptName = data.txt[Object.keys(data.txt)[0]]

                updatedcdata.conceptName = data.n + ' - ' + updatedcdata.conceptName

                # _standard & _fulltext
                updatedcdata._standard = ez5.IconclassUtil.getStandardTextFromObject null, data, cdataFromObjectsMap, databaseLanguages
                updatedcdata._fulltext = ez5.IconclassUtil.getFullTextFromObject data, databaseLanguages

                # aggregate in objectsMap
                if that.__hasChanges(objectsMap[originalUri][objectsMapKey].data, updatedcdata)
                  objectsMap[originalUri][objectsMapKey].data = updatedcdata
                  objectsToUpdate.push(objectsMap[originalUri][objectsMapKey])
          deferred.resolve()
        ).fail( =>
         deferred.reject()
        )
        return deferred.promise()
    )

    chunkWorkPromise.done(=>
     ez5.respondSuccess({payload: objectsToUpdate})
    ).fail(=>
     ez5.respondError("custom.data.type.iconclass.update.error.generic", {error: "Error connecting to Iconclass"})
    )

  __hasChanges: (objectOne, objectTwo) ->
    for key in ["conceptName", "conceptURI", "_standard", "_fulltext", "conceptAncestors", "frontendLanguage"]
      if not CUI.util.isEqual(objectOne[key], objectTwo[key])
        return true
    return false

  main: (data) ->
    if not data
      ez5.respondError("custom.data.type.iconclass.update.error.payload-missing")
      return

    for key in ["action", "server_config", "plugin_config"]
      if (!data[key])
        ez5.respondError("custom.data.type.iconclass.update.error.payload-key-missing", {key: key})
        return

    if (data.action == "start_update")
      @__start_update(data)
      return
    else if (data.action == "update")
      if (!data.objects)
        ez5.respondError("custom.data.type.iconclass.update.error.objects-missing")
        return

      if (!(data.objects instanceof Array))
        ez5.respondError("custom.data.type.iconclass.update.error.objects-not-array")
        return

      # NOTE: state for all batches
      # this contains any arbitrary data the update script might need between batches
      # it should be sent to the server during 'start_update' and is included in each batch
      if (!data.state)
        ez5.respondError("custom.data.type.iconclass.update.error.state-missing")
        return

      # NOTE: information for this batch
      # this contains information about the current batch, espacially:
      #   - offset: start offset of this batch in the list of all collected values for this custom type
      #   - total: total number of all collected custom values for this custom type
      # it is included in each batch
      if (!data.batch_info)
        ez5.respondError("custom.data.type.iconclass.update.error.batch_info-missing")
        return

      # TODO: check validity of config, plugin (timeout), objects...
      @__updateData(data)
      return
    else
      ez5.respondError("custom.data.type.iconclass.update.error.invalid-action", {action: data.action})

module.exports = new iconclassUpdate()
