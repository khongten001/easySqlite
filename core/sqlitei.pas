unit SqliteI;
{$MODE ObjFpc}
{$H+}

interface

uses
  Classes, SysUtils, SQLite3db;

type
  TSqliteConnector = class;

  TSqliteStatement = class(TObject)
    strict private
      QueryResult, Row: TStrings;
      RowPointer: Int64;
    private
      Connection: TSQLite;
      SqlString: String;
    strict private
      procedure ReplaceNextParam(AStringValue: String);
      function GetField(Index: Integer): String;
    public
      constructor Create();
      destructor Destroy; override;
    public
      function AffectedRows: Int64;
      function BindParam(ABoolean: Boolean): TSqliteStatement;
      function BindParam(AInteger: Integer): TSqliteStatement;
      function BindParam(AString: String): TSqliteStatement;
      function Booleans(Index: Int64): Boolean;
      function Count: Int64;
      function ErrorNumber: Int64;
      function ErrorMessage: String;
      function Execute: Boolean;
      function Fetch: Boolean;
      function FieldCount: Int64;
      function InsertRowId: Int64;
      function Integers(Index: Int64): Integer;
      function Seek(Index: Int64): Boolean;
      function Strings(Index: Int64): String;
  end;

  TSqliteConnector = class(TObject)
    strict private
      FDatabaseFilename: String;
    strict private
      function GetConnection: TSQLite;
    public
      constructor Create(ADatabaseFilename: String);
    public
      function Prepare(SqlString: String): TSqliteStatement;
  end;



implementation

(* == TSqliteStatement == *)

procedure TSqliteStatement.ReplaceNextParam(AStringValue: String);
begin
  SqlString := StringReplace(SqlString, '?', AStringValue, []);
end;

function TSqliteStatement.GetField(Index: Integer): String;
begin
  Result := Row.Strings[Index];
end;

constructor TSqliteStatement.Create;
begin
  inherited Create;
  QueryResult := TStringList.Create;
  Row := TStringList.Create;
  RowPointer := -1;
end;

destructor TSqliteStatement.Destroy;
begin
  FreeAndNil(Row);
  FreeAndNil(QueryResult);
  FreeAndNil(Connection);
  inherited Destroy;
end;

function TSqliteStatement.AffectedRows: Int64;
begin
  Result := Connection.ChangeCount;
end;

function TSqliteStatement.BindParam(ABoolean: Boolean): TSqliteStatement;
var
  StringValue: String;
begin
  if ABoolean then
    StringValue := '''TRUE'''
  else
    StringValue := '''FALSE''';
  ReplaceNextParam(StringValue);
  Result := Self;
end;

function TSqliteStatement.BindParam(AInteger: Integer): TSqliteStatement;
var
  StringValue: String;
begin
  StringValue := IntToStr(AInteger);
  ReplaceNextParam(StringValue);
  Result := Self;
end;

function TSqliteStatement.BindParam(AString: String): TSqliteStatement;
var
  StringValue: String;
begin
  StringValue := '''' + AString + '''';
  ReplaceNextParam(StringValue);
  Result := Self;
end;

function TSqliteStatement.Count: Int64;
begin
  Result := Int64(QueryResult.Count) - 1;
  if Result < 0 then
    Result := 0;
end;

function TSqliteStatement.ErrorNumber: Int64;
begin
  Result := Connection.LastError;
end;

function TSqliteStatement.ErrorMessage: String;
begin
  Result := Connection.LastErrorMessage;
end;

function TSqliteStatement.Execute: Boolean;
begin
  Result := Connection.Query(SqlString, QueryResult);
  RowPointer := -1;
end;

function TSqliteStatement.Fetch: Boolean;
begin
  Result := Seek(RowPointer + 1);
end;

function TSqliteStatement.FieldCount: Int64;
begin
  Result := Row.Count;
end;

function TSqliteStatement.InsertRowId: Int64;
begin
  Result := Connection.LastInsertRow;
end;

function TSqliteStatement.Booleans(Index: Int64): Boolean;
begin
  Result := StrToBool(GetField(Index));
end;

function TSqliteStatement.Integers(Index: Int64): Integer;
begin
  Result := StrToInt(GetField(Index));
end;

function TSqliteStatement.Strings(Index: Int64): String;
begin
  Result := GetField(Index);
end;

function TSqliteStatement.Seek(Index: Int64): Boolean;
begin
  if Index < 0 then Index := 0;
  if Index < Count then begin
    RowPointer := Index;
    Row.CommaText := QueryResult.Strings[RowPointer + 1];
  end else
    Result := False;
end;


(* == TSqliteConnector == *)

function TSqliteConnector.GetConnection: TSQLite;
begin
  Result := TSQLite.Create(FDatabaseFilename);
end;

constructor TSqliteConnector.Create(ADatabaseFilename: String);
begin
  inherited Create;
  FDatabaseFilename := ADatabaseFilename;
end;

function TSqliteConnector.Prepare(SqlString: String): TSqliteStatement;
begin
  Result := TSqliteStatement.Create();
  Result.Connection := GetConnection;
  Result.SqlString := SqlString;
end;

end.
