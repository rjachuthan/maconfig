" Snowflake adapter for vim-dadbod, wired up via g:db_adapter_snowflake.
"
" Upstream's adapter already shells out to snowsql and forwards every URL
" query param as a `--flag=value`, which is enough for key-pair auth. What it
" doesn't implement is tables(), and dadbod-ui has no Snowflake entry in its
" own schema table, so the drawer falls back to that hook and comes up empty.
" Everything else just delegates.

function! db#adapter#snowflake_kp#interactive(url) abort
  return db#adapter#snowflake#interactive(a:url)
endfunction

function! db#adapter#snowflake_kp#filter(url) abort
  return db#adapter#snowflake#filter(a:url)
endfunction

function! db#adapter#snowflake_kp#input(url, in) abort
  return db#adapter#snowflake#input(a:url, a:in)
endfunction

function! db#adapter#snowflake_kp#complete_database(url) abort
  return db#adapter#snowflake#complete_database(a:url)
endfunction

function! db#adapter#snowflake_kp#complete_opaque(url) abort
  " Upstream passes an undefined `url` here instead of `a:url`.
  return db#adapter#snowflake_kp#complete_database(a:url)
endfunction

function! s:query(url, query) abort
  " `-o quiet=true` suppresses the result rows too, not just the banner, so
  " the drawer came up empty. friendly=false + timing=false is what actually
  " leaves nothing but the rows.
  let cmd = db#adapter#snowflake#filter(a:url) +
        \ ['-o', 'header=false', '-o', 'output_format=tsv'] +
        \ ['-o', 'friendly=false', '-o', 'timing=false'] +
        \ ['-q', a:query]
  let out = map(db#systemlist(cmd), { _, v -> trim(substitute(v, "\r$", '', '')) })
  return filter(out, { _, v -> !empty(v) })
endfunction

let s:tables_query = join([
      \ "select table_schema || '.' || table_name",
      \ 'from information_schema.tables',
      \ "where table_schema <> 'INFORMATION_SCHEMA'",
      \ 'order by 1',
      \ ], ' ')

function! db#adapter#snowflake_kp#tables(url) abort
  return s:query(a:url, s:tables_query)
endfunction
