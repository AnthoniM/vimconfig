nnoremap <localleader>h :call <SID>TEMPNAME(expand('%'))<cr>

function! s:OpenTag(name, standaloneName)
  return '<'.a:name.'>'
endfunction

function! s:CloseTag(name)
  return '</'.a:name.'>'
endfunction

function! s:ExtractStandalone(lines, cursor, depth)
endfunction

function! s:TEMPNAME(filename)
  let lines = readfile(a:filename)
  call s:Engine(lines)
endfunction

function! s:ReadLine(line)
  let line = split(a:line, ' ')
  let tagDepth = line[0]
  let tagName = line[1]
  let tagType = line[2]
  let mandatory = line[3]
  let standaloneName = line[4]
  return [tagDepth, tagName, tagType, mandatory, standaloneName]
endfunction

function! s:Engine(lines)
  let front = []
  let back = []
  let depth = -1 
  let cur = 0
  let last = len(a:lines)-1

  while (cur <= last)

    if a:lines[cur][0] ==# '#'
      continue
    endif
    " Retrieve data on the current line
    let [tagDepth, tagName, tagType, mandatory, standaloneName] = s:ReadLine(a:lines[cur])

    if (cur == 0)
      if (standaloneName !=# "")
        let filename = standaloneName
      else
        let filename = "autoGeneratedXMLRootDocumentType"
      endif
    endif

    " Close tags deeper or equal to current depth
    let var = depth-tagDepth
    while (var >= 0)
      let front += [remove(back, -1)]
      let var -= 1
    endwhile

"   if (cur+1 <= last)
"       let probeDepth = s:ReadLine(a:lines[cur+displacement])[0]
"       if (probeDepth > tagDepth)
"         let type = "document"
"       else
"         let type = "string"
"       endif
"   endif

    " Add opening tag to front
    let front +=  [s:OpenTag(tagName, standaloneName)]

    " Add closing tag to back
    let back += [s:CloseTag(tagName)]

    " Update depth
    let depth = tagDepth

    " Handle standalone nodes
    " Generate a separate file for the stand alone 
    " and reference to it in the current tag
    if (standaloneName !=# "") && (cur > 0)
      " Compute subselection 
      " Include consecutive a:lines with depth higher then
      " the current depth
      let displacement = 0 
      let probeDepth = tagDepth+1
      while (probeDepth > tagDepth) 
        let displacement += 1
        if (cur+displacement > last)
          " Reached end of file
          let displacement += 1
          break
        endif
        let probeDepth = s:ReadLine(a:lines[cur+displacement])[0]
      endwhile
      let displacement -= 1
      " Recursive call
      " The end boundary is inclusive
      call s:Engine(a:lines[cur:cur+displacement])
      " Set cursor right after subselection
      let cur += displacement+1
    else
      " Go to next line
      let cur += 1
    endif
  endwhile

  while (len(back) != 0)
    let front += [remove(back, -1)]
  endwhile
  let data = join(front, '')
  call s:WriteToFile(filename, data)
endfunction

function! s:WriteToFile(filename, data)
  execute 'silent :! echo '. escape(a:data, '<>/') .' > '. a:filename .'.xml'
endfunction

function! s:SubstituteArrowToDepth()
  " Replaces arrows by the depth their express
  " by example : 
  "   the following :
  "     depth0
  "     --> depth1
  "     ----> depth2
  "   is replaced by :
  "     0 depth0
  "     1 depth1
  "     2 depth2
  execute '%s/^\(-*\)>\?/\=len(expand(submatch(0)))."\t"/g'
endfunction