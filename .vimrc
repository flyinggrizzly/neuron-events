" Easy command bindings
:command! -complete=file -nargs=+ ZE call NewZettelEvent(<f-args>)
:command! -complete=file -nargs=+ ZEt call NewZettelEventTab(<f-args>)

" Creating a new zettel event
function! g:NewZettelEvent(name, date, ...)
  call ZettelEvent('edit', a:name, a:date, a:000)
endfunction

" Creating a new zettel event, in a new tab
function! g:NewZettelEventTab(name, date, ...)
  call ZettelEvent('tabedit', a:name, a:date, a:000)
endfunction

" Creating a new zettel event
"
" Requires a `command` (`e`, `tabe`, etc) param
" Requires a `name` param
" Requires a `date` param, in ISO8601 format (including Time), or ISO8601 with the year, month or day element
"   replaced with wildcards (repeating annually: `yyyy-MM-DD`, repeating monthly: `yyyy-mm-DD`, repeating daily: `yyyy-mm-dd`)
" Accepts a slopped List of tags
function! g:ZettelEvent(command, name, date, tags)
  let l:id_elements = [
  \ 'events/event',
  \ a:date,
  \ a:name,
  \]
  let l:id = join(l:id_elements, '-')

  let l:command = a:command
  let l:tags = a:tags

  let l:filename = join([ l:id, '.md' ], '')
  let l:title = join([ FormatZettelEventDate(a:date), substitute(a:name, '-', ' ', 'g')], ' ')

  execute(join([ l:command, l:filename ], ' '))

  let l:front_matter = BuildFrontmatter(l:tags, 0)

  let l:body = [
  \ '',
  \ '# '. TitleCase(l:title)
  \]

  call append(0, l:front_matter)
  call append(len(l:front_matter), l:body)
endfunction

" Formats the date param passed to `g:ZettelEvent` into an English-friendly format
" Handles repeating dates
function! g:FormatZettelEventDate(date_time)
  let l:full_date_regexp = '\d\d\d\d-\d\d-\d\d'
  let l:annual_date_regexp = 'yyyy-\d\d-\d\d'
  let l:monthly_date_regexp = 'yyyy-mm-\d\d'
  let l:daily_date_regexp = 'yyyy-mm-dd'

  let l:date_segments = split(a:date_time, 'T')
  let l:has_time = len(l:date_segments) > 1
  let l:date_segment = l:date_segments[0]
  let l:time = l:date_segments[1]

  let l:date_components = split(l:date_segment, '-')
  let l:year = l:date_components[0]
  let l:month = l:date_components[1]
  let l:raw_date = l:date_components[2]
  let l:date = substitute(l:raw_date, '^0', '', '')

  let l:components = []

  if match(a:date_time, l:full_date_regexp) > -1
    return a:date_time.':'
  elseif match(a:date_time, l:annual_date_regexp) > -1
    call add(l:components, 'Anually on '.l:month.'/'.l:date.' at '.l:time)
  elseif match(a:date_time, l:monthly_date_regexp) > -1
    if l:date ==? '1'
      call add(l:components, '1st of every month')
    elseif l:date ==? '2'
      call add(l:components, '2nd of every month')
    elseif l:date ==? '3'
      call add(l:components, '3rd of every month')
    else
      call add(l:components, l:date.'th of every month')
    endif
  elseif match(a:date_time, l:daily_date_regexp)
    call add(l:components, 'Every day')
  endif

  if l:has_time
    call add(l:components, ' at '.l:time.':')
  else
    call add(l:components, ':')
  endif

  return join(l:components, ' ')
endfunction

" Shamelessly stolen from christoomey/vim-titlecase
function! g:SmartCapitalize(string)
  " Don't change intentional all caps
  if(toupper(a:string) ==# a:string)
    return a:string
  endif

  let s = tolower(a:string)

  let exclusions = '^\(a\|an\|and\|as\|at\|but\|by\|en\|for\|if\|in\|nor\|of\|on\|or\|per\|the\|to\|v.?\|vs.?\|via\)$'
  " Return the lowered string if it matches either the built-in or user exclusion list
  if (match(s, exclusions) >= 0)
    return s
  endif

  return toupper(s[0]) . s[1:]
endfunction

function! g:TitleCase(string)
  let l:parts = split(a:string, ' ')
  let l:capitalized_parts = []

  for part in l:parts
    call add(l:capitalized_parts, SmartCapitalize(part))
  endfor

  return join(l:capitalized_parts, ' ')
endfunction

function! g:BuildFrontmatter(tags, include_date)
  let l:tags = a:tags

  let l:front_matter = [
    \ '---',
  \]

  if a:include_date
    call add(l:front_matter, 'date: '.strftime("%Y-%m-%dT%H:%M"))
  endif

  if (len(l:tags) > 0)
    call add(l:front_matter, 'tags:')

    for tag in l:tags
      let l:tag_line = '    - ' . tag

      call add(l:front_matter, l:tag_line)
    endfor
  endif

  call add(l:front_matter, '---')

  return l:front_matter
endfunction