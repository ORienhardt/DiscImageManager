//++++++++++++++++++ General Purpose Methods +++++++++++++++++++++++++++++++++++

{-------------------------------------------------------------------------------
Reset a TDirEntry to blank
-------------------------------------------------------------------------------}
procedure ResetDirEntry(var Entry: TDirEntry);
begin
 with Entry do
 begin
  Parent       :='';
  Filename     :='';
  ShortFilename:='';
  Attributes   :='';
  Filetype     :='';
  ShortFiletype:='';
  LoadAddr     :=$0000;
  ExecAddr     :=$0000;
  Length       :=$0000;
  Side         :=$0000;
  Track        :=$0000;
  Sector       :=$0000;
  DirRef       :=$0000;
  TimeStamp    :=0;
  isDOSPart    :=False;
  Sequence     :=0;
 end;
end;

{-------------------------------------------------------------------------------
Remove top bit set characters
-------------------------------------------------------------------------------}
procedure RemoveTopBit(var title: String);
var
 t: Integer=0;
begin
 for t:=1 to Length(title) do title[t]:=chr(ord(title[t])AND$7F);
end;

{-------------------------------------------------------------------------------
Add top bit to spaces
-------------------------------------------------------------------------------}
function AddTopBit(title:String):String;
var
 i: Integer=0;
begin
 //We'll set the top bit on spaces
 for i:=1 to Length(title) do
  if ord(title[i])=32 then title[i]:=chr(32OR$80);
 Result:=title;
end;

{-------------------------------------------------------------------------------
Convert BBC to Windows filename
-------------------------------------------------------------------------------}
procedure BBCtoWin(var f: String);
var
 i: Integer=0;
begin
 for i:=1 to Length(f) do
 begin
  if f[i]='/' then f[i]:='.';
  if f[i]='?' then f[i]:='#';
  if f[i]='<' then f[i]:='$';
  if f[i]='>' then f[i]:='^';
  if f[i]='+' then f[i]:='&';
  if f[i]='=' then f[i]:='@';
  if f[i]=';' then f[i]:='%';
 end;
end;

{-------------------------------------------------------------------------------
Convert Windows to BBC filename
-------------------------------------------------------------------------------}
procedure WintoBBC(var f: String);
var
 i: Integer=0;
begin
 for i:=1 to Length(f) do
 begin
  if f[i]='.' then f[i]:='/';
  if f[i]='#' then f[i]:='?';
  if f[i]='$' then f[i]:='<';
  if f[i]='^' then f[i]:='>';
  if f[i]='&' then f[i]:='+';
  if f[i]='@' then f[i]:='=';
  if f[i]='%' then f[i]:=';';
 end;
end;

{-------------------------------------------------------------------------------
Removes trailing spaces from a string
-------------------------------------------------------------------------------}
procedure RemoveSpaces(var s: String);
var
 x: Integer=0;
begin
 //Start at the end
 x:=Length(s);
 if x>0 then
 begin
  while (s[x]=' ') and (x>0) do //Continue while the last character is a space
   dec(x);       //Move down the string
  s:=Copy(s,1,x);//Finally, remove the spaces
 end;
end;

{-------------------------------------------------------------------------------
Removes control characters from a string
-------------------------------------------------------------------------------}
procedure RemoveControl(var s: String);
var
 x: Integer=0;
 o: String='';
begin
 //Iterate through the old string
 for x:=1 to Length(s) do
  //Only add the character to the new string if it is not a control character
  if ord(s[x])>31 then o:=o+s[x];
 //Change the old string to the new string
 s:=o;
end;

{-------------------------------------------------------------------------------
Check to see if bit b is set in word v
------------------------------------------------------------------------------}
function IsBitSet(v,b: Integer): Boolean;
var
 x: Integer=0;
begin
 Result:=False;
 if (b>=0) and (b<32) then
 begin
  x:=1 shl b;
  Result:=((v AND x)=x);
 end;
end;

{-------------------------------------------------------------------------------
Break down an *.inf file entry
-------------------------------------------------------------------------------}
function BreakDownInf(s: String): TStringArray;
var
 i: Integer=0;
 f: String='';
begin
 //Remove leading spaces, if any
 if s[1]=' ' then
 begin
  i:=0;
  while s[i+1]=' ' do inc(i);
  s:=RightStr(s,Length(s)-i);
 end;
 //First field has opening quote
 if s[1]='"' then
 begin
  //Remove it
  s:=RightStr(s,Length(s)-1);
  //Find the closing quote
  if Pos('"',s)>0 then //Assuming it has one
  begin
   i:=1;
   while s[i]<>'"' do inc(i);
   //Extract the field
   f:=LeftStr(s,i-1);
   //And replace with a non-quoted field
   s:='filename '+RightStr(s,Length(s)-i);
  end;
 end;
 //Remove double spaces
 while Pos('  ',s)>0 do s:=ReplaceStr(s,'  ',' ');
 //Then split the string into fields
 Result:=s.Split(' ');
 //If we previously found a quoted field, replace the first one with it
 if f<>'' then Result[0]:=f;
end;

{-------------------------------------------------------------------------------
Ensures a string contains only visible ASCII characters
-------------------------------------------------------------------------------}
function FilenameToASCII(s: String): String;
var
 i: Integer=0;
begin
 for i:=1 to Length(s) do
  if(ord(s[i])<32)or(ord(s[i])>126)then s[i]:='?';
 Result:=s;
end;

{-------------------------------------------------------------------------------
Convert a attribute byte into a string
-------------------------------------------------------------------------------}
function GetAttributes(attr: String;format: Byte):String;
var
 attr1 : String='';
 attr2 : Byte=0;
begin
 {This converts a hex number to attributes. This hex number is different to what
 is used by ADFS internally (and saved to the disc images) but is what is
 returned by OSFILE A=5, or OS_File 5 on RISC OS.}
 attr1:=attr;
 attr2:=$00;
 Result:='';
 //Is it a hex number?
 if IntToHex(StrtoIntDef('$'+attr,0),2)=UpperCase(attr) then
 begin //Yes
  attr2:=StrToInt('$'+attr);
  attr1:='';
  //Read each attribute and build the string
  if(format>>4=diAcornDFS)
  or(format>>4=diAcornADFS)
  or(format>>4=diAcornUEF) then //ADFS, DFS and CFS
   if (Pos('L',attr1)>0)OR(attr2 AND$08=$08) then Result:=Result+'L';
  if format=diAcornADFS then //ADFS only
  begin
   if (Pos('R',attr1)>0)OR(attr2 AND$01=$01) then Result:=Result+'R';
   if (Pos('W',attr1)>0)OR(attr2 AND$02=$02) then Result:=Result+'W';
   if (Pos('E',attr1)>0)OR(attr2 AND$04=$04) then Result:=Result+'E';//Also P
   if (Pos('r',attr1)>0)OR(attr2 AND$10=$10) then Result:=Result+'r';
   if (Pos('w',attr1)>0)OR(attr2 AND$20=$20) then Result:=Result+'w';
   if (Pos('e',attr1)>0)OR(attr2 AND$40=$40) then Result:=Result+'e';
   if (Pos('l',attr1)>0)OR(attr2 AND$80=$80) then Result:=Result+'l';
  end;
 end else Result:=attr; //Not a hex, so just return what was passed
end;

{-------------------------------------------------------------------------------
Wildcard string comparison
-------------------------------------------------------------------------------}
function CompareString(S, mask: string; case_sensitive: Boolean): Boolean;
var
 sIndex   : Integer=1;
 maskIndex: Integer=1;
begin
 if not case_sensitive then
 begin
  S   :=UpperCase(S);
  mask:=UpperCase(mask);
 end;
 Result   :=True;
 while(sIndex<=Length(S))and(maskIndex<=Length(mask))do
 begin
  case mask[maskIndex] of
   '#':
   begin //matches any character
    Inc(sIndex);
    Inc(maskIndex);
   end;
   '*':
   begin //matches 0 or more characters, so need to check for next character in mask
    Inc(maskIndex);
    if maskIndex>Length(mask) then
     // * at end matches rest of string
     Exit;
    //look for mask character in S
    while(sIndex<=Length(S))and(S[sIndex]<>mask[maskIndex])do
     Inc(sIndex);
    if sIndex>Length(S) then
    begin //character not found, no match
     Result:=false;
     Exit;
    end;
   end;
   else
    if S[sIndex]=mask[maskIndex] then
    begin
     Inc(sIndex);
     Inc(maskIndex);
    end
    else
    begin //no match
     Result:=False;
     Exit;
    end;
  end;
 end;
 //if we have reached the end of both S and mask we have a complete match,
 //otherwise we only have a partial match}
 if(sIndex<=Length(S))or(maskIndex<=Length(mask))then
 begin
  //If the last character of the mask is a '*' then just exit without changing the result
  if maskIndex=Length(mask) then
   if mask[maskIndex]='*' then exit;
  Result:=false;
 end;
end;

{-------------------------------------------------------------------------------
Convert a TDateTime to an AFS compatible Word
-------------------------------------------------------------------------------}
function DateTimeToAFS(timedate: TDateTime):Word;
var
 y: Byte=0;
 m: Byte=0;
 d: Byte=0;
begin
 y:=StrToIntDef(FormatDateTime('yyyy',timedate),1981)-1981;//Year
 m:=StrToIntDef(FormatDateTime('m',timedate),1);           //Month
 d:=StrToIntDef(FormatDateTime('d',timedate),1);           //Date
 Result:=((y AND$F)<<12)OR((y AND$F0)<<1)OR(d AND$1F)OR((m AND$F)<<8);
end;

{-------------------------------------------------------------------------------
Convert an AFS date to a TDateTime
-------------------------------------------------------------------------------}
function AFSToDateTime(date: Word):TDateTime;
var
 day   : Integer=0;
 month : Integer=0;
 year  : Integer=0;
begin
 Result:=0;
 if date=0 then exit;
 day:=date AND$1F;//Day;
 month:=(date AND$F00)>>8; //Month
 year:=((date AND$F000)>>12)+((date AND$E0)>>1)+1981; //Year
 if(day>0)and(day<32)and(month>0)and(month<13)then
  Result:=EncodeDate(year,month,day);
end;

{------------------------------------------------------------------------------
Validate a filename for Windows
-------------------------------------------------------------------------------}
procedure ValidateWinFilename(var f: String);
var
 i: Integer=0;
const
  illegal = '\/:*?"<>|';
begin
 if Length(f)>0 then
  for i:=1 to Length(f) do
   if Pos(f[i],illegal)>0 then f[i]:=' ';
end;

{-------------------------------------------------------------------------------
Converts a decimal number to BCD
-------------------------------------------------------------------------------}
function DecToBCD(dec: Cardinal): Cardinal;
var
 s: String='';
 i: Integer=0;
begin
 Result:=0;
 s:=IntToStr(dec);
 for i:=Length(s) downto 1 do
  inc(Result,StrToInt(s[i])<<(4*(Length(s)-i)));
end;

{-------------------------------------------------------------------------------
Converts a BCD to decimal number
-------------------------------------------------------------------------------}
function BCDToDec(BCD: Cardinal): Cardinal;
var
 s: String='';
 i: Integer=0;
begin
 Result:=0;
 s:=IntToHex(BCD);
 for i:=Length(s) downto 1 do
  inc(Result,StrToIntDef(s[i],0)*(10**(Length(s)-i)));
end;

{-------------------------------------------------------------------------------
Reset a TFileEntry to default values
-------------------------------------------------------------------------------}
procedure ResetFileEntry(var fileentry: TFileEntry);
begin
 with fileentry do
 begin
  LoadAddr   :=0;
  ExecAddr   :=0;
  Length     :=0;
  Size       :=0;
  NumEntries :=0;
  Attributes :=0;
  DataOffset :=0;
  Filename   :='';
  Parent     :='';
  ArchiveName:='';
  Directory  :=False;
 end;
end;
