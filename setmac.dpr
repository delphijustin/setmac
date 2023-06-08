program SetMAC;
{$APPTYPE console}
uses Sysutils,Classes,Windows;
var regfile,args:tstringlist;
oldmac,newmac,netid:Array[0..12]of char;
netName:array[0..255]of char;
netint,netints:hkey;
rs,I:Integer;
S:String;
function evalmac(lpMAC:PChar):boolean;
var I:integer;
begin
strpcopy(lpmac,stringreplace(lpmac,':','',[rfreplaceall]));
strpcopy(lpmac,stringreplace(lpmac,'-','',[rfreplaceall]));
strpcopy(lpmac,stringreplace(lpmac,'.','',[rfreplaceall]));
result:=(strlen(lpmac)=12);
for I:=0 to 11 do result:=result and(strtointdef('$'+lpmac[I],16)<16);
end;
procedure quit(exitcode:DWord=0);
begin
regfile.free;
args.free;
regclosekey(netints);
regclosekey(netint);
exitprocess(exitcode);
end;
procedure listInterfaces;
var I:Integer;
begin
I:=0;
writeln('ID# Driver Name:');
while(regenumkey(netints,I,high(netid))=error_success)do begin
regopenkeyex(netints,netid,0,key_Read,netint);
rs:=sizeof(netname);
strcopy(netname,'-');
regqueryvalueex(netint,'DriverDesc',nil,nil,@netname,@rs);
if(strtointdef(netid,-1)>-1)and(strlen(netid)=4)then writeln(Netid,#32,netname);
regclosekey(netint);
end;
end;
begin
if paramstr(1)='/?' then begin
writeln('Usage: ',extractfilename(paramstr(0)),' [/LIST] [/ID=IDNUMBER /NEWMAC=MACADDRESS]');
writeln;
writeln('Parameters:');
writeln('/LIST        Get a list of network cards and IDs');
writeln('/ID          ID of network card to modify. Use with /NEWMAC when it is used.');
writeln('/NEWMAC      Set this to the new mac address');
write('Press enter to quit...');readln;exitprocess(0);
end;
args:=tstringlist.create;
args.commatext:=getcommandline;
regfile:=tstringlist.create;
regopenkeyex(hkey_local_machine,'SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}',0,key_all_access,netints);
if (paramcount=0)then begin
listInterfaces;
netint:=hkey_users;
retry1:
if netint<>hkey_users then regclosekey(netint);
netint:=hkey_users;
write('Enter Interface ID: ');readln(netid);
if(strtointdef(s,-1)<0)or(length(s)<>4)or(regopenkeyex(netints,netid,0,key_all_access,netint)<>error_success)then begin 
writeln('Bad interface id');goto retry1;end;
retry2:
write('Enter New MAC Address: ');
readln(newmac);if not evalmac(newmac)then begin writeln('Bad MAC Address');goto retry2;end;
args.values['/NEWMAC']:=newmac;
args.values['/ID']:=netid;
end;
if (args.indexofname('/ID')>0)and(args.indexofname('/NEWMAC')>0)then begin
regfile.append('REGEDIT4');
regfile.append('');
regfile.append('[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}\'+args.values['/id']+']');
regopenkeyex(netints,Strplcopy(netid,args.values['/id'],12),0,key_all_access,netint);
rs:=sizeof(oldmac);
if regqueryvalueexa(netint,'NetworkAddress',nil,nil,@oldmac,@rs)=ERROR_SUCCESS then
regfile.append(format('"NetworkAddress"="%s"',[oldmac]))else regfile.append('"NetworkAddress"=-');
regfile.savetofile(changefileext(paramstr(0),'.reg'));
writeln('APPLYMAC: ',syserrormessage(regsetvalueex(netint,'NetworkAddress',0,reg_sz,@newmac,(strlen(newmac)+1)*Sizeof(char)));
quit;
end;
if args.indexof('/LIST')>0 then begin listinterfaces;quit;end;
writeln(syserrormessage(error_invalid_parameter));
quit(1);
end.
