describe('Auto Close HTML+', () => {

    let editor, editorView, activationPromise;

    const sendAutocloseCmd = () => {
        atom.commands.dispatch(editorView, 'autoclose-html-plus:close-and-complete');
    };

    const sendUndoCmd = () => {
        atom.commands.dispatch(editorView, 'core:undo');
    };

    beforeEach(async () => {
        await atom.packages.activatePackage('autoclose-html-plus');
    });

    describe('HTML file', () => {
        beforeEach(async () => {
            await atom.packages.activatePackage('language-html');
            await atom.workspace.open('blank.html');

            editor = atom.workspace.getActiveTextEditor();
            editorView = atom.views.getView(editor);
        });

        it('checks package is activated', () => expect(atom.packages.isPackageActive('autoclose-html-plus')).toBe(true));

        describe('When close-and-complete command is dispatched (on a blank file)', () => {
            beforeEach(sendAutocloseCmd);
            it('inserts a ">"', () => expect(editor.getText()).toBe('>'));
        });

        describe('When a declaration/prolog is closed', () => {
            it('only inserts ">"', () => {
                editor.setText('<!doctype html');
                sendAutocloseCmd();
                expect(editor.getText()).toBe('<!doctype html>');


                editor.setText('<?php echo "foo"; ?');
                sendAutocloseCmd();
                expect(editor.getText()).toBe('<?php echo "foo"; ?>');
            });
        });

        describe('When an inline element (e.g. span) is closed', () => {
            beforeEach(() => {
                editor.setText('<span');
                sendAutocloseCmd();
            });

            it('inserts closing tag on the same line', () => expect(editor.getText()).toBe('<span></span>'));

            it('places cursor in betwen opening & closing tags => at column index 6', () => {
                expect(editor.getCursorBufferPosition().column).toBe(6);
            });

            describe('After an undo', () => {
                beforeEach(sendUndoCmd);

                it('removes the closing tag', () => expect(editor.getText()).toBe('<span>'));

                it('leaves cursor at end of opening tag => at column index 6', () => {
                    expect(editor.getCursorBufferPosition().column).toBe(6);
                });

                describe('After a second undo', () => {
                    beforeEach(sendUndoCmd);
                    it('removes the ">"', () => expect(editor.getText()).toBe('<span'));
                });
            });
        });

        describe('When an inline element (e.g. span) with attributes is closed', () => {
            beforeEach(() => {
                editor.setText('<span class="foo"');
                sendAutocloseCmd();
            });
            it('inserts closing tag', () => expect(editor.getText()).toBe('<span class="foo"></span>'));
        });

        describe('When a block element (e.g. div) is closed', () => {
            beforeEach(() => {
                editor.setText('<div');
                sendAutocloseCmd();
            });

            it('inserts closing tag 2 lines down', () => expect(editor.lineTextForBufferRow(2)).toBe('</div>'));

            it('places cursor at the middle line (row index 1)', () => {
                expect(editor.getCursorBufferPosition().row).toBe(1);
            });

            it('places cursor at correct indentation (tab length for file)', () => {
                let tabLength = editor.getTabLength();
                expect(editor.getCursorBufferPosition().column).toBe(tabLength);
            });

            describe('After an undo', () => {
                beforeEach(sendUndoCmd);

                it('puts the closing tag back inline', () => expect(editor.getText()).toBe('<div></div>'));

                it('places cursor at end of opening tag => at column index 5', () => {
                    expect(editor.getCursorBufferPosition().column).toBe(5);
                });

                describe('After a second undo', () => {
                    beforeEach(sendUndoCmd);
                    it('removes the closing tag', () => expect(editor.getText()).toBe('<div>'));

                    describe('After a third undo', () => {
                        beforeEach(sendUndoCmd);
                        it('removes the ">"', () => expect(editor.getText()).toBe('<div'));
                    })
                });
            });
        });

        describe('When a block element (e.g. div) broken over a line is closed', () => {
            beforeEach(() => {
                editor.setText('<div\n\tclass="foo"');
                sendAutocloseCmd();
            });

            it('inserts closing tag (3 lines down)', () => expect(editor.lineTextForBufferRow(3)).toBe('</div>'));
        });

        describe('When a forced block element (i.e. head) is closed', () => {
            beforeEach(() => {
                editor.setText('<head');
                sendAutocloseCmd();
            });
            it('inserts closing tag 2 lines down', () => expect(editor.lineTextForBufferRow(2)).toBe('</head>'));
        });

        describe('When a never close element (e.g. img) is closed', () => {
            beforeEach(() => editor.setText('<img'));

            describe('If makeNeverCloseSelfClosing is true', () => {
                beforeEach(sendAutocloseCmd);

                it('inserts " />"', () => expect(editor.getText()).toBe('<img />'));

                describe('After an undo', () => {
                    beforeEach(sendUndoCmd);
                    it('removes the " />"', () => expect(editor.getText()).toBe('<img'));
                });
            });

            describe('If makeNeverCloseSelfClosing is false', () => {
                beforeEach(() => {
                    atom.config.set('autoclose-html-plus.makeNeverCloseSelfClosing', 'false');
                    sendAutocloseCmd();
                });
                it('only inserts ">"', () => expect(editor.getText()).toBe('<img>'));
            });

        });

        describe('When ">" is typed after a complete tag', () => {
            beforeEach(() => {
                editor.setText('<span>');
                sendAutocloseCmd();
            })
            it('only inserts ">"', () => expect(editor.getText()).toBe('<span>>'));
        });
    });


    describe('XML file', () => {
        beforeEach(async () => {
            await atom.packages.activatePackage('language-xml');
            await atom.workspace.open('blank.xaml');

            editor = atom.workspace.getActiveTextEditor();
            editorView = atom.views.getView(editor);
        });

        describe('When a complex unrecognised tag is closed', () => {
            beforeEach(() => editor.setText('<App.Res x:Url="http://ms.ft"'));

            describe('If makeUnrecognizedBlock is true', () => {
                beforeEach(sendAutocloseCmd);
                it('inserts closing tag 2 lines down', () => expect(editor.lineTextForBufferRow(2)).toBe('</App.Res>'));
            });

            describe('If makeUnrecognizedBlock is false', () => {
                beforeEach(() => {
                    atom.config.set('autoclose-html-plus.makeUnrecognizedBlock', 'false');
                    sendAutocloseCmd();
                });
                it('inserts closing tag on same line', () => expect(editor.getText()).toBe('<App.Res x:Url="http://ms.ft"></App.Res>'));
            });
        });
    });

});
