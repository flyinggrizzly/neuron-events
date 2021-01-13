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

function! g:FormatZettelEventDate(date_time)
  let l:full_date_regexp = '\d\d\d\d-\d\d-\d\d'
  let l:annual_date_regexp = 'yyyy-\d\d-\d\d'
  let l:monthly_date_regexp = 'yyyy-mm-\d\d'
  let l:monthly_for_a_year_regexp = '\d\d\d\d-mm-\d\d'
  let l:daily_date_regexp = 'yyyy-mm-dd'
  let l:daily_for_a_year_regexp = '\d\d\d\d-mm-dd'
  let l:daily_for_a_month_and_year_regexp = '\d\d\d\d-\d\d-dd'
  let l:daily_for_a_month_regexp = 'yyyy-\d\d-dd'

  if match(a:date_time, l:full_date_regexp) > -1
    return a:date_time
  elseif match(a:date_time, l:annual_date_regexp) > -1
    return AnnualDateFormat(a:date_time)
  elseif match(a:date_time, l:monthly_date_regexp) > -1
    return MonthlyDateFormat(a:date_time)
  elseif match(a:date_time, l:monthly_for_a_year_regexp) > -1
    return MonthlyForAYearFormat(a:date_time)
  elseif match(a:date_time, l:daily_date_regexp)
    return DailyFormat(a:date_time)
  elseif match(a:date_time, l:daily_for_a_year_regexp) > -1
    return DailyForAYearFormat(a:date_time)
  elseif match(a:date_time, l:daily_for_a_month_and_year_regexp) > -1
    return DailyForAMonthAndYearFormat(a:date_time)
  elseif match(a:date_time, l:daily_for_a_month_regexp) > -1
    return DailyForAMonthFormat(a:date_time)
  endif
endfunction

function! g:AnnualDateFormat(date_time)
  let l:date_and_time = split(a:date_time, 'T')
  let l:date_components = split(l:date_and_time[0], '-')
  let l:month = l:date_components[1]
  let l:raw_date = l:date_components[2]
  let l:date = substitute(l:raw_date, '^0', '', '')

  if IncludesTime(a:date_time)
    let l:time = l:date_and_time[1]

    return "Annually on ".l:month."/".l:date." at ".l:time
  else
    return "Annually on ".l:month."/".l:date
  endif
endfunction

function! g:DeclineTwoDigitCounter(number)
  let l:trailing_digit = a:number[-1]

  if l:trailing_digit ==? '1'
    return a:number.'st'
  elseif l:trailing_digit ==? '2'
    return a:number.'nd'
  elseif l:trailing_digit ==? '3'
    return a:number.'rd'
  else
    return a:number.'th'
  endif
endfunction

function! g:MonthlyDateFormat(date_time)
  let l:date_and_time = split(a:date_time, 'T')
  let l:date_components = split(l:date_and_time[0], '-')
  let l:raw_date = l:date_components[2]
  let l:date = substitute(l:raw_date, '^0', '', '')

  if IncludesTime(a:date_time)
    let l:time = l:date_and_time[1]

    return DeclineTwoDigitCounter(l:date).' at '.l:time
  else
    return DeclineTwoDigitCounter(l:date)
  endif
endfunction

" Format for YYYY-mm-DD
function! g:MonthlyForAYearFormat(date_time)
  let l:date_and_time = split(a:date_time, 'T')
  let l:date_components = split(l:date_and_time[0], '-')
  let l:year = l:date_components[0]
  let l:raw_date = l:date_components[2]
  let l:date = substitute(l:raw_date, '^0', '', '')

  if IncludesTime(a:date_time)
    let l:time = l:date_and_time[1]

    return DeclineTwoDigitCounter(l:date).' of every month (in '.l:year.') at '.l:time
  else
    return DeclineTwoDigitCounter(l:date).' of every month (in '.l:year.')'
  endif
endfunction

function! DailyFormat(date_time)
  let l:date_and_time = split(a:date_time, 'T')

  if IncludesTime(a:date_time)
    let l:time = l:date_and_time[1]

    return 'Every day at '.l:time
  else
    return 'Every day'
  endif
endfunction

function! DailyForAYearFormat(date_time)
  let l:date_and_time = split(a:date_time, 'T')
  let l:date_components = split(l:date_and_time[0], '-')
  let l:year = l:date_components[0]

  if IncludesTime(a:date_time)
    let l:time = l:date_and_time[1]

    return 'Every day in '.l:year.' at '.l:time
  else
    return 'Every day in '.l:year
  endif
endfunction

function! DailyForAMonthAndYearFormat(date_time)
  let l:date_and_time = split(a:date_time, 'T')
  let l:date_components = split(l:date_and_time[0], '-')
  let l:year = l:date_components[0]
  let l:month = l:date_components[1]

  if IncludesTime(a:date_time)
    let l:time = l:date_and_time[1]

    return 'Every day in '.LookupMonth(l:month).' '.l:year.' at '.l:time
  else
    return 'Every day in '.LookupMonth(l:month).' '.l:year
  endif
endfunction

function! g:DailyForAMonthFormat(date_time)
  let l:date_and_time = split(a:date_time, 'T')
  let l:date_components = split(l:date_and_time[0], '-')
  let l:month = l:date_components[1]

  if IncludesTime(a:date_time)
    let l:time = l:date_and_time[1]

    return 'Every day in '.LookupMonth(l:month).' at '.l:time
  else
    return 'Every day in '.LookupMonth(l:month)
  endif
endfunction

function! g:LookupMonth(number)
  let l:simple_number = substitute('a:number', '^0', '', '')

  if l:simple_number ==? '1'
    return 'January'
  elseif l:simple_number ==? '2'
    return 'February'
  elseif l:simple_number ==? '3'
    return 'March'
  elseif l:simple_number ==? '4'
    return 'April'
  elseif l:simple_number ==? '5'
    return 'May'
  elseif l:simple_number ==? '6'
    return 'June'
  elseif l:simple_number ==? '7'
    return 'July'
  elseif l:simple_number ==? '8'
    return 'August'
  elseif l:simple_number ==? '9'
    return 'September'
  elseif l:simple_number ==? '10'
    return 'October'
  elseif l:simple_number ==? '11'
    return 'November'
  elseif l:simple_number ==? '12'
    return 'December'
  end
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
      let l:tag_line = '  - ' . tag

      call add(l:front_matter, l:tag_line)
    endfor
  endif

  call add(l:front_matter, '---')

  return l:front_matter
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
