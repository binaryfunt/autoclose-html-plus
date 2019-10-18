module.exports =
    config:
        forceInline:
            title: 'Force Inline'
            order: 1
            description: 'Elements in this comma delimited list will render their closing tags on the same line, even if they are block by default. Use * to force all closing tags to render inline'
            type: 'array'
            default: ['title', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6']
        forceBlock:
            title: 'Force Block'
            order: 2
            description: 'Elements in this comma delimited list will render their closing tags after a tabbed line, even if they are inline by default. Values are ignored if Force Inline is *'
            type: 'array'
            default: ['head']
        neverClose:
            title: 'Never Close Elements'
            order: 3
            description: 'Comma delimited list of elements to never close'
            type: 'array'
            default: ['br', 'hr', 'img', 'input', 'link', 'meta', 'area', 'base', 'col', 'command', 'embed', 'keygen', 'param', 'source', 'track', 'wbr']
        makeNeverCloseSelfClosing:
            title: 'Make Never Close Elements Self-Closing'
            order: 4
            description: 'Closes elements with " />" (ie &lt;tag&gt; becomes &lt;tag /&gt;)'
            type: 'boolean'
            default: true
        makeUnrecognizedBlock:
            title: 'Make Unrecognized Elements Block Tags'
            order: 5
            description: 'Unrecognized/non-standard HTML elements will render their closing tags after a tabbed line. This may be useful for custom XML tags'
            type: 'boolean'
            default: true
        legacyMode:
            title: "Legacy/International Mode"
            order: 6
            description: "Do not use this unless you use a non-US or non-QWERTY keyboard and/or the plugin isn't working otherwise. USING THIS OPTION WILL OPT YOU OUT OF NEW IMPROVEMENTS/FEATURES POST 0.22.0"
            type: 'boolean'
            default: false
