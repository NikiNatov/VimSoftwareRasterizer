" ------------------------------------------------------------- Color -------------------------------------------------------------
let Color = {}

function! Color.create(r, g, b)
	let l:instance = #{ r: a:r, g: a:g, b: a:b }

	function! l:instance.get_hex_string()
		return printf('%02x%02x%02x', self.r, self.g, self.b)
	endfunction

	let l:hex_str = l:instance.get_hex_string()
	execute "highlight " . l:hex_str . " guifg='#" . l:hex_str . "'"

	if empty(prop_type_get(l:hex_str))
		call prop_type_add(l:hex_str, { 'highlight': l:hex_str })
	endif

	return l:instance
endfunction
