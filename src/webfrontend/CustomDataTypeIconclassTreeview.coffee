##################################################################################
#  1. Class for use of ListViewTree
#   - uses the iconclass-API as source for the treeview
#
#  2. extends CUI.ListViewTreeNode
#   - offers preview and selection of iconclass-records for treeview-nodes
##################################################################################

class Iconclass_ListViewTree

    #############################################################################
    # construct
    #############################################################################
    constructor: (@popover = null, @editor_layout = null, @cdata = null, @cdata_form = null, @context = null, @iconclass_opts = {}) ->

        options =
          class: "customPlugin_Treeview"
          cols: ["maximize", "auto"]
          fixedRows: 0
          fixedCols: 0
          no_hierarchy : false

        that = @

        treeview = new CUI.ListViewTree(options)
        treeview.render()
        treeview.root.open()

        # append loader-row
        row = new CUI.ListViewRow()
        column = new CUI.ListViewColumn(
          colspan: 2
          element: new CUI.Label(icon: "spinner", appearance: "title",text: $$("custom.data.type.iconclass.modal.form.popup.loadingstringtreeview"))
        )
        row.addColumn(column)
        treeview.appendRow(row)
        treeview.root.open()

        @treeview = treeview
        @treeview


    #############################################################################
    # get top hierarchy
    #############################################################################
    getTopTreeView: (activeFrontendLanguage) ->

        dfr = new CUI.Deferred()

        that = @
        topTree_xhr = { "xhr" : undefined }

        # start new request to DANTE-API
        url = 'https://jsontojsonp.gbv.de/?url=' + encodeURIComponent('http://iconclass.org/json/?notation=1&notation=2&notation=3&notation=4&notation=5&notation=6&notation=7&notation=8&notation=9')
        topTree_xhr.xhr = new (CUI.XHR)(url: url)
        topTree_xhr.xhr.start().done((data, status, statusText) ->
          # remove loading row (if there is one)
          if that.treeview.getRow(0)
            that.treeview.removeRow(0)

          # add lines from request
          for iconclassEntry, key in data
            if iconclassEntry?.txt[activeFrontendLanguage]
              prefLabel = iconclassEntry?.txt[activeFrontendLanguage]
            else
              prefLabel = iconclassEntry?.txt?.de
            prefLabel = iconclassEntry.n + ' - ' + prefLabel

            # narrower?
            if iconclassEntry.c?.length > 0
              hasNarrowers = true
            else
              hasNarrowers = false

            newNode = new Iconclass_ListViewTreeNode
                selectable: false
              ,
                prefLabel: prefLabel
                uri: 'http://iconclass.org/' + iconclassEntry.n
                iconclassInfo: iconclassEntry
                hasNarrowers: hasNarrowers
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                context: that.context
                iconclass_opts: that.iconclass_opts
                editor_layout: that.editor_layout
                activeFrontendLanguage: activeFrontendLanguage

            that.treeview.addNode(newNode)
          # refresh popup, because its content has changed (new height etc)
          CUI.Events.trigger
            node: that.popover
            type: "content-resize"
          dfr.resolve()
          dfr.promise()
        )

        dfr

##############################################################################
# custom tree-view-node
##############################################################################
class Iconclass_ListViewTreeNode extends CUI.ListViewTreeNode

    prefLabel = ''
    uri = ''

    constructor: (@opts={}, @additionalOpts={}) ->

        super()

        @prefLabel = @additionalOpts.prefLabel
        @uri = @additionalOpts.uri
        @iconclassInfo = @additionalOpts.iconclassEntry
        @popover = @additionalOpts.popover
        @cdata = @additionalOpts.cdata
        @cdata_form = @additionalOpts.cdata_form
        @context = @additionalOpts.context
        @iconclass_opts = @additionalOpts.iconclass_opts
        @editor_layout = @additionalOpts.editor_layout
        @activeFrontendLanguage = @additionalOpts.activeFrontendLanguage

    #########################################
    # function getChildren
    getChildren: =>
        that = @
        dfr = new CUI.Deferred()
        children = []

        # start new request to iconclass-API
        notations = @additionalOpts.iconclassInfo.c;
        notationsString = ''
        for notation, notationKey in notations
          notationsString = notationsString + '&notation=' + encodeURIComponent(notation)

        # get infos for all the children at once
        url = 'https://jsontojsonp.gbv.de/?url=' + encodeURIComponent('http://iconclass.org/json/?' + notationsString);
        getChildren_xhr ={ "xhr" : undefined }
        getChildren_xhr.xhr = new (CUI.XHR)(url: url)
        getChildren_xhr.xhr.start().done((data, status, statusText) ->
          for iconclassEntry, key in data
            if iconclassEntry?.txt[@activeFrontendLanguage]
              prefLabel = iconclassEntry?.txt[@activeFrontendLanguage]
            else
              prefLabel = iconclassEntry?.txt?.de
            prefLabel = iconclassEntry.n + ' - ' + prefLabel

            # narrowers?
            if iconclassEntry.c?.length > 0
              hasNarrowers = true
            else
              hasNarrowers = false

            newNode = new Iconclass_ListViewTreeNode
                selectable: false
              ,
                prefLabel: prefLabel
                uri: 'http://iconclass.org/' + iconclassEntry.n
                hasNarrowers: hasNarrowers
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                context: that.context
                iconclass_opts: that.iconclass_opts
                editor_layout: that.editor_layout
                iconclassInfo: iconclassEntry
            children.push(newNode)
          dfr.resolve(children)
        )

        dfr.promise()

    #########################################
    # function isLeaf
    isLeaf: =>
        if @additionalOpts.hasNarrowers == true
            return false
        else
          return true

    #########################################
    # function renderContent
    renderContent: =>
        that = @
        extendedInfo_xhr = { "xhr" : undefined }
        d = CUI.dom.div()

        buttons = []

        # '+'-Button
        icon = 'fa-plus-circle'
        tooltipText = $$('custom.data.type.iconclass.modal.form.popup.add_choose')

        plusButton =  new CUI.Button
                            text: ""
                            icon_left: new CUI.Icon(class: icon)
                            active: false
                            group: "default"
                            tooltip:
                              text: tooltipText
                            onClick: =>
                              # build save data
                              iconclassInfo = that.additionalOpts.iconclassInfo

                              that.cdata.conceptAncestors = []
                              # if treeview, add ancestors
                              if iconclassInfo?.p?.length > 0
                                # save ancestor-uris to cdata
                                for ancestor in iconclassInfo.p
                                  that.cdata.conceptAncestors.push 'http://iconclass.org/' + ancestor
                              # add own uri to ancestor-uris
                              that.cdata.conceptAncestors.push 'http://iconclass.org/' + iconclassInfo.n

                              console.warn @, that, iconclassInfo
                              # lock conceptURI in savedata
                              that.cdata.conceptURI = 'http://iconclass.org/' + iconclassInfo.n
                              # lock conceptFulltext in savedata
                              that.cdata._fulltext = ez5.IconclassUtil.getFullTextFromObject iconclassInfo, false
                              # lock standard in savedata
                              that.cdata._standard = ez5.IconclassUtil.getStandardTextFromObject that.context, iconclassInfo, that.cdata, false

                              # lock conceptName in savedata
                              that.cdata.conceptName = ez5.IconclassUtil.getConceptNameFromObject iconclassInfo, that.cdata

                              # update form
                              CustomDataTypeIconclass.prototype.__updateResult(that.cdata, that.editor_layout, that.iconclass_opts)
                              # hide popover
                              that.popover.hide()

        plusButton.setEnabled(true)

        buttons.push(plusButton)

        # infoIcon-Button
        infoButton = new CUI.Button
                        text: ""
                        icon_left: new CUI.Icon(class: "fa-info-circle")
                        active: false
                        group: "default"
                        tooltip:
                          markdown: true
                          placement: "e"
                          content: (tooltip) ->
                            # show infopopup
                            encodedURI = encodeURIComponent(that.uri)
                            console.warn encodedURI
                            CustomDataTypeIconclass.prototype.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr, that.context)
                            new CUI.Label(icon: "spinner", text: $$('custom.data.type.iconclass.modal.form.popup.loadingstring'))
        buttons.push(infoButton)

        # button-bar for each row
        buttonBar = new CUI.Buttonbar
                          buttons: buttons

        CUI.dom.append(d, CUI.dom.append(CUI.dom.div(), buttonBar.DOM))

        @addColumn(new CUI.ListViewColumn(element: d, colspan: 1))

        CUI.Events.trigger
          node: that.popover
          type: "content-resize"

        new CUI.Label(text: @prefLabel)
