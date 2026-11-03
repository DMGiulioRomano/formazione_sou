jscommand { window.CodeMirrorAdapter.commands.save = () => { window.app.commands.executeCommandById('editor:save-file'); }; }
nmap <C-s> :w<CR>
nmap <leader>w :w<CR>

exmap q obcommand workspace:close
nmap <leader>q :q<CR>   

