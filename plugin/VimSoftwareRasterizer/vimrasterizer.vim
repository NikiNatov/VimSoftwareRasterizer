function! s:Main()
	call VimSoftwareRasterizer#vimrasterizer#Start()
endfunction

command! VimRasterizer call s:Main()
