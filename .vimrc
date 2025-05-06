:set relativenumber
:set nowrapscan

vmap > >gv
vmap < <gv
vmap <TAB> >
vmap <S-TAB> <

map Ø O<esc>
map ø o<esc>

map æ :/<C-r>"<Enter>
map Æ yiw:/<C-r>"<Enter>
vmap æ :/<C-r>"<Enter>
vmap Æ y:/<C-r>"<Enter>

map å ma$x`a
map Å ma^x`a

map <A-Up> ddkP
map <A-Down> ddp
vmap <A-down> dp`[V`]
vmap <A-up> dkkp`[V`]
