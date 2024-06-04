{$INCLUDE doomrl.inc}
{
----------------------------------------------------
DFMAP.PAS -- Map data and handling for DownFall
Copyright (c) 2002 by Kornel "Anubis" Kisielewicz
----------------------------------------------------
}
unit dfmap;
interface
uses vutil, vmath, dfdata;

type TCellHook  = (CellHook_OnEnter, CellHook_OnExit, CellHook_OnAct, CellHook_OnDescribe, CellHook_OnDestroy);
     TCellHooks = set of TCellHook;
const CellHooks : array[TCellHook] of string = ('OnEnter', 'OnExit', 'OnAct', 'OnDescribe', 'OnDestroy');

type TMap = object
       Overlay  : array[ 1..MaxX, 1..MaxY ] of Byte;
       Rotation : array[ 1..MaxX, 1..MaxY ] of Byte;
       Style    : array[ 1..MaxX, 1..MaxY ] of Byte;
     end;

type TCell = class
  PicChr      : Char;
  PicLow      : Char;
  Sprite      : array[0..15] of TSprite;
  BloodSprite : TSprite;
  LightColor  : Byte;
  DarkColor   : Byte;
  BloodColor  : Byte;
  Desc        : AnsiString;
  BlDesc      : AnsiString;
  DR          : Byte;
  HP          : Byte;
  Flags       : TFlags;
  Hooks       : TCellHooks;
  bloodto     : AnsiString;
  destroyto   : AnsiString;
  raiseto     : AnsiString;
end;
            

type

{ TCells }

TCells = class
         public
           procedure RegisterCell( aCellNum : Byte );
           destructor Destroy; override;
         private
           FData     : array of TCell;
           FMaxCells : Byte;
           function getCell( aIndex : Byte ) : TCell;
         public
           property Cells[ aIndex : Byte ] : TCell read getCell; default;
           property Max : Byte read FMaxCells;
         end;

var Cells : TCells;

implementation

uses SysUtils, vluasystem, vcolor, vdebug;

procedure TCells.RegisterCell( aCellNum : byte );
var iColorID : AnsiString;
    iHook    : TCellHook;
    iCell    : TCell;
    iTable   : TLuaTable;
    iSprite  : TSprite;
begin
  if aCellNum >= High( FData ) then
  begin
    SetLength( FData, vmath.Max( High( FData ) * 2, 100 ) );
    FMaxCells := aCellNum;
  end;
  if aCellNum > FMaxCells then FMaxCells := aCellNum;

  iCell  := TCell.Create;
  iTable := LuaSystem.GetTable(['cells',aCellNum]);
  with iTable do
  try
    iColorID := getString('id');
    if IsString('color_id') then iColorID := getString('color_id');
    
   iCell.Hooks := [];
    for iHook in TCellHooks do
      if isFunction( CellHooks[ iHook ] ) then
        Include( iCell.Hooks,iHook );

    iCell.PicChr    := getChar('ascii');
    iCell.PicLow    := getChar('asciilow');
    iCell.DarkColor := getInteger('color_dark');
    iCell.LightColor:= getInteger('color');
    iCell.BloodColor:= getInteger('blcolor');
    iCell.Desc      := getString('name');
    iCell.BlDesc    := getString('blname');
    iCell.DR        := getInteger('armor');
    iCell.HP        := getInteger('hp');
    iCell.Flags     := getFlags('flags');
    iCell.bloodto   := getString('bloodto');
    iCell.destroyto := getString('destroyto');
    iCell.raiseto   := getString('raiseto');
    FillChar( iCell.Sprite, SizeOf(iCell.Sprite), 0 );
    ReadSprite( iTable, iCell.Sprite[0] );
    iCell.BloodSprite.SpriteID := getInteger('blsprite',0);
  finally
    Free;
  end;

  if (not Option_HighASCII) then iCell.PicChr := iCell.PicLow;

  if ColorOverrides.Exists(iColorID+'_light') then
    iCell.LightColor := ColorOverrides[iColorID+'_light'];
  if ColorOverrides.Exists(iColorID+'_dark') then
    iCell.DarkColor:= ColorOverrides[iColorID+'_dark'];

  FData[aCellNum] := iCell;
end;

function TCells.getCell( aIndex : Byte ) : TCell;
begin
  Exit( FData[ aIndex ] );
end;

destructor TCells.Destroy;
var iCell : TCell;
begin
  for iCell in FData do
    iCell.Free;
end;


end.
