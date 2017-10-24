"Functions for IPTC Data in  Silverfast"""""""""""""""""""""""""""""""""""""
"Silverfast can save IPTC Data with your photos. Normally these data are
"entered by checking various boxes and enter the respective information.
"Fortunately theses data can be saved and reloaded, which makes it somewhat 
"easier to just modify the files directly and load them afterwards.
"Unfortunately the convention of Silverfast is somewhat tedious. 
"
"Spaces are represented by the %20 character. And the keywords must be
"separated by exactly 64 characters. This vimscript makes it possible 
"to convert a textfile, which we will call inputfile, with title, date,
"location and keywords.
"At the moment the line of the keywords has to be 64 characters long and 
"the exact number of keywords must be given separately.

"The workings of this script are really primitive. In buffer 1 is
"the file were the informations are added and in buffer 2 will be a
"Template, which is simply a previously saved file from Silverfast.
"The functions simply go to the respective information and replace them in
"the template.

"The function NameSubstitution() assumes, that the given file is in buffer 1 
"and the template is in buffer 2.
"
" Example of the inputfile "Name:", "Date:", "State:", "City:",
" "Caption:", "KeywordCount:", "Keywords:" are required.
" ALSO the lines with the Keywords have to be exactly 64 Characters long.
" For Silverfast these empty spaces will be replaced by %20, which stands for 
" one character.
"
" Another point to keep in mind is, that my standard IPTC_Template has already
" 2 keywords inside, which were equal for all photos. Therefore the
" KeywordCount gets added to 2. If the template differs, these things have to
" be changed.
"
"	Name: Amerika Reise 2002 Film 23 Photo 01
"	Date: 29.09.2002
"	State: California
"	City: Los Angeles
"
"	Caption: Skyline of Los Angles photographed from the Griffith Observatory.
"
"	KeywordCount: 3
"
"	Keywords:
"California                                                      
"Los Angeles                                                     
"Griffith Observatory                                            
"


" The first four functions all work the same way.
" A mark is set, we search for the keyword mentioned above, go to the :, then
" the next word and yank everything behind it.
" Afterwards we go to the next buffer, were the IPTC_Template is supposed to
" be, search for the respective IPTCPoint, i.e IPTCObject, IPTCDate etc.,
" and insert the copied content and substitute the spaces with %20.
" NOTE: If there are no spaces the function will give back an error message.
" Lastly we delete what was previously entered in that line.
" NOTE: The IPTC_Template file must contain some information in the file
" between the <IPTCObject> and </IPTCObject>.
" Finally we save the file, necessary in order to return back to the previous
" buffer and finally jump back to the mark.
" buffer and finally jump back to the mark.

function! NameSubstitution()
	normal! ma
	/Name
	normal!	f:wy$
	:bn
	/IPTCObject
	execute "normal! o\<esc>p0i\t\t\<esc>0"
	:s / /%20/g
	execute "normal! jddgg"
	:w
	:bp
	normal! `a
endfunction	

"The date format in Silverfast has to be year month day with no "." or spaces.
"The format in the input file is day.month.year. So  here we additionally
"transform these conventions.
"
function! DateSubstitution()
	normal! mb
	/Date
	execute "normal! f:wyW"
	:bn
	/IPTCDate
	execute "normal! o\<esc>p0i\t\t\<esc>0"
	execute "normal! wf.;lywA\<space>\<esc>pBBf.lyw$pBByw$pBBdWjddgg"
	:w
	:bp
	execute "normal! `b"
endfunction	

function! StateSubstitution()
	normal! mc
	/State
	execute "normal! f:wy$"
	:bn
	/IPTCProvince
	execute "normal! o\<esc>p0i\t\t\<esc>0"
	:s / /%20/g
	execute "normal! jddgg"
	:w
	:bp
	execute "normal! `c"
endfunction	

function! CitySubstitution()
	normal! md
	/City
	execute "normal! f:wy$"
	:bn
	/IPTCCity
	execute "normal! o\<esc>p0i\t\t\<esc>0"
	:s / /%20/g
	execute "normal! jddgg"
	:w
	:bp
	execute "normal! `d"
endfunction	

function! CaptionSubstitution()
	execute "normal! me"
	/Caption
	execute "normal! f:wy$"
	:bn
	/IPTCCaption
	execute "normal! o\<esc>p0i\t\t\<esc>0"
	:s / /%20/g
	execute "normal! jddgg"
	:w
	:bp
	execute "normal! `e"
endfunction

"Sub() is a subfunction, which starts on a Keyword. We go down to the next
"Keyword, yank the whole line.
"In the following we are taking care of the necessary 64 character that
"Silverfast requires. In order to do that, we go to the top of the file,
"paste the keyword and go to the end of the line. Next we read out the cursor
"position. If the x Position or the column is smaller than 64 characters, we
"simply append the necessary whitespaces. If the line containing the keyword
"is greater than 64 characters, we simply cut it at the 64 character mark.
"Hence 0 has a different meaning in vim, we have to consider the case of 64 
"separately and simply leave the line as it is.
"In all three cases the line gets yanked and deleted. At the moment we don't
"use the u yank but rather the default yank, which is included in the dd.
"
"In every case we now have a line with the keyword in it, which has exactly 64 
"characters. Next up we go to the next buffer, find the location IPTCKeywords.
"Afterwords we go down one line to the previous inserted keywords and then
"paste the yanked line from our inputfile. Afterwards we substitute our
"whitespaces with %20 and combine the two lines to one, which leaves us
"at the correct position to repeat the process.

function! Sub()
	execute "normal! j0y$0"
	normal mb
	execute "normal! ggO\<esc>P$"
	let save_cursor = getcurpos()
	if save_cursor[2] < 64
		let xShift = 64-save_cursor[2]
		execute	"normal! ".xShift."a "
		normal! 0"uy$dd
		echo xShift
	elseif save_cursor[2] > 64
		:call cursor(1,64)	
		execute "normal! ld$"
		normal! 0"uy$dd
	elseif save_cursor[2] == 64
		normal! 0"uy$dd
	endif
	:w
	:bn
	/IPTCKeywords
	"execute "normal! jo\<esc>p0"
	execute "normal! jp0"
	:s / /%20/g
	execute "normal! kJxgg"
	:w
	:bp
	execute "normal! 'b"
endfunction

" In Silverfast the Keywords in the line /IPTCKeywords must correspond exactly
" to the number given by /IPTCKeywordCount in the IPTC file. Here we extract the
" number of keywords from the IPTC_Template, so in can vary.
" We simply go into the IPTC_Template file in the next buffer, or the copy
" saved under a different name to be exact, and copy the number under
" /IPTCKeywordCount without the %20 at the end.
"
function! ExtractKeywordnumber()
	normal mp
	:bn
	/IPTCKeywordCount
	execute "normal! jwywgg"
	:bf
	let Keywords_In_Templete= @"
	execute "normal! `p"
	return Keywords_In_Templete
endfunction

"The previous process of having to give the numbers of Keywords separately
"seems convoluted so we will now start to count the Keywords. In order for it
"to work, the Keywords must be given under the name Keywords: and only after
"the final Keyword there is a blank line required.
"The function simply goes to the word Keywords and then to the next blank
"line. Afterwards we simply calculate the difference.

function! CountKeywords()
	normal ma
	/Keywords:
	let save_cursorKeywords = getcurpos()
	execute "normal! }k"
	let save_cursorEndKeywords = getcurpos()
	let number_of_Keywords = save_cursorEndKeywords[1]-save_cursorKeywords[1]
	execute "normal! `a"
	return number_of_Keywords
endfunction

"The function KeywordsSubstitution() will now use the subfunction Sub()
"and add all the keywords given in the input file to the IPTC_Template.
"First we use the function CountKeywords() to extract the number of keywords
"already given in the IPTC_Template.
"Next we set c to 1 and search for Keywords.
"The courser will now be on Keywords, but the subfunction Sub() will go down
"one, and therefore be on the first keyword. The while loop now continuously 
"adds the keywords to the IPTC_Template file. At last we go back to our mark. 

function! KeywordsSubstitution()
	normal mz
	let var = CountKeywords()
	execute "normal! `z"
"	let var=@h

	let c=1
	/Keywords
	normal mb
	while c <= var
		:call Sub()
		let c += 1
	endwhile 

	execute "normal! `z"
endfunction	

" Again Silverfast needs the amount of Keywords as well and in a very
" particular way with a %20 at the end. We start using the two previous
" functions to extract the number of keywords already in the IPTC_Template and
" by counting the to be added number of keywords in our inputfile.
" Next we assign the result to the register q and switch to our IPTC_Template
" in the next buffer. Finally we remove the previous entry and replace it with
" the new one, including the obscure %20 at the end. Like always we save and
" move back to the input file.

function! KeywordNumberUpdate()
	normal mf
	let sta = ExtractKeywordnumber()
	let var = CountKeywords()
	let var += sta 
	let @q = var
	:bn
	/IPTCKeywordCount
	execute "normal! jddO\<esc>0"
	normal "qp
	execute "normal! 0i\<tab>\<tab>\<esc>wa\%20\<esc>gg"
	:w
	:bp
	execute "normal! `f"
endfunction

" In order to create the filename, I use a habit of mine to name
" the photos as "USA Travel Film 6 Photo 23". In other words I have the words
" Film and Photo with the respective number in the title. The filename will
" then be f06f23 (photo is foto in German).
" This function cheats as well, as I don't know how to combine strings in vim.
" So we start by going to the name, and extracting the number of the film and
" photo in registers 5 and 6 respectively.
" Then we go on top of the file, write f insert register 5, write f again and
" insert register 6. Finally we yank that word in the t register and delete it
" together with the new created line.


function! CreateFilename()
	normal! mf
	/Name
	execute "normal! f:/Film\<cr>w"
	normal "5ye
	execute "normal! /Photo\<cr>w"
	normal "6ye
"	let name="f".{@5}."f".{@6}
	execute "normal! ggOf\<esc>"
	normal "5p
	execute "normal! af\<esc>"
	normal "6p
	normal B"tywdd
	execute "normal! `f"
	:w
endfunction	


"Finally we wrap things up! 
"The function is supposed to be called at the input file before the IPTC Data
"for the next photo. We start by marking our spot and creating the filename.
"The filename will now be in the t register, so we assign it to the
"variable filename. All files will be saved in the home directory.
"This has the simple advantage, that this is the folder were Silverfast opens
"on default. Next up we add the IPTC_Template file to the next buffer.
"We now save our IPTC_Template under a new name f02f03 for instance. 
"The order of the buffers at this point is important.
"In buffer 1 will be the input file, in the second buffer will be the new
"saved file and the IPTC_Template moved to buffer 3. Furthermore the active
"buffer will be the last saved buffer 2.
"So next we go back to the previous buffer, the input file, and back to our
"mark.
"At this point we added a little control to look if the file we want to create
"already exists. In the previous version this let to a crash, since a file can't
"be overwritten and the script would start changing the IPTC_Template which
"at this point was useless.
"Now we simply check if the file exists and fie a short message. 
"NOTE: If the file exists it will not be overwritten. If you want to update
"it, you must first delete it manually.
"Now we can call all the functions, which will be applied to the next
"buffer, which is the new file, not the IPTC_Template.
"At the end will will still be on the input file - buffer 1 - and have to
"close the other buffers in order to be able to repeat the process.


function! Wrap()
	normal mw
	:call CreateFilename()
	let filename = @t
	let name = "/Users/schiffer/".filename
	execute ':badd' . "/Users/schiffer/.vim/plugin/IPTC_Template/IPTC_Template"
	:bn

	 if  filereadable(name)
		 echom "File ".name." already exits!"
		 sleep 1000m
		 redraw
	 else

	execute ':sav'. name 
	:bp
	execute "normal `w"
	:call NameSubstitution()
	:call DateSubstitution() 
	:call StateSubstitution()
	:call CitySubstitution()
	:call KeywordNumberUpdate()
	:call CaptionSubstitution()
	:call KeywordsSubstitution()

	 endif
	:.+,$bwipeout
endfunction


"nnoremap <leader>n :call NameSubstitution() <cr>
"nnoremap <leader>d :call DateSubstitution() <cr>
"nnoremap <leader>s :call StateSubstitution() <cr>
"nnoremap <leader>t :call CitySubstitution() <cr>
"nnoremap <leader>c :call CaptionSubstitution() <cr>
"nnoremap <leader>k :call KeywordsSubstitution() <cr>
"nnoremap <leader>h :call CreateFilename() <cr>
"nnoremap <leader>z :call KeywordCounter() <cr>
"nnoremap <leader>z :call ExtractKeywordnumber() <cr>
nnoremap <leader>w :call Wrap() <cr>
