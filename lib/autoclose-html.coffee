isOpeningTagLikePattern = /<(?![\!\/])([a-z]{1}[^>\s=\'\"\/]*)[^>\/]*>$/i

ConfigSchema = require('./configuration.coffee')
{CompositeDisposable} = require 'atom'

module.exports =
    config: ConfigSchema.config

    neverClose: []
    forceInline: []
    forceBlock: []
    makeNeverCloseSelfClosing: false
    makeUnrecognizedBlock: false
    legacyMode: false

    inlineByDefault: ['a', 'abbr', 'acronym', 'audio', 'b', 'bdi', 'bdo', 'big', 'button', 'canvas', 'cite', 'code', 'data', 'datalist', 'del', 'dfn', 'em', 'i', 'iframe', 'ins', 'kbd', 'label', 'map', 'mark', 'meter', 'noscript', 'object', 'output', 'picture', 'progress', 'q', 'ruby', 's', 'samp', 'script', 'select', 'slot', 'small', 'span', 'strong', 'sub', 'sup', 'svg', 'template', 'textarea', 'time', 'u', 'tt', 'var', 'video']

    activate: () ->

        @autocloseHTMLEvents = new CompositeDisposable

        @closeAndCompleteCommand = atom.commands.add 'atom-text-editor',
            'autoclose-html-plus:close-and-complete': (e) =>
                if @legacyMode
                    console.log(e)
                    e.abortKeyBinding()
                else
                    atom.workspace.getActiveTextEditor().insertText(">")
                    this.execAutoclose()


        atom.config.observe 'autoclose-html-plus.neverClose', (value) =>
            @neverClose = value

        atom.config.observe 'autoclose-html-plus.forceInline', (value) =>
            @forceInline = value

        atom.config.observe 'autoclose-html-plus.forceBlock', (value) =>
            @forceBlock = value

        atom.config.observe 'autoclose-html-plus.makeNeverCloseSelfClosing', (value) =>
            @makeNeverCloseSelfClosing = value

        atom.config.observe 'autoclose-html-plus.makeUnrecognizedBlock', (value) =>
            @makeUnrecognizedBlock = value

        atom.config.observe 'autoclose-html-plus.legacyMode', (value) =>
            @legacyMode = value
            if @legacyMode
                @_events()
            else
                @_unbindEvents()


    deactivate: ->
        if @legacyMode
            @_unbindEvents()

        @closeAndCompleteCommand.dispose()


    isInline: (eleTag) ->
        if @forceInline.indexOf("*") > -1
            return true

        try
            ele = document.createElement eleTag
        catch
            return false

        if eleTag.toLowerCase() in @forceBlock
            return false
        else if eleTag.toLowerCase() in @forceInline
            return true

        if @makeUnrecognizedBlock
            return eleTag.toLowerCase() in @inlineByDefault
        else
            document.body.appendChild ele
            ret = window.getComputedStyle(ele).getPropertyValue('display') in ['inline', 'inline-block', 'none']
            document.body.removeChild ele
            return ret


    isNeverClosed: (eleTag) ->
        return eleTag.toLowerCase() in @neverClose


    execAutoclose: () ->
        editor = atom.workspace.getActiveTextEditor()
        range = editor.selections[0].getBufferRange()
        line = editor.buffer.getLines()[range.end.row]
        partial = line.substr(0, range.start.column)
        partial = partial.substr(partial.lastIndexOf('<'))

        # If no opening tag detected on this line, check previous lines:
        if partial is '>'
            originalPartial = partial
            partial = line.substr(0, range.start.column)
            count = 1
            loop
                if count >= 10 or count > range.end.row
                    partial = originalPartial
                    break
                line = editor.buffer.getLines()[range.end.row - count]
                partial = line.concat(partial)
                if partial.lastIndexOf('<') >= 0
                    # partial = partial.concat('>')
                    partial = partial.substr(partial.lastIndexOf('<'))
                    break
                count++

        return if partial.substr(partial.length - 1, 1) is '/'

        singleQuotes = partial.match(/\'/g)
        doubleQuotes = partial.match(/\"/g)
        oddSingleQuotes = singleQuotes && (singleQuotes.length % 2)
        oddDoubleQuotes = doubleQuotes && (doubleQuotes.length % 2)

        return if oddSingleQuotes or oddDoubleQuotes

        index = -1
        while((index = partial.indexOf('"')) isnt -1)
            partial = partial.slice(0, index) + partial.slice(partial.indexOf('"', index + 1) + 1)

        while((index = partial.indexOf("'")) isnt -1)
            partial = partial.slice(0, index) + partial.slice(partial.indexOf("'", index + 1) + 1)

        return if not (matches = partial.match(isOpeningTagLikePattern))?

        eleTag = matches[matches.length - 1]

        if @isNeverClosed(eleTag)
            if @makeNeverCloseSelfClosing
                tag = '/>'
                if partial.substr partial.length - 1, 1 isnt ' '
                    tag = ' ' + tag
                editor.backspace()
                editor.insertText tag
            return

        isInline = @isInline eleTag

        editor.insertText('</' + eleTag + '>')
        editor.setCursorBufferPosition range.end
        if not isInline
            inlineCheckpoint = editor.createCheckpoint()
            editor.insertNewline()
            editor.insertNewline()
            editor.autoIndentBufferRow range.end.row + 1
            editor.setCursorBufferPosition [range.end.row + 1, atom.workspace.getActivePaneItem().getTabText().length * atom.workspace.getActivePaneItem().indentationForBufferRow(range.end.row + 1)]
            editor.groupChangesSinceCheckpoint(inlineCheckpoint)


    _events: () ->
        atom.workspace.observeTextEditors (textEditor) =>
            textEditor.observeGrammar (grammar) =>
                textEditor.autocloseHTMLbufferEvent.dispose() if textEditor.autocloseHTMLbufferEvent?
                if atom.views.getView(textEditor).getAttribute('data-grammar').split(' ').indexOf('html') > -1
                     textEditor.autocloseHTMLbufferEvent = textEditor.buffer.onDidChange (e) =>
                         if e?.newText is '>' && textEditor == atom.workspace.getActiveTextEditor()
                             setTimeout =>
                                 @execAutoclose()
                     @autocloseHTMLEvents.add(textEditor.autocloseHTMLbufferEvent)


    _unbindEvents: () ->
        @autocloseHTMLEvents.dispose()
