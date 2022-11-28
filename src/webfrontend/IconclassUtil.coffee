class ez5.IconclassUtil

  @getPreview: (data, language) ->
    that = @
    html = ''

    if data instanceof Array
      data = data[0]

    if ! data?.n
      return false

    if data?.txt[language]
      prefLabel = data?.txt[language]
    else
      prefLabel = data?.txt?.de

    xuri = 'https://iconclass.org/' + data.n

    html += '<div style="font-size: 12px; color: #999;"><span class="cui-label-icon"><i class="fa  fa-external-link"></i></span>&nbsp;' + xuri + '</div>'

    html += '<h3><span class="cui-label-icon"><i class="fa  fa-info-circle"></i></span>&nbsp;' + prefLabel + '</h3>'

    # keywords
    keywordsString = '';
    keywords = []
    if data?.kw?.language
      keywords = data?.kw?.language
    else
      keywords = data?.kw?.de
    for key, val of keywords
        keywordsString = ' - ' + val + '<br />' + keywordsString
    if keywordsString
      html += '<h4>' + $$('custom.data.type.iconclass.modal.form.popup.preview.keywords') + '</h4>' + keywordsString

    html = '<style>.iconclassTooltip { padding: 10px; min-width:200px; } .iconclassTooltip h4 { margin-bottom: 0px; }</style><div class="iconclassTooltip">' + html + '</div>'

    return html

  @getConceptNameFromObject: (object, cdata) ->
    if cdata?.frontendLanguage
        if cdata?.frontendLanguage?.length == 2
          activeFrontendLanguage = cdata.frontendLanguage

    if Array.isArray(object)
      object = object[0]

    conceptName = ''

    # build standard upon prefLabel!
    # 1. TEXT
    if object.txt[activeFrontendLanguage]
      conceptName = object.txt[activeFrontendLanguage]
    # else take first preflabel..
    else if iconclassInfo?.txt?.de
      conceptName = object.txt.de
    else if iconclassInfo?.txt?.en
      conceptName = object.txt.en
    else
      conceptName = object.txt[Object.keys(object.txt)[0]]

    conceptName = object.n + ' - ' + conceptName

    return conceptName

  @getStandardTextFromObject: (context, object, cdata, databaseLanguages = false) ->

    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    activeFrontendLanguage = null
    if context
      activeFrontendLanguage = context.getFrontendLanguage()

    if cdata?.frontendLanguage
        if cdata?.frontendLanguage?.length == 2
          activeFrontendLanguage = cdata.frontendLanguage

    if Array.isArray(object)
      object = object[0]

    _standard = {}
    standardTextString = ''
    l10nObject = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    # build standard upon prefLabel!
    # 1. TEXT
    if object.txt[activeFrontendLanguage]
      standardTextString = object.txt[activeFrontendLanguage]
    # else take first preflabel..
    else
      standardTextString = object.txt[Object.keys(object.txt)[0]]

    standardTextString = object.n + ' - ' + standardTextString

    # 2. L10N
    #  give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # get shortened version
      shortenedLanguage = l10nObjectKey.split('-')[0]
      # add to l10n
      if object.txt[shortenedLanguage]
        l10nObject[l10nObjectKey] = object.n + ' - ' + object.txt[shortenedLanguage]

    _standard.l10ntext = l10nObject

    return _standard



  @getFullTextFromObject: (object, databaseLanguages = false) ->
    if databaseLanguages == false
      databaseLanguages = ez5.loca.getDatabaseLanguages()

    shortenedDatabaseLanguages = databaseLanguages.map((value, key, array) ->
      value.split('-').shift()
    )

    if Array.isArray(object)
      object = object[0]

    _fulltext = {}
    fullTextString = ''
    l10nObject = {}
    l10nObjectWithShortenedLanguages = {}

    # init l10nObject for fulltext
    for language in databaseLanguages
      l10nObject[language] = ''

    for language in shortenedDatabaseLanguages
      l10nObjectWithShortenedLanguages[language] = ''

    objectKeys = ["kw", "n", "txt"]

    # parse all object-keys and add all values to fulltext
    for key, value of object
      if objectKeys.includes(key)

        propertyType = typeof value

        # string
        if propertyType == 'string'
          fullTextString += value + ' '
          # add to each language in l10n
          for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
            l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + value + ' '

        # object / array
        if propertyType == 'object'
          # array?
          if Array.isArray(object[key])
            for arrayValue in object[key]
              fullTextString += arrayValue + ' '
              # no language: add to every l10n-fulltext
              for l10nObjectWithShortenedLanguagesKey, l10nObjectWithShortenedLanguagesValue of l10nObjectWithShortenedLanguages
                l10nObjectWithShortenedLanguages[l10nObjectWithShortenedLanguagesKey] = l10nObjectWithShortenedLanguagesValue + arrayValue + ' '
          else
            # object?
            for objectKey, objectValue of object[key]
              if Array.isArray(objectValue)
                for arrayValueOfObject in objectValue
                  fullTextString += arrayValueOfObject + ' '
                  # check key and also add to l10n
                  if l10nObjectWithShortenedLanguages.hasOwnProperty objectKey
                    l10nObjectWithShortenedLanguages[objectKey] += arrayValueOfObject + ' '
              if typeof objectValue == 'string'
                fullTextString += objectValue + ' '
                # check key and also add to l10n
                if l10nObjectWithShortenedLanguages.hasOwnProperty objectKey
                  l10nObjectWithShortenedLanguages[objectKey] += objectValue + ' '
    # finally give l10n-languages the easydb-language-syntax
    for l10nObjectKey, l10nObjectValue of l10nObject
      # get shortened version
      shortenedLanguage = l10nObjectKey.split('-')[0]
      # add to l10n
      if l10nObjectWithShortenedLanguages[shortenedLanguage]
        l10nObject[l10nObjectKey] = l10nObjectWithShortenedLanguages[shortenedLanguage]

    _fulltext.text = fullTextString
    _fulltext.l10ntext = l10nObject

    return _fulltext
