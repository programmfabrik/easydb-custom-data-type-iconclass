class CustomDataTypeIconclass extends CustomDataTypeWithCommons

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-iconclass.iconclass"

  #######################################################################
  # overwrite getCustomMaskSettings
  getCustomMaskSettings: ->
    if @ColumnSchema
      return @FieldSchema.custom_settings || {};
    else
      return {}

  #######################################################################
  # overwrite getCustomSchemaSettings
  getCustomSchemaSettings: ->
    if @ColumnSchema
      return @ColumnSchema.custom_settings || {};
    else
      return {}

  #######################################################################
  # overwrite getCustomSchemaSettings
  name: (opts = {}) ->
    if ! @ColumnSchema
      if opts?.callfrompoolmanager && opts?.name != ''
        return opts.name
      else
        return "noNameSet"
    else
      return @ColumnSchema?.name

  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.iconclass.name")

  #######################################################################
  # returns markup to display in expert search
  #######################################################################
  renderSearchInput: (data) ->
      that = @
      if not data[@name()]
          data[@name()] = {}

      form = @renderEditorInput(data, '', {})

      CUI.Events.listen
            type: "data-changed"
            node: form
            call: =>
                CUI.Events.trigger
                    type: "search-input-change"
                    node: form
      form.DOM

  #######################################################################
  # make searchfilter for expert-search
  #######################################################################
  getSearchFilter: (data) ->
      that = @
      # popup with tree: find all records which have the given uri in their ancestors
      filter =
          type: "complex"
          search: [
              type: "in"
              bool: "must"
              fields: [ @path() + '.' + @name() + ".conceptAncestors" ]
          ]
      if ! data[@name()]
          filter.search[0].in = [ null ]
      else if data[@name()]?.conceptURI
          filter.search[0].in = [data[@name()].conceptURI]
      else
          filter = null

      filter


  #######################################################################
  # make tag for expert-search
  #######################################################################
  getQueryFieldBadge: (data) ->
      if ! data[@name()]
          value = $$("field.search.badge.without")
      else if ! data[@name()]?.conceptURI
          value = $$("field.search.badge.without")
      else
          value = data[@name()].conceptName

      name: @nameLocalized()
      value: value

  #######################################################################
  # handle suggestions-menu  (POPOVER)
  #######################################################################
  __updateSuggestionsMenu: (cdata, cdata_form, input_searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 50

    # show loader
    menu_items = [
        text: $$('custom.data.type.iconclass.modal.form.loadingSuggestions')
        icon_left: new CUI.Icon(class: "fa-spinner fa-spin")
        disabled: true
    ]
    itemList =
      items: menu_items
    suggest_Menu.setItemList(itemList)

    setTimeout ( ->

        input_searchstring = input_searchstring.replace /^\s+|\s+$/g, ""
        input_searchstring = input_searchstring.replace '*', ''
        input_searchstring = input_searchstring.replace ' ', ''

        # check if searchstring starts with a notation (number)
        searchStringIsNotation = false
        if isNaN(input_searchstring[0]) == false
          searchStringIsNotation = true

        suggest_Menu.show()

        # limit-Parameter
        countSuggestions = 20

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        searchUrl = 'https://jsontojsonp.gbv.de/?url=http%3A%2F%2Ficonclass.org%2Frkd%2F1%2F%3Fq%3D' + encodeURIComponent(input_searchstring) + '%26q_s%3D1%26fmt%3Djson'
        if searchStringIsNotation
          searchUrl = 'https://jsontojsonp.gbv.de/?url=http%3A%2F%2Ficonclass.org%2F' + encodeURIComponent(input_searchstring) + '.json'

        activeFrontendLanguage = that.getFrontendLanguage()

        # start request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: searchUrl)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->
            extendedInfo_xhr = { "xhr" : undefined }
            if !searchStringIsNotation
              if data.records
                data = data.records
            else
              if data.length != 0
                data = [data]
            menu_items = []
            for suggestion, key in data
              do(key) ->
                # get label in users frontendLanguage
                if suggestion.txt[activeFrontendLanguage]
                  suggestionsLabel = suggestion.txt[activeFrontendLanguage]
                else
                  suggestionsLabel = suggestion.txt.de
                suggestionsLabel = suggestion.n + ' ' + suggestionsLabel
                suggestionsURI = 'http://iconclass.org/' + suggestion.n
                item =
                  text: suggestionsLabel
                  value: suggestion
                  tooltip:
                    markdown: true
                    placement: "ne"
                    content: (tooltip) ->
                      # show infopopup
                      encodedURI = encodeURIComponent(suggestionsURI)
                      that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.iconclass.modal.form.popup.loadingstring'))
                menu_items.push item
            # create new menu with suggestions
            itemList =
              onClick: (ev2, btn) ->
                  iconclassInfo = btn.getOpt("value")

                  cdata.conceptAncestors = []
                  # if treeview, add ancestors
                  if iconclassInfo?.p?.length > 0
                    # save ancestor-uris to cdata
                    for ancestor in iconclassInfo.p
                      cdata.conceptAncestors.push 'http://iconclass.org/' + ancestor
                  # add own uri to ancestor-uris
                  cdata.conceptAncestors.push 'http://iconclass.org/' + iconclassInfo.n

                  # lock conceptURI in savedata
                  cdata.conceptURI = 'http://iconclass.org/' + iconclassInfo.n
                  # lock conceptFulltext in savedata
                  cdata._fulltext = ez5.IconclassUtil.getFullTextFromObject iconclassInfo, false
                  # lock standard in savedata
                  cdata._standard = ez5.IconclassUtil.getStandardTextFromObject that, iconclassInfo, cdata, false

                  if iconclassInfo?.txt[activeFrontendLanguage]
                    cdata.conceptName = iconclassInfo?.txt[activeFrontendLanguage]
                  else
                    cdata.conceptName = iconclassInfo?.txt?.de
                  cdata.conceptName = iconclassInfo.n + ' ' + cdata.conceptName

                  # update the layout in form
                  that.__updateResult(cdata, layout, opts)
                  @

              items: menu_items

            # if no suggestions: set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: $$('custom.data.type.iconclass.modal.form.popup.suggest.nohit')
                  value: undefined
                ]
            suggest_Menu.setItemList(itemList)
            suggest_Menu.show()
        )
    ), delayMillisseconds


  #######################################################################
  # render editorinputform
  renderEditorInput: (data, top_level_data, opts) ->
    #console.error @, data, top_level_data, opts, @name(), @fullName()

    if not data[@name()]
        cdata = {
            conceptName : ''
            conceptURI : ''
        }
        data[@name()] = cdata
    else
        cdata = data[@name()]
    @__renderEditorInputPopover(data, cdata, opts)

  #######################################################################
  # get frontend-language
  getFrontendLanguage: () ->
    # language
    desiredLanguage = ez5.loca.getLanguage()
    desiredLanguage = desiredLanguage.split('-')
    desiredLanguage = desiredLanguage[0]

    desiredLanguage

  #######################################################################
  # show tooltip with loader and then additional info (for extended mode)
  __getAdditionalTooltipInfo: (encodedURI, tooltip, extendedInfo_xhr, context = null) ->
    that = @
    if context
      that = context
    # abort eventually running request
    if extendedInfo_xhr.xhr != undefined
      extendedInfo_xhr.xhr.abort()

    # start new request to DANTE-API
    url = 'https://jsontojsonp.gbv.de/?url=' + encodedURI + '.json'
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: url)
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = ez5.IconclassUtil.getPreview(data, that.getFrontendLanguage())
      if htmlContent
        tooltip.DOM.innerHTML = htmlContent
      else
        tooltip.DOM.innerHTML = '<div class="iconclassTooltip" style="padding: 10px">' + $$('custom.data.type.iconclass.modal.form.popup.no_information_found') + '</div>'
      tooltip.autoSize()
    )
    return

  #######################################################################
  # build treeview-Layout with treeview
  buildAndSetTreeviewLayout: (popover, layout, cdata, cdata_form, that, topMethod = 0, returnDfr = false, opts) ->
    that = @
    treeview = new Iconclass_ListViewTree(popover, layout, cdata, cdata_form, that, opts)
    activeFrontendLanguage = that.getFrontendLanguage()

    # maybe deferred is wanted?
    if returnDfr == false
      treeview.getTopTreeView(activeFrontendLanguage)
    else
      treeviewDfr = treeview.getTopTreeView(activeFrontendLanguage)

    treeviewPane = new CUI.Pane
        class: "cui-pane iconclass_treeviewPane"
        top:
            content: [
                new CUI.PaneHeader
                    left:
                        content:
                            new CUI.Label(text: $$('custom.data.type.iconclass.modal.form.popup.choose'))
            ]
        center:
            content: [
                treeview.treeview
              ,
                cdata_form
            ]

    @popover.setContent(treeviewPane)

    # maybe deferred is wanted?
    if returnDfr == false
      return treeview
    else
      return treeviewDfr

  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, data, cdata, layout, opts) ->
    that = @

    # init popover
    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"

    # do search-request for all the top-entrys of vocabulary
    @buildAndSetTreeviewLayout(@popover, layout, cdata, null, that, 1, false, opts)

    @popover.show()

  #######################################################################
  # create form (POPOVER)
  #######################################################################
  __getEditorFields: (cdata) ->
    that = @
    fields = []

    # searchfield (autocomplete)
    option =  {
          type: CUI.Input
          class: "commonPlugin_Input"
          undo_and_changed_support: false
          form:
              label: $$("custom.data.type.iconclass.modal.form.text.searchbar")
          placeholder: $$("custom.data.type.iconclass.modal.form.text.searchbar.placeholder")
          name: "searchbarInput"
        }
    fields.push option

    fields

  #######################################################################
  # checks the form and returns status
  getDataStatus: (cdata) ->
      if (cdata)
        if cdata.conceptURI and cdata.conceptName
          # check url for valididy
          uriCheck = false
          if cdata.conceptURI.trim() != ''
            uriCheck = true

          nameCheck = if cdata.conceptName then cdata.conceptName.trim() else undefined

          if uriCheck and nameCheck
            return "ok"

          if cdata.conceptURI.trim() == '' || cdata.conceptName.trim() == ''
            return "empty"

          return "invalid"
      return "empty"

  #######################################################################
  # renders the "resultmask" (outside popover)
  __renderButtonByData: (cdata) ->
    that = @
    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.iconclass.edit.no_entry")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.iconclass.edit.no_valid_entry")).DOM

    extendedInfo_xhr = { "xhr" : undefined }

    # active frontendlanguage
    frontendLanguage = ez5.loca.getLanguage()

    # default label is conceptName
    outputLabel = cdata.conceptName

    # logic: if the conceptLabel is not set by hand and it is available in the given frontendlanguage -->
    #         choose label from _standard.l10n
    if cdata?._standard?.l10ntext?[frontendLanguage] && cdata?.conceptNameChosenByHand != true
      outputLabel = cdata._standard.l10ntext[frontendLanguage]

    # output Button with Name of picked dante-Entry and URI
    encodedURI = encodeURIComponent(cdata.conceptURI)
    new CUI.HorizontalLayout
      maximize: true
      left:
        content:
          new CUI.Label
            centered: false
            text: outputLabel
      center:
        content:
          new CUI.ButtonHref
            name: "outputButtonHref"
            class: "pluginResultButton"
            appearance: "link"
            size: "normal"
            href: cdata.conceptURI
            target: "_blank"
            class: "cdt_iconclass_smallMarginTop"
            tooltip:
              markdown: true
              placement: 'nw'
              content: (tooltip) ->
                # get details-data
                that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                # loader, until details are xhred
                new CUI.Label(icon: "spinner", text: $$('custom.data.type.iconclass.modal.form.popup.loadingstring'))
      right: null
    .DOM

  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    if Object.keys(custom_settings).length == 0
      ['Ohne Optionen']

CustomDataType.register(CustomDataTypeIconclass)