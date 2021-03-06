/// abstract database direct access classes
// - this unit is a part of the freeware Synopse framework,
// licensed under a MPL/GPL/LGPL tri-license; version 1.18
unit SynDB;

{
    This file is part of Synopse framework.

    Synopse framework. Copyright (C) 2014 Arnaud Bouchez
      Synopse Informatique - http://synopse.info

  *** BEGIN LICENSE BLOCK *****
  Version: MPL 1.1/GPL 2.0/LGPL 2.1

  The contents of this file are subject to the Mozilla Public License Version
  1.1 (the "License"); you may not use this file except in compliance with
  the License. You may obtain a copy of the License at
  http://www.mozilla.org/MPL

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
  for the specific language governing rights and limitations under the License.

  The Original Code is Synopse mORMot framework.

  The Initial Developer of the Original Code is Arnaud Bouchez.

  Portions created by the Initial Developer are Copyright (C) 2014
  the Initial Developer. All Rights Reserved.

  Contributor(s):
  - delphinium


  Alternatively, the contents of this file may be used under the terms of
  either the GNU General Public License Version 2 or later (the "GPL"), or
  the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
  in which case the provisions of the GPL or the LGPL are applicable instead
  of those above. If you wish to allow use of your version of this file only
  under the terms of either the GPL or the LGPL, and not to allow others to
  use your version of this file under the terms of the MPL, indicate your
  decision by deleting the provisions above and replace them with the notice
  and other provisions required by the GPL or the LGPL. If you do not delete
  the provisions above, a recipient may use your version of this file under
  the terms of any one of the MPL, the GPL or the LGPL.

  ***** END LICENSE BLOCK *****

  Version 1.14
  - first public release, corresponding to SQLite3 Framework 1.14

  Version 1.15
  - SynDB unit extracted from previous SynOleDB.pas
  - TQueryValue.As* methods now handle NULL column as 0 or ''
  - added new TSQLDBRowVariantType custom variant type, allowing late binding
    access to row columns (not for Delphi 5) - see RowData method
  - fixed transaction handling in a safe abstract manner
  - TSQLDBStatement class now expects a prepared statement behavior, therefore
    TSQLDBStatementPrepared class has been merged into its parent class, and
    inherited classes have been renamed TSQLDBStatementWithParams[AndColumns]
  - new TSQLDBStatement.FetchAllAsJSON method for JSON retrieval as RawUTF8
  - exposed FetchAllAsJSON method for ISQLDBRows interface
  - made the code compatible with Delphi 5
  - new TSQLDBConnectionProperties.SQLIso8601ToDate virtual method
  - code refactoring for better metadata (database and table schemas) handling,
    including GetTableNames, GetFields, GetFieldDefinitions and GetForeignKey
    methods - will work with OleDB metadata and direct Oracle sys.all_* tables
  - new TSQLDBConnectionProperties.SQLCreate/SQLAddColumn/SQLAddIndex virtual
    methods (SQLCreate and SQLAddColumn will use the new protected SQLFieldCreate
    virtual method to retrieve the SQL field definition from protected
    fSQLCreateField[Max] properties) - as a result, SQL statement generation as
    requested for mORMot is now much more generic than previously
  - new overloaded TSQLDBStatement.Execute() method, able to mix % and ?
    parameters in the SQL statement
  - new TSQLDBStatement.BindNull() method
  - new TSQLDBConnectionProperties.NewThreadSafeStatementPrepared and
    TSQLDBConnection.NewStatementPrepared methods, able to be overridden to
    implement a SQL statement caching (used e.g. for SynDBSQLite3)
  - new TSQLDBConnection.ServerTimeStamp property, which will return the
    external database Server current date and time as TTimeLog/Int64 value
    (current implementation handle Oracle, MSSQL and MySQL database engines -
    with SQLite3, this will be the local PC time, just as for other DB engines)
  - new overloaded TSQLDBStatement.Bind() method, which can bind an array
    of const (i.e. an open list of Delphi arguments) to a statement
  - new overloaded TSQLDBStatement.Bind() and ColumnToVarData() methods, able
    to bind or retrieve values from a TVarData/TVarDataDynArray (used e.g.
    for direct access to/from SQLite3 virtual table in the SQLite3DB unit)
  - new ColumnTimeStamp method for TSQLDBStatement/ISQLDBRows, returning a
    TTimeLog/Int64 value for a date/time column

  Version 1.16
  - both TSQLDBStatement.FetchAllToJSON and FetchAllAsJSON methods now return
    the number of rows data fetched (excluding field names)
  - new class method TSQLDBConnectionProperties.GetFieldDefinition()
  - new method TSQLDBStatement.FetchAllToCSVValues() for fast to-file CSV export
  - new TSQLDBStatement.ColumnsToSQLInsert() and BindFromRows() methods to allow
    fast data conversion/export between databases
  - new TSQLDBConnectionProperties.SQLSelectAll method to retrieve a SELECT
    statement according to a DB column expected layout
  - new TSQLDBConnectionProperties.ClearConnectionPool method (could be used
    to recreate all connections in case of DB or network failure/timeout)
  - fixed issue in TSQLDBConnection.GetServerTimeStamp method

  Version 1.17
  - code refactoring to allow direct ODBC connection implementation
  - fixed random issue in TSQLDBConnection.GetServerTimeStamp method (using
    wrongly TTimeLog direct arithmetic, therefore raising EncodeTime() errors)
  - fixed issue about creating unexisting NCLOB instead of CLOB/NCLOB
  - fixed TQuery implementation to match the expected original behavior
    (e.g. SQL.Clear) - also undefined buggy Last method (use ORDER DESC instead)
  - fixed issue in TQuery when executing requests with parameters
  - fixed issues in TQuery when translated SQL from named parameters to
    positioned (?) parameters, and escaping strings
  - enhanced MySQL DBMS back-end compatibility
  - TQuery will now accept reused parameters in the SQL statement (just like
    the original class)
  - added TQueryValue.AsLargeInt property alias for better compatibility
  - enhanced TSQLDBStatement.BindVariant() to handle varBoolean value as integer,
    and to avoid most temporary conversions to string
  - enhanced TSQLDBStatement.Bind(Params: TVarDataDynArray) to handle varDate,
    and modified TQueryValue in consequence
  - enhanced TSQLDBStatement.Bind(const Params: array of const) to accept
    BLOB content, when transmitted after BinToBase64WithMagic() conversion,
    and TDateTime parameters via Date[Time]ToSQL() encoding 
  - declared TSQLDBConnectionProperties.GetMainConnection() method as virtual,
    then override it for thread-safe connections - see ticket [65e24b2de4]
  - now TSQLDBStatement.ColumnToVarData method will store '' when TDateTime value
    is 0, or a pure date or a pure time if the value is defined as such, just as
    expected by http://www.sqlite.org/lang_datefunc.html - i.e. SQLite3DB
  - added FieldSize optional parameter to TSQLDBStatement.ColumnType() method
    (used e.g. by SynDBVCL to provide the expected field size on TDataSet)
  - added TSQLDBStatement.ColumnBlobBytes() methods to retrieve TBytes BLOBs
  - added TSQLDBConnection.InTransaction property
  - added TSQLDBConnectionProperties.EngineName property
  - added TSQLDBConnectionProperties.DBMS property, and huge code refactoring
    among all SynDB* units for generic handling of DBMS-specific properties
  - added TSQLDBConnectionProperties.AdaptSQLLimitForEngineList for handling
    the LIMIT # statement in a database-agnostic form
  - added TSQLDBConnectionProperties.BatchSendingAbilities property to define
    the CRUD modes available in batch sending (see e.g. Oracle's array bind,
    or MS SQL bulk insert feature)
  - added direct access to the columns description via new property
    TSQLDBStatementWithParamsAndColumns.Columns
  - added TSQLDBColumnProperty.ColumnUnique property (mainly for
    TSQLDBConnectionProperties.SQLFieldCreate to create proper SQL)
  - new TSQLDBStatement.BindArray*() methods, introducing array binding for
    faster database batch modifications (only implemented in SynDBOracle by now)

  Version 1.18
  - SQL statements are now cached by default - in some cases, it will increase
    individual reading or writing speed by a factor of 4x
  - TSQLDBConnectionProperties.Create will set ForcedSchemaName := 'dbo'
    ("DataBase Owner") by default for dMSSQL kind of database engine
  - new TSQLDBConnectionProperties/TSQLDBConnection.OnProcess event handlers
  - added TSQLDBConnectionProperties.StoreVoidStringAsNull, which will be
    set e.g. for MS SQL and Jet databases which do not allow by default to
    store '' values, but expect NULL instead
  - TSQLDBConnection.Connect will now trigger OnProcess(speReconnected) and
    update the new TSQLDBConnection.TotalConnectionCount property
  - TSQLDBConnection.Disconnect will now flush internal statement cache
  - TQuery.Execute() is now able to try to re-connect once in case of failure
  - fixed issue with bound parameter in TQuery.Execute() for Unicode Delphi
  - introducing new ISQLDBStatement interface, used by SQL statement cache
  - avoid syntax error for some engines which do not accept an ending ';' in
    SQL statements
  - added RaiseExceptionOnError: boolean=false optional parameter to
    TSQLDBConnection.NewStatementPrepared() method
  - added TSQLDBConnection.LastErrorMessage and LastErrorException properties,
    to retrieve the error when NewStatementPrepared() returned nil
  - added TSQLDBConnectionProperties.ForcedSchemaName optional property
  - added TSQLDBConnectionProperties.SQLGetIndex() and GetIndexes() methods
    to retrieve advanced information about database indexes (e.g. for indexes
    created after multiple columns)
  - added TSQLDBConnectionProperties.SQLTableName() method
  - added TSQLDBConnectionProperties.SQLSplitTableName() and SQLFullTableName()
  - now TSQLDBConnectionProperties.SQLAddIndex() will handle schema name and
    will ensure that the generated identifier won't be too long 
  - added TSQLDBConnectionProperties.ExecuteInlined() overloaded methods
  - added TSQLDBConnectionPropertiesThreadSafe.ForceOnlyOneSharedConnection
    property to by-pass internal thread-pool (e.g. for embedded engines)
  - enhanced TSQLDBConnectionPropertiesThreadSafe.ThreadSafeConnection speed
  - declared all TSQLDBConnectionProperties.SQL*() methods as virtual
  - TSQLDBConnectionProperties.SQLAddIndex() will now generate IF NOT EXISTS
    statements, if the corresponding DBMS supports it (only SQLite3 AFAIK),
    and handle MSSQL as expected (i.e. without 'dbo.' in INDEX name)
  - additional aDescending parameter to TSQLDBConnectionProperties.SQLAddIndex()
  - added TSQLDBConnectionProperties.OnBatchInsert property and the corresponding
    MultipleValuesInsert() protected method to implement INSERT multiple VALUES
  - added dFirebird, dNexusDB, dPostgreSQL and dDB2 kind of database in
    TSQLDBDefinition, including associated SQL requests to retrieve metadata
  - let TSQLDBConnectionProperties.SQLTableName() handle quoted table names
  - added TSQLDBConnection.NewTableFromRows() method to dump a SQL statement
    result into a new table of any database (may be used for replication)
  - "rowCount": is added in TSQLDBStatement.FetchAllToJSON at the end of the
    non-expanded JSON content, if needed - improves client parsing performance
  - TSQLDBStatement.FetchAllToJSON will now add column names (in non-expanded
    JSON format) if no data row is returned - just like TSQLRequest.Execute
  - TSQLDBConnectionProperties.SQLSelectAll() now handles spaces in table names
  - TSQLDBStatement.GetParamValueAsText() will truncate to a given number of
    chars the returned text
  - added DoNotFletchBlobs optional parameter to TSQLDBStatement.FetchAllAsJSON()
    FetchAllToJSON(), and ColumnsToJSON() methods (used e.g. by SynDBExplorer)
  - added RewindToFirst optional parameter to TSQLDBStatement.FetchAllAsJSON()
    and FetchAllToJSON() methods (could be used e.g. for TQuery.FetchAllAsJSON)
  - added new TSQLDBStatement.ExecutePreparedAndFetchAllAsJSON() method for
    direct retrieval of JSON rows from a prepared statement
  - added new TSQLDBStatement.PrepareInlined() methods (used by mORMotDB.pas)
  - added direct result export into optimized binary content, via the new
    TSQLDBStatement.FetchAllToBinary() method (used e.g. by TSQLDBProxyConnection)
  - new TSQLDBProxyConnectionProperties, TSQLDBProxyConnection and
    TSQLDBProxyStatement abstract classes for generic mean of connection
    remoting (to be used e.g. for background thread or remote execution)
  - replaced confusing TVarData by a new dedicated TSQLVar memory structure,
    shared with mORMot and mORMotSQLite3 units (includes methods refactoring)
  - TSQLDBFieldType is now defined in SynCommons, and used by TSQLVar and all
    database-related process (i.e. in mORMot and SynDB units)
  - added Bind(TSQLVar) overloaded method to ISQLDBStatement/TSQLDBStatement
  - added missing ColumnToSQLVar() method to ISQLDBRows interface
  - added TSQLDBStatement.ColumnsToBinary() method
  - method TSQLDBStatement.ColumnTypeNativeToDB() is now public, and will
    recognize uniqueidentifier data type as ftUTF8
  - added TSQLDBStatementWithParams.BindFromRows() method
  - new TSQLDBProxyStatementRandomAccess class for in-memory browsing of data
    retrieved via TSQLDBStatement.FetchAllToBinary()
  - added TSQLDBConnectionPropertiesThreadSafe.ThreadingMode property instead
    of limited boolean property ForceOnlyOneSharedConnection
  - added generic ReplaceParamsByNames() function, which allows 'END;' at the
    end of a statement to fulfill ticket [4a7da3c6a1]
  - added TSQLDBConnection[Properties].OnProgress callback event handler
  - now trim any spaces when retrieving database schema text values
  - fixed ticket [4c68975022] about broken SQL statement when logging active
  - fixed ticket [545fbe7579] about TSQLDBConnection.LastErrorMessage not reset
  - fixed ticket [d465da9843] when guessing SQLite3 column type from its
    affinity - see http://www.sqlite.org/datatype3.html
  - fixed potential GPF after TSQLDBConnectionProperties.ExecuteNoResult() method call
  - fixed TSQLDBConnectionProperties.SQLGetField() returned value for dFirebird
  - fixed TSQLDBConnectionProperties.ColumnTypeNativeToDB() for dFirebird
  - fixed unnecessary limitation to 64 params for TSQLDBStatementWithParams
  - TSQLDBStatement.Bind() will now handle a nil parameter to SQL null bound value
  - TSQLDBStatement.ColumnToVariant() will now handle VariantStringAsWideString
  - function ReplaceParamsByNames() won't generate any SQL keyword parameters
    (e.g. :AS :OF :BY), to be compliant with Oracle OCI expectations
  - added property RollbackOnDisconnect, set to TRUE by default, to ensure
    any pending uncommitted transaction is roll-backed - see [dc64fe169b]
  - added TSQLDBConnectionProperties.GetIndexesAndSetFieldsColumnIndexed()
    internal method, used by some overridden GetFields() implementations


}

{$I Synopse.inc} // define HASINLINE USETYPEINFO CPU32 CPU64 OWNNORMTOUPPER

interface

/// if defined, a TQuery class will be defined to emulate the BDE TQuery class
{$define EMULATES_TQUERY}

{$ifdef LVCL}
  {$undef EMULATES_TQUERY}
{$endif}

uses
  Windows,
  {$ifdef ISDELPHIXE2}System.SysUtils,{$else}SysUtils,{$endif}
  Classes,
  {$ifndef LVCL}
  Contnrs,
  {$endif}
  {$ifndef DELPHI5OROLDER}
  Variants,
  {$endif}
  SynCommons;

  
{ -------------- TSQLDB* generic classes and types }

type
  /// generic Exception type, as used by the SynDB unit
  ESQLDBException = class(Exception);

  // NOTE: TSQLDBFieldType is defined in SynCommons.pas (used by TSQLVar)
  
  /// an array of RawUTF8, for each existing column type
  // - used e.g. by SQLCreate method
  // - ftUnknown maps ID field (as integer), ftNull maps RawUTF8 index # field,
  // ftUTF8 maps RawUTF8 blob field, other types map their default kind 
  // - for UTF-8 text, ftUTF8 will define the BLOB field, whereas ftNull will
  // expect to be formated with an expected field length in ColumnAttr
  // - the RowID definition will expect the ORM to create an unique identifier,
  // and will use the ftUnknown type definition for this (may be not the same
  // as ftInt64, e.g. for SQLite3 it should be INTEGER and not BIGINT)
  // and send it with the INSERT statement (some databases, like Oracle, do not
  // support standard's IDENTITY attribute) - see http://troels.arvin.dk/db/rdbms
  TSQLDBFieldTypeDefinition = array[TSQLDBFieldType] of RawUTF8;

  /// the diverse type of bound parameters during a statement execution
  // - will be paramIn by default, which is the case 90% of time
  // - could be set to paramOut or paramInOut if must be refereshed after
  // execution (for calling a stored procedure expecting such parameters)
  TSQLDBParamInOutType =
    (paramIn, paramOut, paramInOut);

  /// used to define a field/column layout in a table schema
  // - for TSQLDBConnectionProperties.SQLCreate to describe the new table
  // - for TSQLDBConnectionProperties.GetFields to retrieve the table layout
  TSQLDBColumnDefine = packed record
    /// the Column name
    ColumnName: RawUTF8;
    /// the Column type, as retrieved from the database provider
    // - returned as plain text by GetFields method, to be used e.g. by
    // TSQLDBConnectionProperties.GetFieldDefinitions method
    // - SQLCreate will check for this value to override the default type
    ColumnTypeNative: RawUTF8;
    /// the Column default width (in chars or bytes) of ftUTF8 or ftBlob
    // - can be set to value <0 for CLOB or BLOB column type, i.e. for
    // a value without any maximal length
    ColumnLength: PtrInt;
    /// the Column data precision
    // - used e.g. for numerical values
    ColumnPrecision: PtrInt;
    /// the Column data scale
    // - used e.g. for numerical values
    ColumnScale: PtrInt;
    /// the Column type, as recognized by our SynDB classes
    // - should not be ftUnknown nor ftNull
    ColumnType: TSQLDBFieldType;
    /// specify if column is indexed
    ColumnIndexed: boolean;
  end;

  /// used to define the column layout of a table schema
  // - e.g. for TSQLDBConnectionProperties.GetFields
  TSQLDBColumnDefineDynArray = array of TSQLDBColumnDefine;

  /// used to describe extended Index definition of a table schema
  TSQLDBIndexDefine = packed record
    /// name of the index
    IndexName: RawUTF8;
    /// description of the index type
    // - for MS SQL possible values are:
    // ! HEAP | CLUSTERED | NONCLUSTERED | XML |SPATIAL
    //  - for Oracle:
    // ! NORMAL | BITMAP | FUNCTION-BASED NORMAL | FUNCTION-BASED BITMAP | DOMAIN
    //  see @http://docs.oracle.com/cd/B19306_01/server.102/b14237/statviews_1069.htm
    TypeDesc: RawUTF8;
    /// Expression for the subset of rows included in the filtered index
    // - only set for MS SQL - not retrieved for other DB types yet
    Filter: RawUTF8;
    /// comma separated list of indexed column names, in order of their definition
    KeyColumns: RawUTF8;
    /// comma separaded list of a nonkey column added to the index by using the CREATE INDEX INCLUDE clause
    // - only set for MS SQL - not retrieved for other DB types yet
    IncludedColumns: RawUTF8;
    /// if Index is unique
    IsUnique: boolean;
    /// if Index is part of a PRIMARY KEY constraint
    // - only set for MS SQL - not retrieved for other DB types yet
    IsPrimaryKey: boolean;
    /// if Index is part of a UNIQUE constraint
    // - only set for MS SQL - not retrieved for other DB types yet
    IsUniqueConstraint: boolean;
  end;

  /// used to describe extended Index definition of a table schema
  // - e.g. for TSQLDBConnectionProperties.GetIndexes
  TSQLDBIndexDefineDynArray = array of TSQLDBIndexDefine;

  /// possible column retrieval patterns
  // - used by TSQLDBColumnProperty.ColumnValueState
  TSQLDBStatementGetCol = (colNone, colNull, colWrongType, colDataFilled, colDataTruncated);

  /// used to define a field/column layout
  // - for TSQLDBConnectionProperties.SQLCreate to describe the table
  // - for T*Statement.Execute/Column*() methods to map the IRowSet content
  TSQLDBColumnProperty = packed record
    /// the Column name
    ColumnName: RawUTF8;
    /// a general purpose integer value
    // - for SQLCreate: default width (in WideChars or Bytes) of ftUTF8 or ftBlob;
    // if set to 0, a CLOB or BLOB column type will be created - note that
    // UTF-8 encoding is expected when calculating the maximum column byte size
    // for the CREATE TABLE statement (e.g. for Oracle 1333=4000/3 is used)
    // - for TOleDBStatement: the offset of this column in the IRowSet data,
    // starting with a DBSTATUSENUM, the data, then its length (for inlined
    // sftUTF8 and sftBlob only)
    // - for TSQLDBOracleStatement: contains an offset to this column values
    // inside fRowBuffer[] internal buffer
    // - for TSQLDBDatasetStatement: maps TField pointer value
    ColumnAttr: PtrUInt;
    /// the Column type, used for storage
    // - for SQLCreate: should not be ftUnknown nor ftNull
    // - for TOleDBStatement: should not be ftUnknown
    // - for SynDBOracle: never ftUnknown, may be ftNull (for SQLT_RSET)
    ColumnType: TSQLDBFieldType;
    /// set if the Column must exists (i.e. should not be null)
    ColumnNonNullable: boolean;
    /// set if the Column shall have unique value (add the corresponding constraint)
    ColumnUnique: boolean;
    /// set if the Column data is inlined within the main rows buffer
    // - for TOleDBStatement: set if column was NOT defined as DBTYPE_BYREF
    // which is the most common case, when column data < 4 KB
    // - for TSQLDBOracleStatement: FALSE if column is an array of
    // POCILobLocator (SQLT_CLOB/SQLT_BLOB) or POCIStmt (SQLT_RSET)
    // - for TSQLDBODBCStatement: FALSE if bigger than 255 WideChar (ftUTF8) or
    // 255 bytes (ftBlob)
    ColumnValueInlined: boolean;
    /// expected column data size
    // - for TSQLDBOracleStatement/TOleDBStatement/TODBCStatement: used to store
    // one column size (in bytes)
    ColumnValueDBSize: cardinal;
    /// optional character set encoding for ftUTF8 columns
    // - for SQLT_STR/SQLT_CLOB (SynDBOracle): equals to the OCI char set
    ColumnValueDBCharSet: integer;
    /// internal DB column data type
    // - for TSQLDBOracleStatement: used to store the DefineByPos() TypeCode,
    // can be SQLT_STR/SQLT_CLOB, SQLT_FLT, SQLT_INT, SQLT_DAT, SQLT_BLOB,
    // SQLT_BIN and SQLT_RSET
    // - for TSQLDBODBCStatement: used to store the DataType as returned
    // by ODBC.DescribeColW() - use private ODBC_TYPE_TO[ColumnType] to
    // retrieve the marshalled type used during column retrieval
    // - for TSQLDBFirebirdStatement: used to store XSQLVAR.sqltype
    // - for TSQLDBDatasetStatement: indicates the TField class type, i.e.
    // 0=TField, 1=TLargeIntField, 2=TWideStringField
    ColumnValueDBType: smallint;
    /// driver-specific encoding information
    // - for SynDBOracle: used to store the ftUTF8 column encoding, i.e. for
    // SQLT_CLOB, equals either to SQLCS_NCHAR or SQLCS_IMPLICIT
    ColumnValueDBForm: byte;
    /// may contain the current status of the column value
    // - for SynDBODBC: state of the latest SQLGetData() call
    ColumnDataState: TSQLDBStatementGetCol;
    /// may contain the current column size for not FIXEDLENGTH_SQLDBFIELDTYPE
    // - for SynDBODBC: size (in bytes) in corresponding fColData[] 
    // - TSQLDBProxyStatement: the actual maximum column size
    ColumnDataSize: integer;
  end;

  PSQLDBColumnProperty = ^TSQLDBColumnProperty;

  /// used to define a table/field column layout
  TSQLDBColumnPropertyDynArray = array of TSQLDBColumnProperty;

  /// identify a CRUD mode of a statement
  TSQLDBStatementCRUD = (
    cCreate, cRead, cUpdate, cDelete);

  /// identify the CRUD modes of a statement
  // - used e.g. for batch send abilities of a DB engine 
  TSQLDBStatementCRUDs = set of TSQLDBStatementCRUD;

  /// the known database definitions
  // - will be used e.g. for TSQLDBConnectionProperties.SQLFieldCreate(), or
  // for OleDB/ODBC/ZDBC tuning according to the connected database engine  
  TSQLDBDefinition = (dUnknown, dDefault, dOracle, dMSSQL, dJet, dMySQL,
    dSQLite, dFirebird, dNexusDB, dPostgreSQL, dDB2);

  /// set of the available database definitions
  TSQLDBDefinitions = set of TSQLDBDefinition;

  TSQLDBStatement = class;

{$ifndef LVCL}
{$ifndef DELPHI5OROLDER}
  /// a custom variant type used to have direct access to a result row content
  // - use ISQLDBRows.RowData method to retrieve such a Variant
  TSQLDBRowVariantType = class(TSynInvokeableVariantType)
  protected
    procedure IntGet(var Dest: TVarData; const V: TVarData; Name: PAnsiChar); override;
    procedure IntSet(const V, Value: TVarData; Name: PAnsiChar); override;
  end;
{$endif}
{$endif}

  /// generic interface to access a SQL query result rows
  // - not all TSQLDBStatement methods are available, but only those to retrieve
  // data from a statement result: the purpose of this interface is to make
  // easy access to result rows, not provide all available features - therefore
  // you only have access to the Step() and Column*() methods
  ISQLDBRows = interface
    ['{11291095-9C15-4984-9118-974F1926DB9F}']
    {/ After a prepared statement has been prepared returning a ISQLDBRows
      interface, this method must be called one or more times to evaluate it
     - you shall call this method before calling any Column*() methods
     - return TRUE on success, with data ready to be retrieved by Column*()
     - return FALSE if no more row is available (e.g. if the SQL statement
      is not a SELECT but an UPDATE or INSERT command)
     - access the first or next row of data from the SQL Statement result:
       if SeekFirst is TRUE, will put the cursor on the first row of results,
       otherwise, it will fetch one row of data, to be called within a loop
     - should raise an Exception on any error
     - typical use may be:
     ! var Customer: Variant;
     ! begin
     !   with Props.Execute( 'select * from Sales.Customer where AccountNumber like ?', ['AW000001%'],@Customer) do
     !     while Step do // loop through all matching data rows
     !       assert(Copy(Customer.AccountNumber,1,8)='AW000001');
     ! end;
    }
    function Step(SeekFirst: boolean=false): boolean;
     
    {/ the column/field count of the current Row }
    function ColumnCount: integer;
    {/ the Column name of the current Row
     - Columns numeration (i.e. Col value) starts with 0
     - it's up to the implementation to ensure than all column names are unique }
    function ColumnName(Col: integer): RawUTF8;
    {/ returns the Column index of a given Column name
     - Columns numeration (i.e. Col value) starts with 0
     - returns -1 if the Column name is not found (via case insensitive search) }
    function ColumnIndex(const aColumnName: RawUTF8): integer;
    /// the Column type of the current Row
    // - FieldSize can be set to store the size in chars of a ftUTF8 column
    // (0 means BLOB kind of TEXT column)
    function ColumnType(Col: integer; FieldSize: PInteger=nil): TSQLDBFieldType;
    {/ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(Col: integer): Int64; overload;
    {/ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(Col: integer): double; overload;
    {/ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDateTime(Col: integer): TDateTime; overload;
    {/ return a column date and time value of the current Row, first Col is 0 }
    function ColumnTimeStamp(Col: integer): TTimeLog; overload;
    {/ return a Column currency value of the current Row, first Col is 0 }
    function ColumnCurrency(Col: integer): currency; overload;
    {/ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(Col: integer): RawUTF8; overload;
    {/ return a Column text value as generic VCL string of the current Row, first Col is 0 }
    function ColumnString(Col: integer): string; overload; 
    {/ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlob(Col: integer): RawByteString; overload;
    {/ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlobBytes(Col: integer): TBytes; overload;
    {/ return a Column as a TSQLVar value, first Col is 0
     - the specified Temp variable will be used for temporary storage of
       svtUTF8/svtBlob values }
    procedure ColumnToSQLVar(Col: Integer; var Value: TSQLVar;
      var Temp: RawByteString; DoNotFetchBlob: boolean=false);
    {$ifndef LVCL}
    {/ return a Column as a variant
     - a ftUTF8 TEXT content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob BLOB content will be mapped into a TBlobData AnsiString variant }
    function ColumnVariant(Col: integer): Variant; overload;
    {/ return a Column as a variant, first Col is 0
     - this default implementation will call Column*() method above
     - a ftUTF8 TEXT content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob BLOB content will be mapped into a TBlobData AnsiString variant }
    function ColumnToVariant(Col: integer; var Value: Variant): TSQLDBFieldType; overload;
    {$endif}
    {/ return a special CURSOR Column content as a SynDB result set
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - such columns are mapped as ftNull internally - so this method is the only
       one giving access to the data rows
     - see also BoundCursor() if you want to access a CURSOR out parameter }
    function ColumnCursor(Col: integer): ISQLDBRows; overload;

    {/ return a Column integer value of the current Row, from a supplied column name }
    function ColumnInt(const ColName: RawUTF8): Int64; overload;
    {/ return a Column floating point value of the current Row, from a supplied column name }
    function ColumnDouble(const ColName: RawUTF8): double; overload;
    {/ return a Column floating point value of the current Row, from a supplied column name }
    function ColumnDateTime(const ColName: RawUTF8): TDateTime; overload;
    {/ return a column date and time value of the current Row, from a supplied column name }
    function ColumnTimeStamp(const ColName: RawUTF8): TTimeLog; overload;
    {/ return a Column currency value of the current Row, from a supplied column name }
    function ColumnCurrency(const ColName: RawUTF8): currency; overload;
    {/ return a Column UTF-8 encoded text value of the current Row, from a supplied column name }
    function ColumnUTF8(const ColName: RawUTF8): RawUTF8; overload;
    {/ return a Column text value as generic VCL string of the current Row, from a supplied column name }
    function ColumnString(const ColName: RawUTF8): string; overload; 
    {/ return a Column as a blob value of the current Row, from a supplied column name }
    function ColumnBlob(const ColName: RawUTF8): RawByteString; overload;
    {/ return a Column as a blob value of the current Row, from a supplied column name }
    function ColumnBlobBytes(const ColName: RawUTF8): TBytes; overload;
    {$ifndef LVCL}
    {/ return a Column as a variant, from a supplied column name }
    function ColumnVariant(const ColName: RawUTF8): Variant; overload;
    {/ return a Column as a variant, from a supplied column name
      - since a property getter can't be an overloaded method, we define one
      for the Column[] property }
    function GetColumnVariant(const ColName: RawUTF8): Variant;
    {/ return a special CURSOR Column content as a SynDB result set
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - such columns are mapped as ftNull internally - so this method is the only
       one giving access to the data rows }
    function ColumnCursor(const ColName: RawUTF8): ISQLDBRows; overload;
    {/ return a Column as a variant
      - this default property can be used to write simple code like this:
       ! procedure WriteFamily(const aName: RawUTF8);
       ! var I: ISQLDBRows;
       ! begin
       !   I := MyConnProps.Execute('select * from table where name=?',[aName]);
       !   while I.Step do
       !     writeln(I['FirstName'],' ',DateToStr(I['BirthDate']));
       ! end;
      - of course, using a variant and a column name will be a bit slower than
       direct access via the Column*() dedicated methods, but resulting code
       is fast in practice }
    property Column[const ColName: RawUTF8]: Variant read GetColumnVariant; default;
    {$ifndef DELPHI5OROLDER}
    /// create a TSQLDBRowVariantType able to access any field content via late binding
    // - i.e. you can use Data.Name to access the 'Name' column of the current row
    // - this Variant will point to the corresponding TSQLDBStatement instance,
    // so it's not necessary to retrieve its value for each row
    // - typical use is:
    // ! var Row: Variant;
    // ! (...)
    // !  with MyConnProps.Execute('select * from table where name=?',[aName]) do begin
    // !    Row := RowDaa;
    // !    while Step do
    // !      writeln(Row.FirstName,Row.BirthDate);
    // !  end;
    function RowData: Variant;
    {$endif}
    {$endif}
    /// return the associated statement instance
    function Instance: TSQLDBStatement;
    // return all rows content as a JSON string
    // - JSON data is retrieved with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - you can ignore all BLOB fields, if DoNotFletchBlobs is set to TRUE
    // - you can go back to the first row of data before creating the JSON, if
    // RewindToFirst is TRUE (could be used e.g. for TQuery.FetchAllAsJSON)
    // - if ReturnedRowCount points to an integer variable, it will be filled with
    // the number of row data returned (excluding field names)
    // - similar to corresponding TSQLRequest.Execute method in SynSQLite3 unit
    function FetchAllAsJSON(Expanded: boolean; ReturnedRowCount: PPtrInt=nil;
      DoNotFletchBlobs: boolean=false; RewindToFirst: boolean=false): RawUTF8;
    /// append all rows content as binary stream
    // - will save the column types and name, then every data row in optimized
    // binary format (faster and smaller than JSON)
    // - you can specify a LIMIT for the data extent (default 0 meaning all data)
    // - generates the format expected by TSQLDBProxyStatement
    function FetchAllToBinary(Dest: TStream; MaxRowCount: cardinal=0;
      DataRowPosition: PCardinalDynArray=nil): cardinal;
  end;

  /// generic interface to bind to prepared SQL query
  // - inherits from ISQLDBRows, so gives access to the result columns data
  // - not all TSQLDBStatement methods are available, but only those to bind
  // parameters and retrieve data after execution
  // - reference counting mechanism of this interface will feature statement 
  // cache (if available) for NewThreadSafeStatementPrepared() or PrepareInlined()
  ISQLDBStatement = interface(ISQLDBRows)
  ['{EC27B81C-BD57-47D4-9711-ACFA27B583D7}']
    {/ bind a NULL value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindNull(Param: Integer; IO: TSQLDBParamInOutType=paramIn);
    {/ bind an integer value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: Int64;
      IO: TSQLDBParamInOutType=paramIn); overload;
    {/ bind a double value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: double;
      IO: TSQLDBParamInOutType=paramIn); overload;  
    {/ bind a TDateTime value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindDateTime(Param: Integer; Value: TDateTime;
      IO: TSQLDBParamInOutType=paramIn); overload;  
    {/ bind a currency value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindCurrency(Param: Integer; Value: currency;
      IO: TSQLDBParamInOutType=paramIn); overload; 
    {/ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextU(Param: Integer; const Value: RawUTF8;
      IO: TSQLDBParamInOutType=paramIn); overload;  
    {/ bind a UTF-8 encoded buffer text (#0 ended) to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextP(Param: Integer; Value: PUTF8Char;
      IO: TSQLDBParamInOutType=paramIn); overload;  
    {/ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextS(Param: Integer; const Value: string;
      IO: TSQLDBParamInOutType=paramIn); overload;  
    {/ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextW(Param: Integer; const Value: WideString;
      IO: TSQLDBParamInOutType=paramIn); overload;  
    {/ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; Data: pointer; Size: integer;
      IO: TSQLDBParamInOutType=paramIn); overload;  
    {/ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; const Data: RawByteString;
      IO: TSQLDBParamInOutType=paramIn); overload;
    {/ bind a Variant value to a parameter
     - the leftmost SQL parameter has an index of 1
     - will call all virtual Bind*() methods from the Data type
     - if DataIsBlob is TRUE, will call BindBlob(RawByteString(Data)) instead
       of BindTextW(WideString(Variant)) - used e.g. by TQuery.AsBlob/AsBytes }
    procedure BindVariant(Param: Integer; const Data: Variant; DataIsBlob: boolean;
      IO: TSQLDBParamInOutType=paramIn);
    /// bind one TSQLVar value
    // - the leftmost SQL parameter has an index of 1
    procedure Bind(Param: Integer; const Data: TSQLVar;
      IO: TSQLDBParamInOutType=paramIn); overload;
    /// bind one RawUTF8 encoded value
    // - the leftmost SQL parameter has an index of 1
    // - the value should match the BindArray() format, i.e. be stored as in SQL
    // (i.e. number, 'quoted string', 'YYYY-MM-DD hh:mm:ss', null)
    procedure Bind(Param: Integer; ParamType: TSQLDBFieldType; const Value: RawUTF8;
      ValueAlreadyUnquoted: boolean; IO: TSQLDBParamInOutType=paramIn); overload;
    {/ bind an array of const values
     - parameters marked as ? should be specified as method parameter in Params[]
     - BLOB parameters can be bound with this method, when set after encoding
       via BinToBase64WithMagic() call
     - TDateTime parameters can be bound with this method, when encoded via
       a DateToSQL() or DateTimeToSQL() call }
    procedure Bind(const Params: array of const;
      IO: TSQLDBParamInOutType=paramIn); overload; 
    {/ bind an array of fields from an existing SQL statement
     - can be used e.g. after ColumnsToSQLInsert() method call for fast data
       conversion between tables }
    procedure BindFromRows(const Fields: TSQLDBColumnPropertyDynArray;
      Rows: TSQLDBStatement);
    {/ bind a special CURSOR parameter to be returned as a SynDB result set
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - such parameters are mapped as ftUnknown
     - use BoundCursor() method to retrieve the corresponding ISQLDBRows after
       execution of the statement }
    procedure BindCursor(Param: integer);
    {/ return a special CURSOR parameter content as a SynDB result set
     - this method is not about a column, but a parameter defined with
       BindCursor() before method execution
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - this method allow direct access to the data rows after execution }
    function BoundCursor(Param: Integer): ISQLDBRows;

    /// bind an array of values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. number, 'quoted string',
    // 'YYYY-MM-DD hh:mm:ss', null)
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; ParamType: TSQLDBFieldType;
      const Values: TRawUTF8DynArray; ValuesCount: integer); overload;
    /// bind an array of integer values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; const Values: array of Int64); overload;
    /// bind an array of double values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; const Values: array of double); overload;
    /// bind an array of TDateTime values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. 'YYYY-MM-DD hh:mm:ss')
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArrayDateTime(Param: Integer; const Values: array of TDateTime);
    /// bind an array of currency values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArrayCurrency(Param: Integer; const Values: array of currency);
    /// bind an array of RawUTF8 values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. 'quoted string')
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; const Values: array of RawUTF8); overload;

    {$ifndef LVCL}
    {/ retrieve the parameter content, after SQL execution
     - the leftmost SQL parameter has an index of 1
     - to be used e.g. with stored procedures:
     ! query :=  'BEGIN TEST_PKG.DUMMY(?, ?, ?, ?, ?); END;';
     ! stmt := Props.NewThreadSafeStatementPrepared(query, false);
     ! stmt.Bind(1, in1, paramIn);
     ! stmt.BindTextU(2, in2, paramIn);
     ! stmt.BindTextU(3, in3, paramIn);
     ! stmt.BindTextS(4, '', paramOut); // to be retrieved with out1: string
     ! stmt.Bind(5, 0, paramOut);       // to be retrieved with out2: integer
     ! stmt.ExecutePrepared;
     ! stmt.ParamToVariant(4, out1, true);
     ! stmt.ParamToVariant(5, out2, true);
     - the parameter should have been bound with IO=paramOut or IO=paramInOut
       if CheckIsOutParameter is TRUE }
    function ParamToVariant(Param: Integer; var Value: Variant;
      CheckIsOutParameter: boolean=true): TSQLDBFieldType;
    {$endif}

    {/ execute a prepared SQL statement
     - parameters marked as ? should have been already bound with Bind*() functions
     - should raise an Exception on any error
     - after execution, you can access any returned data via ISQLDBRows methods }
    procedure ExecutePrepared;
    // execute a prepared SQL statement and return all rows content as a JSON string
    // - JSON data is retrieved with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    procedure ExecutePreparedAndFetchAllAsJSON(Expanded: boolean; out JSON: RawUTF8);
    /// gets a number of updates made by latest executed statement
    function UpdateCount: Integer;
  end;

  {$M+} { published properties to be logged as JSON }

{$ifndef DELPHI5OROLDER}
  /// proxy commands implemented by TSQLDBProxyConnectionProperties.Process()
  // - method signature expect "const Input" and "var Output" arguments
  // - Input is not used for cConnect, cDisconnect, cGetForeignKeys,
  // cStartTransaction, cCommit, cRollback and cServerTimeStamp
  // - Input is the TSQLDBProxyConnectionProperties instance for cInitialize
  // - Input is the RawUTF8 table name for most cGet* metadata commands
  // - Input is the SQL statement and associated bound parameters for cExecute,
  // cExecuteToBinary, cExecuteToJSON, and cExecuteToExpandedJSON, encoded as
  // TSQLDBProxyConnectionCommandExecute record
  // - Output is not used for cConnect, cDisconnect, cStartTransaction,
  // cCommit, cRollback and cExecute
  // - Output is TSQLDBDefinition (i.e. DBMS type) for cInitialize
  // - Output is TTimeLog for cServerTimeStamp
  // - Output is TSQLDBColumnDefineDynArray for cGetFields
  // - Output is TSQLDBIndexDefineDynArray for cGetIndexes
  // - Output is TSynNameValue (fForeignKeys) for cGetForeignKeys
  // - Output is TRawUTF8DynArray for cGetTableNames
  // - Output is RawByteString result data for cExecuteToBinary
  // - Output is RawUTF8 result data for cExecuteToJSON and cExecuteToExpandedJSON
  // - calls could be declared as such:
  // ! Process(cInitialize,?,fDBMS: TSQLDBDefinition);
  // ! Process(cConnect,?,?);
  // ! Process(cDisconnect,?,?);
  // ! Process(cStartTransaction,?,?);
  // ! Process(cCommit,?,?);
  // ! Process(cRollback,?,?);
  // ! Process(cServerTimeStamp,?,result: TTimeLog);
  // ! Process(cGetFields,aTableName: RawUTF8,Fields: TSQLDBColumnDefineDynArray);
  // ! Process(cGetIndexes,aTableName: RawUTF8,Indexes: TSQLDBIndexDefineDynArray);
  // ! Process(cGetTableNames,?,Tables: TRawUTF8DynArray);
  // ! Process(cGetForeignKeys,?,fForeignKeys: TSynNameValue);
  // ! Process(cExecute,Request: TSQLDBProxyConnectionCommandExecute,?);
  // ! Process(cExecuteToBinary,Request: TSQLDBProxyConnectionCommandExecute,Data: RawByteString);
  // ! Process(cExecuteToJSON,Request: TSQLDBProxyConnectionCommandExecute,JSON: RawUTF8);
  // ! Process(cExecuteToExpandedJSON,Request: TSQLDBProxyConnectionCommandExecute,JSON: RawUTF8);
  TSQLDBProxyConnectionCommand = (
    cInitialize,
    cConnect, cDisconnect, cStartTransaction, cCommit, cRollback,
    cServerTimeStamp,
    cGetFields, cGetIndexes, cGetTableNames, cGetForeignKeys,
    cExecute, cExecuteToBinary, cExecuteToJSON, cExecuteToExpandedJSON);
{$endif}

  TSQLDBConnection = class;
  TSQLDBConnectionProperties = class;

  /// possible events notified to TOnSQLDBProcess callback method
  // - event handler is specified by TSQLDBConnectionProperties.OnProcess or
  // TSQLDBConnection.OnProcess properties
  // - speNonActive / speActive will be used to notify external DB blocking
  // access, so can be used e.g. to change the mouse cursor shape (this trigger
  // is re-entrant, i.e. it will be executed only once in case of nested calls)
  // - speReconnected will be called if TSQLDBConnection did successfully
  // recover its database connection (on error, TQuery will call speConnectionLost)
  // - speConnectionLost will be called by TQuery in case of broken connection,
  // and if Disconnect/Reconnect did not restore it as expected (i.e. speReconnected)
  TOnSQLDBProcessEvent = (
    speNonActive, speActive,
    speConnectionLost, speReconnected);

  /// event handler called during all external DB process
  // - event handler is specified by TSQLDBConnectionProperties.OnProcess or
  // TSQLDBConnection.OnProperties properties
  TOnSQLDBProcess = procedure(Sender: TSQLDBConnection; Event: TOnSQLDBProcessEvent) of object;

  /// defines a callback signature able to handle multiple INSERT
  // - may execute e.g. for 2 fields and 3 data rows on a database engine
  // implementing INSERT with multiple VALUES (like MySQL, PostgreSQL, NexusDB,
  // MSSQL or SQlite3), as implemented by
  // TSQLDBConnectionProperties.MultipleValuesInsert() :
  // $ INSERT INTO TableName(FieldNames[0],FieldNames[1]) VALUES
  // $   (FieldValues[0][0],FieldValues[1][0]),
  // $   (FieldValues[0][1],FieldValues[1][1]),
  // $   (FieldValues[0][2],FieldValues[1][2]);
  // - for other kind of DB which do not support multi values INSERT, may
  // execute a dedicated driver command, like MSSQL "bulk insert" or Firebird
  // "execute block"
  TOnBatchInsert = procedure(Props: TSQLDBConnectionProperties;
    const TableName: RawUTF8; const FieldNames: TRawUTF8DynArray;
    const FieldTypes: TSQLDBFieldTypeArray; RowCount: integer;
    const FieldValues: TRawUTF8DynArrayDynArray) of object;

  /// bit set to identify columns, e.g. null columns
  TSQLDBProxyStatementColumns = set of 0..255;

  /// pointer to a bit set to identify columns, e.g. null columns
  PSQLDBProxyStatementColumns = ^TSQLDBProxyStatementColumns;

  /// abstract class used to set Database-related properties
  // - handle e.g. the Database server location and connection parameters (like
  // UserID and password)
  // - should also provide some Database-specific generic SQL statement creation
  // (e.g. how to create a Table), to be used e.g. by the mORMot layer
  TSQLDBConnectionProperties = class
  protected
    fServerName: RawUTF8;
    fDatabaseName: RawUTF8;
    fPassWord: RawUTF8;
    fUserID: RawUTF8;
    fForcedSchemaName: RawUTF8;
    fMainConnection: TSQLDBConnection;
    fBatchSendingAbilities: TSQLDBStatementCRUDs;
    fBatchMaxSentAtOnce: integer;
    fOnBatchInsert: TOnBatchInsert;
    {$ifndef UNICODE}
    fVariantWideString: boolean;
    {$endif}
    fUseCache: boolean;
    fRollbackOnDisconnect: boolean;
    fStoreVoidStringAsNull: boolean;
    fForeignKeys: TSynNameValue;
    fSQLCreateField: TSQLDBFieldTypeDefinition;
    fSQLCreateFieldMax: PtrUInt;
    fSQLGetServerTimeStamp: RawUTF8;
    fEngineName: RawUTF8;
    fDBMS: TSQLDBDefinition;
    fOnProcess: TOnSQLDBProcess;
    // this default implementation just returns the fDBMS value or dDefault
    // (never returns dUnknwown)
    function GetDBMS: TSQLDBDefinition; virtual;
    function GetForeignKeysData: RawByteString;
    procedure SetForeignKeysData(const Value: RawByteString);
    function FieldsFromList(const aFields: TSQLDBColumnDefineDynArray; aExcludeTypes: TSQLDBFieldTypes): RawUTF8;
    function GetMainConnection: TSQLDBConnection; virtual;
    /// will be called at the end of constructor
    // - this default implementation will do nothing
    procedure SetInternalProperties; virtual;
    /// SQL statement to get all field/column names for a specified Table
    // - used by GetFieldDefinitions public method
    // - should return a SQL "SELECT" statement with the field names as first
    // column, a textual field type as 2nd column, then field length, then
    // numeric precision and scale as 3rd, 4th and 5th columns, and the index
    // count in 6th column
    // - this default implementation just returns nothing
    // - if this method is overridden, the ColumnTypeNativeToDB() method should
    // also be overridden in order to allow conversion from native column
    // type into the corresponding TSQLDBFieldType
    function SQLGetField(const aTableName: RawUTF8): RawUTF8; virtual;
    /// SQL statement to get advanced information about all indexes for a Table
    // - should return a SQL "SELECT" statement with the index names as first
    function SQLGetIndex(const aTableName: RawUTF8): RawUTF8; virtual;
    /// SQL statement to get all table names
    // - used by GetTableNames public method
    // - should return a SQL "SELECT" statement with the table names as
    // first column (any other columns will be ignored)
    // - this default implementation just returns nothing
    function SQLGetTableNames: RawUTF8; virtual;
    /// should initialize fForeignKeys content with all foreign keys of this
    // database
    // - used by GetForeignKey method
    procedure GetForeignKeys; virtual; abstract;
    /// will use fSQLCreateField[Max] to create the SQL column definition
    // - this default virtual implementation will handle properly all supported
    // database engines, assuming aField.ColumnType=ftUnknown for ID
    function SQLFieldCreate(const aField: TSQLDBColumnProperty): RawUTF8; virtual;
    /// wrapper around GetIndexes() + set Fields[].ColumnIndexed in consequence
    // - used by some overridden versions of GetFields() method
    procedure GetIndexesAndSetFieldsColumnIndexed(const aTableName: RawUTF8;
      var Fields: TSQLDBColumnDefineDynArray);
    /// check if the exception or its error message is about DB connection error
    // - will be used by TSQLDBConnection.LastErrorWasAboutConnection method
    // - default method will check for the 'conne' sub-string in the message text
    // - should be overridden depending on the error message returned by the DB
    function ExceptionIsAboutConnection(aClass: ExceptClass; const aMessage: RawUTF8): boolean; virtual;
{$ifndef DELPHI5OROLDER}
    /// unique access point from remote TSQLDBProxyConnectionProperties accesses
    // - ready to process TSQLDBProxyConnectionProperties.Process() commands:
    // to be executed e.g. in a background thread, or via a remote (HTTP) link
    // - made virtual to add custom behavior on need for a specific connection
    procedure RemoteProcessExec(Command: TSQLDBProxyConnectionCommand;
      const Input; var Output); virtual;
{$endif}
    /// generic method able to implement OnBatchInsert() with parameters
    // - for MySQL, PostgreSQL, MSSQL2008, NexusDB or SQlite3, will execute
    // (with parameters) the extended standard syntax:
    // $ INSERT INTO TableName(FieldNames[0],FieldNames[1]) VALUES
    // $   (FieldValues[0][0],FieldValues[1][0]),
    // $   (FieldValues[0][1],FieldValues[1][1]),
    // $   (FieldValues[0][2],FieldValues[1][2]);
    // - for Firebird, will run the corresponding EXECUTE BLOCK() statement
    // with parameters - but Firebird sounds slower than without any parameter
    // (as tested with ZDBC/ZEOS or UniDAC)
    // - for Oracle, will run (with parameters for values):
    // $ INSERT ALL
    // $  INTO TableName(FieldNames[0],FieldNames[1]) VALUES (?,?)
    // $  INTO TableName(FieldNames[0],FieldNames[1]) VALUES (?,?)
    // $  INTO TableName(FieldNames[0],FieldNames[1]) VALUES (?,?)
    // $ SELECT 1 FROM DUAL;
    procedure MultipleValuesInsert(Props: TSQLDBConnectionProperties;
      const TableName: RawUTF8; const FieldNames: TRawUTF8DynArray;
      const FieldTypes: TSQLDBFieldTypeArray; RowCount: integer;
      const FieldValues: TRawUTF8DynArrayDynArray);
    /// Firebird-dedicated method able to implement OnBatchInsert()
    // - will run an EXECUTE BLOCK statement without any parameters, but
    // including inlined values - sounds to be faster on ZEOS/ZDBC!
    procedure MultipleValuesInsertFirebird(Props: TSQLDBConnectionProperties;
      const TableName: RawUTF8; const FieldNames: TRawUTF8DynArray;
      const FieldTypes: TSQLDBFieldTypeArray; RowCount: integer;
      const FieldValues: TRawUTF8DynArrayDynArray);
  public
    /// initialize the properties
    // - children may optionaly handle the fact that no UserID or Password
    // is supplied here, by displaying a corresponding Dialog box
    constructor Create(const aServerName, aDatabaseName, aUserID, aPassWord: RawUTF8); virtual;
    /// release related memory, and close MainConnection
    destructor Destroy; override;
    /// create a new connection
    // - call this method if the shared MainConnection is not enough (e.g. for
    // multi-thread access)
    // - the caller is responsible of freeing this instance
    function NewConnection: TSQLDBConnection; virtual; abstract;
    /// get a thread-safe connection
    // - this default implementation will return the MainConnection shared
    // instance, so the provider should be thread-safe by itself
    // - TSQLDBConnectionPropertiesThreadSafe will implement a per-thread
    // connection pool, via an internal TSQLDBConnection pool, per thread
    // if necessary (e.g. for OleDB, which expect one TOleDBConnection instance
    // per thread)
    function ThreadSafeConnection: TSQLDBConnection; virtual;
    /// release all existing connections
    // - can be called e.g. after a DB connection problem, to purge the
    // connection pool, and allow automatic reconnection
    procedure ClearConnectionPool; virtual;
    /// create a new thread-safe statement
    // - this method will call ThreadSafeConnection.NewStatement
    function NewThreadSafeStatement: TSQLDBStatement;
    /// create a new thread-safe statement from an internal cache (if any)
    // - will call ThreadSafeConnection.NewStatementPrepared
    // - this method should return a prepared statement instance on success
    // - on error, returns nil and you can check Connnection.LastErrorMessage /
    // Connection.LastErrorException to retrieve corresponding error information
    // (if RaiseExceptionOnError is left to default FALSE value, otherwise, it will
    // raise an exception) 
    function NewThreadSafeStatementPrepared(const aSQL: RawUTF8;
       ExpectResults: Boolean; RaiseExceptionOnError: Boolean=false): ISQLDBStatement; overload;
    /// create a new thread-safe statement from an internal cache (if any)
    // - this method will call the overloaded NewThreadSafeStatementPrepared method
    // - here Args[] array does not refer to bound parameters, but to values
    // to be changed within SQLFormat in place of '%' characters (this method
    // will call FormatUTF8() internaly); parameters will be bound directly
    // on the returned TSQLDBStatement instance
    // - this method should return a prepared statement instance on success
    // - on error, returns nil and you can check Connnection.LastErrorMessage /
    // Connection.LastErrorException to retrieve correspnding error information
    function NewThreadSafeStatementPrepared(SQLFormat: PUTF8Char;
      const Args: array of const; ExpectResults: Boolean): ISQLDBStatement; overload;
    /// create, prepare and bound inlined parameters to a thread-safe statement
    // - this implementation will call the NewThreadSafeStatement virtual method,
    // then bound inlined parameters as :(1234): and call its Execute method
    // - raise an exception on error
    function PrepareInlined(const aSQL: RawUTF8; ExpectResults: Boolean): ISQLDBStatement; overload;
    /// create, prepare and bound inlined parameters to a thread-safe statement
    // - overloaded method using FormatUTF8() and inlined parameters
    function PrepareInlined(SQLFormat: PUTF8Char; const Args: array of const; ExpectResults: Boolean): ISQLDBStatement; overload;
    /// execute a SQL query, returning a statement interface instance to retrieve
    // the result rows
    // - will call NewThreadSafeStatement method to retrieve a thread-safe
    // statement instance, then run the corresponding Execute() method
    // - raise an exception on error
    // - returns an ISQLDBRows to access any resulting rows (if ExpectResults is
    // TRUE), and provide basic garbage collection, as such:
    // ! procedure WriteFamily(const aName: RawUTF8);
    // ! var I: ISQLDBRows;
    // ! begin
    // !   I := MyConnProps.Execute('select * from table where name=?',[aName]);
    // !   while I.Step do
    // !     writeln(I['FirstName'],' ',DateToStr(I['BirthDate']));
    // ! end;
    // - if RowsVariant is set, you can use it to row column access via late
    // binding, as such:
    // ! procedure WriteFamily(const aName: RawUTF8);
    // ! var R: Variant;
    // ! begin
    // !   with MyConnProps.Execute('select * from table where name=?',[aName],@R) do
    // !   while Step do
    // !     writeln(R.FirstName,' ',DateToStr(R.BirthDate));
    // ! end;
    function Execute(const aSQL: RawUTF8; const Params: array of const
      {$ifndef LVCL}{$ifndef DELPHI5OROLDER}; RowsVariant: PVariant=nil{$endif}{$endif}): ISQLDBRows;
    /// execute a SQL query, without returning any rows
    // - can be used to launch INSERT, DELETE or UPDATE statement, e.g.
    // - will call NewThreadSafeStatement method to retrieve a thread-safe
    // statement instance, then run the corresponding Execute() method
    // - return the number of modified rows (or 0 if the DB driver do not
    // give access to this value)
    function ExecuteNoResult(const aSQL: RawUTF8; const Params: array of const): integer;
    /// create, prepare, bound inlined parameters and execute a thread-safe statement
    // - this implementation will call the NewThreadSafeStatement virtual method,
    // then bound inlined parameters as :(1234): and call its Execute method
    // - raise an exception on error
    function ExecuteInlined(const aSQL: RawUTF8; ExpectResults: Boolean): ISQLDBRows; overload;
    /// create, prepare, bound inlined parameters and execute a thread-safe statement
    // - overloaded method using FormatUTF8() and inlined parameters
    function ExecuteInlined(SQLFormat: PUTF8Char; const Args: array of const; ExpectResults: Boolean): ISQLDBRows; overload;

    /// convert a textual column data type, as retrieved e.g. from SQLGetField,
    // into our internal primitive types
    // - default implementation will always return ftUTF8
    function ColumnTypeNativeToDB(const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType; virtual;
    /// returns the SQL statement used to create a Table
    // - should return the SQL "CREATE" statement needed to create a table with
    // the specified field/column names and types
    // - if aAddID is TRUE, "ID Int64 PRIMARY KEY" column is added as first,
    // and will expect the ORM to create an unique RowID value sent at INSERT
    // (could use "select max(ID) from table" to retrieve the last value) -
    // note that 'ID' is used instead of 'RowID' since it fails on Oracle e.g.
    // - this default implementation will use internal fSQLCreateField and
    // fSQLCreateFieldMax protected values, which contains by default the
    // ANSI SQL Data Types and maximum 1000 inlined WideChars: inherited classes
    // may change the default fSQLCreateField* content or override this method
    function SQLCreate(const aTableName: RawUTF8;
      const aFields: TSQLDBColumnPropertyDynArray; aAddID: boolean): RawUTF8; virtual;
    /// returns the SQL statement used to add a column to a Table
    // - should return the SQL "ALTER TABLE" statement needed to add a column to
    // an existing table
    // - this default implementation will use internal fSQLCreateField and
    // fSQLCreateFieldMax protected values, which contains by default the
    // ANSI SQL Data Types and maximum 1000 inlined WideChars: inherited classes
    // may change the default fSQLCreateField* content or override this method
    function SQLAddColumn(const aTableName: RawUTF8;
      const aField: TSQLDBColumnProperty): RawUTF8; virtual;
    /// returns the SQL statement used to add an index to a Table
    // - should return the SQL "CREATE INDEX" statement needed to add an index
    // to the specified column names of an existing table
    // - index will expect UNIQUE values in the specified columns, if Unique
    // parameter is set to true
    // - this default implementation will return the standard SQL statement, i.e.
    // 'CREATE [UNIQUE] INDEX index_name ON table_name (column_name[s])'
    function SQLAddIndex(const aTableName: RawUTF8;
      const aFieldNames: array of RawUTF8; aUnique: boolean;
      aDescending: boolean=false;
      const aIndexName: RawUTF8=''): RawUTF8; virtual;
    /// used to compute a SELECT statement for the given fields
    // - should return the SQL "SELECT ... FROM ..." statement to retrieve
    // the specified column names of an existing table
    // - by default, all columns specified in aFields[] will be available:
    // it will return "SELECT * FROM TableName"
    // - but if you specify a value in aExcludeTypes, it will compute the
    // matching column names to ignore those kind of content (e.g. [stBlob] to
    // save time and space)
    function SQLSelectAll(const aTableName: RawUTF8;
      const aFields: TSQLDBColumnDefineDynArray; aExcludeTypes: TSQLDBFieldTypes): RawUTF8; virtual;
    /// SQL statement to create the corresponding database
    // - this default implementation will only handle dFirebird by now
    function SQLCreateDatabase(const aDatabaseName: RawUTF8;
      aDefaultPageSize: integer=0): RawUTF8; virtual;
    /// convert an ISO-8601 encoded time and date into a date appropriate to
    // be pasted in the SQL request
    // - this default implementation will return the quoted ISO-8601 value, i.e.
    // 'YYYY-MM-DDTHH:MM:SS' (as expected by Microsoft SQL server e.g.)
    // - returns  to_date('....','YYYY-MM-DD HH24:MI:SS')  for Oracle
    function SQLIso8601ToDate(const Iso8601: RawUTF8): RawUTF8; virtual;
    /// split a table name to its OWNER.TABLE full name (if applying)
    // - will use ForcedSchemaName property (if applying), or the OWNER. already
    // available within the supplied table name
    procedure SQLSplitTableName(const aTableName: RawUTF8; out Owner, Table: RawUTF8); virtual;
    /// return the fully qualified SQL table name
    // - will use ForcedSchemaName property (if applying), or return aTableName
    // - you can override this method to force the expected format
    function SQLFullTableName(const aTableName: RawUTF8): RawUTF8; virtual;
    /// return a SQL table name with quotes if necessary
    // - can be used e.g. with SELECT statements
    // - you can override this method to force the expected format
    function SQLTableName(const aTableName: RawUTF8): RawUTF8; virtual;

    /// retrieve the column/field layout of a specified table
    // - this default implementation will use protected SQLGetField virtual
    // method to retrieve the field names and properties
    // - used e.g. by GetFieldDefinitions
    // - will call ColumnTypeNativeToDB protected virtual method to guess the
    // each mORMot TSQLDBFieldType
    procedure GetFields(const aTableName: RawUTF8; var Fields: TSQLDBColumnDefineDynArray); virtual;
    /// retrieve the advanced indexed information of a specified Table
    //  - this default implementation will use protected SQLGetIndex virtual
    // method to retrieve the index names and properties
    // - currently only MS SQL and Oracle are supported
    procedure GetIndexes(const aTableName: RawUTF8; var Indexes: TSQLDBIndexDefineDynArray); virtual;
    /// get all field/column definition for a specified Table as text
    // - call the GetFields method and retrieve the column field name and
    // type as 'Name [Type Length Precision Scale]'
    // - if WithForeignKeys is set, will add external foreign keys as '% tablename'
    procedure GetFieldDefinitions(const aTableName: RawUTF8;
      var Fields: TRawUTF8DynArray; WithForeignKeys: boolean);
    /// get one field/column definition as text
    // - return column type as 'Name [Type Length Precision Scale]'
    class function GetFieldDefinition(const Column: TSQLDBColumnDefine): RawUTF8;
    /// get one field/column definition as text, targeting a TSQLRecord 
    // published property
    // - return e.g. property type information as:
    // ! 'Name: RawUTF8 read fName write fName index 20;';
    class function GetFieldORMDefinition(const Column: TSQLDBColumnDefine): RawUTF8;
    /// get all table names
    // - this default implementation will use protected SQLGetTableNames virtual
    // method to retrieve the table names
    procedure GetTableNames(var Tables: TRawUTF8DynArray); virtual;
    /// retrieve a foreign key for a specified table and column
    // - first time it is called, it will retrieve all foreign keys from the
    // remote database using virtual protected GetForeignKeys method into
    // the protected fForeignKeys list: this may be slow, depending on the
    // database access (more than 10 seconds waiting is possible)
    // - any further call will use this internal list, so response will be
    // immediate
    // - the whole foreign key list is shared by all connections
    function GetForeignKey(const aTableName, aColumnName: RawUTF8): RawUTF8; 

    /// adapt the LIMIT # clause in the SQL SELECT statement to a syntax
    // matching the underlying DBMS
    // - e.g. TSQLRestStorageExternal.AdaptSQLForEngineList() calls this
    // to let TSQLRestServer.URI by-pass virtual table mechanism
    // - integer parameters state how the SQL statement has been analysed
    function AdaptSQLLimitForEngineList(var SQL: RawUTF8;
      LimitRowCount, AfterSelectPos, WhereClausePos, LimitPos: integer): boolean; virtual;
    /// determine if the SQL statement can be cached
    // - used by TSQLDBConnection.NewStatementPrepared() for handling cache
    function IsCachable(P: PUTF8Char): boolean; virtual;
    /// return the database engine name, as computed from the class name
    // - 'TSQLDBConnectionProperties' will be trimmed left side of the class name
    class function EngineName: RawUTF8;

    /// return a shared connection, corresponding to the given database
    // - call the ThreadSafeConnection method instead e.g. for multi-thread
    // access, or NewThreadSafeStatement for direct retrieval of a new statement
    property MainConnection: TSQLDBConnection read GetMainConnection;
    /// the associated User Identifier, as specified at creation
    property UserID: RawUTF8 read fUserID;
    /// the associated User Password, as specified at creation
    property PassWord: RawUTF8 read fPassWord;
    /// can be used to store the fForeignKeys[] data in an external BLOB
    // - since GetForeignKeys is somewhat slow, could save a lot of time
    property ForeignKeysData: RawByteString read GetForeignKeysData write SetForeignKeysData;
    /// an optional Schema name to be used for SQLGetField() instead of UserID
    // - by default, UserID will be used as schema name, if none is specified
    // (i.e. if table name is not set as SCHEMA.TABLE)
    // - depending on the DBMS identified, the class may also set automatically
    // the default 'dbo' for MS SQL or 'public' for PostgreSQL
    // - you can set a custom schema to be used instead
    property ForcedSchemaName: RawUTF8 read fForcedSchemaName write fForcedSchemaName;
    /// TRUE if an internal cache of SQL statement should be used
    // - cache will be accessed for NewStatementPrepared() method only, by
    // returning ISQLDBStatement interface instances
    // - default value is TRUE for faster process (e.g. TTestSQLite3ExternalDB
    // regression tests will be two times faster with statement caching)
    // - will cache only statements containing ? parameters or a SELECT with no
    // WHERE clause within
    property UseCache: boolean read fUseCache;
    /// defines if TSQLDBConnection.Disconnect shall Rollback any pending
    // transaction
    // - some engines executes a COMMIT when the client is disconnected, others
    // do raise an exception: this parameter ensures that any pending transaction
    // is roll-backed before disconnection
    // - is set to TRUE by default
    property RollbackOnDisconnect: Boolean read fRollbackOnDisconnect write fRollbackOnDisconnect;
    /// defines if '' string values are to be stored as SQL null
    // - by default, '' will be stored as ''
    // - but some DB engines (e.g. Jet or MS SQL) does not allow by default to
    // store '' values, but expect NULL to be stored instead
    property StoreVoidStringAsNull: Boolean read fStoreVoidStringAsNull write fStoreVoidStringAsNull;
    /// this event handler will be called during all process
    // - can be used e.g. to change the desktop cursor
    // - you can override this property directly in the TSQLDBConnection
    property OnProcess: TOnSQLDBProcess read fOnProcess write fOnProcess;
  published { to be logged as JSON - no UserID nor Password for security :) }
    /// return the database engine name, as computed from the class name
    // - 'TSQLDBConnectionProperties' will be trimmed left side of the class name
    property Engine: RawUTF8 read fEngineName;
    /// the associated server name, as specified at creation
    property ServerName: RawUTF8 read fServerName;
    /// the associated database name, as specified at creation
    property DatabaseName: RawUTF8 read fDatabaseName;
    /// the remote DBMS type, as stated by the inheriting class itself, or
    //  retrieved at connecton time (e.g. for ODBC)
    property DBMS: TSQLDBDefinition read GetDBMS;
    /// the abilities of the database for batch sending
    // - e.g. Oracle will handle array DML binds, or MS SQL bulk insert
    property BatchSendingAbilities: TSQLDBStatementCRUDs read fBatchSendingAbilities;
    /// the maximum number of rows to be transmitted at once for batch sending
    // - e.g. Oracle handles array DML operation with iters <= 32767 at best
    // - if OnBatchInsert points to MultipleValuesInsert(), this value is
    // ignored, and the maximum number of parameters is guessed per DBMS type
    property BatchMaxSentAtOnce: integer read fBatchMaxSentAtOnce write fBatchMaxSentAtOnce;
    /// you can define a callback method able to handle multiple INSERT
    // - may execute e.g. INSERT with multiple VALUES (like MySQL, MSSQL, NexusDB,
    // PostgreSQL or SQlite3), as defined by MultipleValuesInsert() callback
    property OnBatchInsert: TOnBatchInsert read fOnBatchInsert write fOnBatchInsert;
    {$ifndef UNICODE}
    /// set to true to force all variant conversion to WideString instead of
    // the default faster AnsiString, for pre-Unicode version of Delphi
    // - by default, the conversion to Variant will create an AnsiString kind
    // of variant: for pre-Unicode Delphi, avoiding WideString/OleStr content
    // will speed up the process a lot, if you are sure that the current
    // charset matches the expected one (which is very likely)
    // - set this property to TRUE so that the conversion to Variant will
    // create a WideString kind of variant, to avoid any character data loss:
    // the access to the property will be slower, but you won't have any
    // potential data loss
    // - starting with Delphi 2009, the TEXT content will be stored as an
    // UnicodeString in the variant, so this property is not necessary
    // - the Variant conversion is mostly used for the TQuery wrapper, or for
    // the ISQLDBRows.Column[] property or ISQLDBRows.ColumnVariant() method;
    // this won't affect other Column*() methods, or JSON production
    property VariantStringAsWideString: boolean read fVariantWideString write fVariantWideString;
    {$endif}
  end;
  {$M-}

  /// specify the class of TSQLDBConnectionProperties
  // - sometimes used to create connection properties instances, from a set
  // of available classes (see e.g. SynDBExplorer or sample 16)
  TSQLDBConnectionPropertiesClass = class of TSQLDBConnectionProperties;

  /// abstract connection created from TSQLDBConnectionProperties
  // - more than one TSQLDBConnection instance can be run for the same
  // TSQLDBConnectionProperties
  TSQLDBConnection = class
  protected
    fProperties: TSQLDBConnectionProperties;
    fErrorException: ExceptClass;
    fErrorMessage: RawUTF8;
    fTransactionCount: integer;
    fServerTimeStampOffset: TDateTime;
    fCache: TRawUTF8ListHashed;
    fOnProcess: TOnSQLDBProcess;
    fTotalConnectionCount: integer;
    fInternalProcessActive: integer;
    fRollbackOnDisconnect: Boolean;
    function GetInTransaction: boolean; virtual;
    function GetServerTimeStamp: TTimeLog; virtual;
    function GetLastErrorWasAboutConnection: boolean; 
    /// raise an exception
    procedure CheckConnection;
    /// call OnProcess() call back event, if needed
    procedure InternalProcess(Event: TOnSQLDBProcessEvent);
  public
    /// connect to a specified database engine
    constructor Create(aProperties: TSQLDBConnectionProperties); virtual;
    /// release memory and connection
    destructor Destroy; override;

    /// connect to the specified database
    // - should raise an Exception on error
    // - this default implementation will notify OnProgress callback for
    // sucessfull re-connection: it should be called in overridden methods
    // AFTER actual connection process
    procedure Connect; virtual;
    /// stop connection to the specified database
    // - should raise an Exception on error
    // - this default implementation will release all cached statements: so it
    // should be called in overridden methods BEFORE actual disconnection
    procedure Disconnect; virtual;
    /// return TRUE if Connect has been already successfully called
    function IsConnected: boolean; virtual; abstract;
    /// initialize a new SQL query statement for the given connection
    // - the caller should free the instance after use
    function NewStatement: TSQLDBStatement; virtual; abstract;
    /// initialize a new SQL query statement for the given connection
    // - this default implementation will call the NewStatement method, and
    // implement handle statement caching is UseCache=true - in this case,
    // the TSQLDBStatement.Reset method shall have been overridden to allow
    // binding and execution of the very same prepared statement
    // - this method should return a prepared statement instance on success
    // - on error, if RaiseExceptionOnError=false (by default), it returns nil
    // and you can check LastErrorMessage and LastErrorException properties to
    // retrieve correspnding error information
    // - on error, if RaiseExceptionOnError=true, an exception is raised
    function NewStatementPrepared(const aSQL: RawUTF8;
      ExpectResults: Boolean; RaiseExceptionOnError: Boolean=false): ISQLDBStatement; virtual;
    /// begin a Transaction for this connection
    // - this default implementation will check and set TransactionCount
    procedure StartTransaction; virtual;
    /// commit changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    // - this default implementation will check and set TransactionCount
    procedure Commit; virtual;
    /// discard changes of a Transaction for this connection
    // - StartTransaction method must have been called before
    // - this default implementation will check and set TransactionCount
    procedure Rollback; virtual;

    /// direct export of a DB statement rows into a new table of this database
    // - the corresponding table will be created within the current connection,
    // if it does not exist
    // - INSERTs will be nested within a transaction if WithinTransaction is TRUE
    // - will raise an Exception in case of error
    function NewTableFromRows(const TableName: RawUTF8;
      Rows: TSQLDBStatement; WithinTransaction: boolean): integer;

    /// number of nested StartTransaction calls
    // - equals 0 if no transaction is active
    property TransactionCount: integer read fTransactionCount;
    /// TRUE if StartTransaction has been called
    // - check if TransactionCount>0
    property InTransaction: boolean read GetInTransaction;
    /// the current Date and Time, as retrieved from the server
    // - this property will return the timestamp in TTimeLog / TTimeLogBits /
    // Int64 value after correction from the Server returned time-stamp (if any)
    // - default implementation will return the executable time, i.e. TimeLogNow
    property ServerTimeStamp: TTimeLog read GetServerTimeStamp;
    /// this event handler will be called during all process
    // - can be used e.g. to change the desktop cursor
    // - by default, will follow TSQLDBConnectionProperties.OnProcess property
    property OnProcess: TOnSQLDBProcess read fOnProcess write fOnProcess;
    /// defines if Disconnect shall Rollback any pending transaction
    // - some engines executes a COMMIT when the client is disconnected, others
    // do raise an exception: this parameter ensures that any pending transaction
    // is roll-backed before disconnection
    // - is set to TRUE by default
    property RollbackOnDisconnect: Boolean
      read fRollbackOnDisconnect write fRollbackOnDisconnect;
    /// TRUE if last error is a broken connection, e.g. during execution of
    // NewStatementPrepared
    // - i.e. LastErrorException/LastErrorMessage concerns the database connection
    // - will use TSQLDBConnectionProperties.ExceptionIsAboutConnection virtual method
    property LastErrorWasAboutConnection: boolean read GetLastErrorWasAboutConnection;
  published { to be logged as JSON }
    /// the associated database properties
    property Properties: TSQLDBConnectionProperties read fProperties;
    /// returns TRUE if the connection was set
    property Connected: boolean read IsConnected;
    /// number of sucessfull connections for this instance
    // - can be greater than 1 in case of re-connection via Disconnect/Connect 
    property TotalConnectionCount: integer read fTotalConnectionCount;
    /// some error message, e.g. during execution of NewStatementPrepared
    property LastErrorMessage: RawUTF8 read fErrorMessage;
    /// some error exception, e.g. during execution of NewStatementPrepared
    property LastErrorException: ExceptClass read fErrorException;
  end;

  /// generic abstract class to implement a prepared SQL query
  // - inherited classes should implement the DB-specific connection in its
  // overridden methods, especially Bind*(), Prepare(), ExecutePrepared, Step()
  // and Column*() methods
  TSQLDBStatement = class(TInterfacedObject, ISQLDBRows, ISQLDBStatement)
  protected
    fConnection: TSQLDBConnection;
    fSQL: RawUTF8;
    fExpectResults: boolean;
    fParamCount: integer;
    fColumnCount: integer;
    fTotalRowsRetrieved: Integer;
    fCurrentRow: Integer;
    fStatementClassName: string;
    fSQLWithInlinedParams: RawUTF8;
    function GetSQLWithInlinedParams: RawUTF8;
    /// raise an exception if Col is out of range according to fColumnCount
    procedure CheckCol(Col: integer); {$ifdef HASINLINE}inline;{$endif}
    {/ will set a Int64/Double/Currency/TDateTime/RawUTF8/TBlobData Dest variable
      from a given column value
     - internal conversion will use a temporary Variant and ColumnToVariant method
     - expects Dest to be of the exact type (e.g. Int64, not Integer) }
    function ColumnToTypedValue(Col: integer; DestType: TSQLDBFieldType; var Dest): TSQLDBFieldType;
    {/ retrieve the inlined value of a given parameter, e.g. 1 or 'name'
    - use ParamToVariant() virtual method
    - optional MaxCharCount will truncate the text to a given number of chars }
    function GetParamValueAsText(Param: integer; MaxCharCount: integer=4096): RawUTF8; virtual;
    /// append the inlined value of a given parameter
    // - use GetParamValueAsText() method
    procedure AddParamValueAsText(Param: integer; Dest: TTextWriter); virtual;
    {$ifndef LVCL}
    {/ return a Column as a variant }
    function GetColumnVariant(const ColName: RawUTF8): Variant;
    {$endif}
    /// return the associated statement instance for a ISQLDBRows interface
    function Instance: TSQLDBStatement;
  public
    {/ create a statement instance }
    constructor Create(aConnection: TSQLDBConnection); virtual;

    {/ bind a NULL value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindNull(Param: Integer; IO: TSQLDBParamInOutType=paramIn); virtual; abstract;
    {/ bind an integer value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: Int64;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a double value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure Bind(Param: Integer; Value: double;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a TDateTime value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindDateTime(Param: Integer; Value: TDateTime;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a currency value to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindCurrency(Param: Integer; Value: currency;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextU(Param: Integer; const Value: RawUTF8;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a UTF-8 encoded buffer text (#0 ended) to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextP(Param: Integer; Value: PUTF8Char;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextS(Param: Integer; const Value: string;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextW(Param: Integer; const Value: WideString;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; Data: pointer; Size: integer;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindBlob(Param: Integer; const Data: RawByteString;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual; abstract;
    {/ bind a Variant value to a parameter
     - the leftmost SQL parameter has an index of 1
     - will call all virtual Bind*() methods from the Data type
     - if DataIsBlob is TRUE, will call BindBlob(RawByteString(Data)) instead
       of BindTextW(WideString(Variant)) - used e.g. by TQuery.AsBlob/AsBytes }
    procedure BindVariant(Param: Integer; const Data: Variant; DataIsBlob: boolean;
      IO: TSQLDBParamInOutType=paramIn); virtual;
    /// bind one TSQLVar value
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will call corresponding Bind*() method
    procedure Bind(Param: Integer; const Data: TSQLVar;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual;
    /// bind one RawUTF8 encoded value
    // - the leftmost SQL parameter has an index of 1
    // - the value should match the BindArray() format, i.e. be stored as in SQL
    // (i.e. number, 'quoted string', 'YYYY-MM-DD hh:mm:ss', null) - e.g. as
    // computed by TJSONObjectDecoder.Decode()
    procedure Bind(Param: Integer; ParamType: TSQLDBFieldType; const Value: RawUTF8;
      ValueAlreadyUnquoted: boolean; IO: TSQLDBParamInOutType=paramIn); overload; virtual;
    {/ bind an array of const values
     - parameters marked as ? should be specified as method parameter in Params[]
     - BLOB parameters can be bound with this method, when set after encoding
       via BinToBase64WithMagic() call
     - TDateTime parameters can be bound with this method, when encoded via
       a DateToSQL() or DateTimeToSQL() call
     - this default implementation will call corresponding Bind*() method }
    procedure Bind(const Params: array of const;
      IO: TSQLDBParamInOutType=paramIn); overload; virtual;
    {/ bind an array of fields from an existing SQL statement
     - can be used e.g. after ColumnsToSQLInsert() method call for fast data
       conversion between tables }
    procedure BindFromRows(const Fields: TSQLDBColumnPropertyDynArray;
      Rows: TSQLDBStatement);
    {/ bind a special CURSOR parameter to be returned as a SynDB result set
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - such parameters are mapped as ftUnknown
     - use BoundCursor() method to retrieve the corresponding ISQLDBRows after
       execution of the statement
     - this default method will raise an exception about unexpected behavior }
    procedure BindCursor(Param: integer); virtual;
    {/ return a special CURSOR parameter content as a SynDB result set
     - this method is not about a column, but a parameter defined with
       BindCursor() before method execution
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - this method allow direct access to the data rows after execution
     - this default method will raise an exception about unexpected behavior }
    function BoundCursor(Param: Integer): ISQLDBRows; virtual; 

    /// bind an array of values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. number, 'quoted string',
    // 'YYYY-MM-DD hh:mm:ss', null)
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; ParamType: TSQLDBFieldType;
      const Values: TRawUTF8DynArray; ValuesCount: integer); overload; virtual;
    /// bind an array of integer values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; const Values: array of Int64); overload; virtual;
    /// bind an array of double values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; const Values: array of double); overload; virtual;
    /// bind an array of TDateTime values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. 'YYYY-MM-DD hh:mm:ss')
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArrayDateTime(Param: Integer; const Values: array of TDateTime); virtual;
    /// bind an array of currency values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArrayCurrency(Param: Integer; const Values: array of currency); virtual;
    /// bind an array of RawUTF8 values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. 'quoted string')
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; const Values: array of RawUTF8); overload; virtual;

    {/ Prepare an UTF-8 encoded SQL statement
     - parameters marked as ? will be bound later, before ExecutePrepared call
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this default implementation will just store aSQL content and the
       ExpectResults parameter, and connect to the remote server is was not
       already connected }
    procedure Prepare(const aSQL: RawUTF8; ExpectResults: Boolean); overload; virtual;
    {/ Execute a prepared SQL statement
     - parameters marked as ? should have been already bound with Bind*() functions
     - should raise an Exception on any error }
    procedure ExecutePrepared; virtual; abstract;
    {/ Reset the previous prepared statement
     - some drivers expect an explicit reset before binding parameters and
       executing the statement another time
     - this default implementation will just do nothing }
    procedure Reset; virtual;
    {/ Prepare and Execute an UTF-8 encoded SQL statement
     - parameters marked as ? should have been already bound with Bind*()
       functions above
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this method will call Prepare then ExecutePrepared methods }
    procedure Execute(const aSQL: RawUTF8; ExpectResults: Boolean); overload;
    {/ Prepare and Execute an UTF-8 encoded SQL statement
     - parameters marked as ? should be specified as method parameter in Params[]
     - BLOB parameters could not be bound with this method, but need an explicit
       call to BindBlob() method
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this method will bind parameters, then call Excecute() virtual method }
    procedure Execute(const aSQL: RawUTF8; ExpectResults: Boolean;
      const Params: array of const); overload;
    {/ Prepare and Execute an UTF-8 encoded SQL statement
     - parameters marked as % will be replaced by Args[] value in the SQL text
     - parameters marked as ? should be specified as method parameter in Params[]
     - so could be used as such, mixing both % and ? parameters:
     ! Statement.Execute('SELECT % FROM % WHERE RowID=?',true,[FieldName,TableName],[ID])
     - BLOB parameters could not be bound with this method, but need an explicit
       call to BindBlob() method
     - if ExpectResults is TRUE, then Step() and Column*() methods are available
       to retrieve the data rows
     - should raise an Exception on any error
     - this method will bind parameters, then call Excecute() virtual method }
    procedure Execute(SQLFormat: PUTF8Char; ExpectResults: Boolean;
      const Args, Params: array of const); overload;
    /// execute a prepared SQL statement and return all rows content as a JSON string
    // - JSON data is retrieved with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - this virtual implementation calls ExecutePrepared then FetchAllAsJSON()
    procedure ExecutePreparedAndFetchAllAsJSON(Expanded: boolean; out JSON: RawUTF8); virtual;
    /// gets a number of updates made by latest executed statement
    // - default implementation returns 0
    function UpdateCount: integer; virtual;
    {$ifndef LVCL}
    {/ retrieve the parameter content, after SQL execution
     - the leftmost SQL parameter has an index of 1
     - to be used e.g. with stored procedures:
     ! query :=  'BEGIN TEST_PKG.DUMMY(?, ?, ?, ?, ?); END;';
     ! stmt := Props.NewThreadSafeStatementPrepared(query, false);
     ! stmt.Bind(1, in1, paramIn);
     ! stmt.BindTextU(2, in2, paramIn);
     ! stmt.BindTextU(3, in3, paramIn);
     ! stmt.BindTextS(4, '', paramOut); // to be retrieved with out1: string
     ! stmt.Bind(5, 0, paramOut);       // to be retrieved with out2: integer
     ! stmt.ExecutePrepared;
     ! stmt.ParamToVariant(4, out1, true);
     ! stmt.ParamToVariant(5, out2, true);
     - the parameter should have been bound with IO=paramOut or IO=paramInOut
       if CheckIsOutParameter is TRUE
     - this implementation just check that Param is correct: overridden method
       should fill Value content }
    function ParamToVariant(Param: Integer; var Value: Variant;
      CheckIsOutParameter: boolean=true): TSQLDBFieldType; virtual;
    {$endif}

    {/ After a statement has been prepared via Prepare() + ExecutePrepared() or
       Execute(), this method must be called one or more times to evaluate it
     - you shall call this method before calling any Column*() methods
     - return TRUE on success, with data ready to be retrieved by Column*()
     - return FALSE if no more row is available (e.g. if the SQL statement
      is not a SELECT but an UPDATE or INSERT command)
     - access the first or next row of data from the SQL Statement result:
       if SeekFirst is TRUE, will put the cursor on the first row of results,
       otherwise, it will fetch one row of data, to be called within a loop
     - should raise an Exception on any error
     - typical use may be (see also e.g. the mORMotDB unit):
     ! var Query: ISQLDBStatement;
     ! begin
     !   Query := Props.NewThreadSafeStatementPrepared('select AccountNumber from Sales.Customer where AccountNumber like ?', ['AW000001%'],true);
     !   if Query<>nil then begin
     !     assert(SameTextU(Query.ColumnName(0),'AccountNumber'));
     !     while Query.Step do // loop through all matching data rows
     !       assert(Copy(Query.ColumnUTF8(0),1,8)='AW000001');
     !   end;
     ! end;
    }
    function Step(SeekFirst: boolean=false): boolean; virtual; abstract;
    {/ the column/field count of the current Row }
    function ColumnCount: integer;
    {/ the Column name of the current Row
     - Columns numeration (i.e. Col value) starts with 0
     - it's up to the implementation to ensure than all column names are unique }
    function ColumnName(Col: integer): RawUTF8; virtual; abstract;
    {/ returns the Column index of a given Column name
     - Columns numeration (i.e. Col value) starts with 0
     - returns -1 if the Column name is not found (via case insensitive search) }
    function ColumnIndex(const aColumnName: RawUTF8): integer; virtual; abstract;
    /// the Column type of the current Row
    // - FieldSize can be set to store the size in chars of a ftUTF8 column
    // (0 means BLOB kind of TEXT column)
    function ColumnType(Col: integer; FieldSize: PInteger=nil): TSQLDBFieldType; virtual; abstract;
    {/ returns TRUE if the column contains NULL }
    function ColumnNull(Col: integer): boolean; virtual; abstract;
    {/ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(Col: integer): Int64; overload; virtual; abstract;
    {/ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(Col: integer): double; overload; virtual; abstract;
    {/ return a Column date and time value of the current Row, first Col is 0 }
    function ColumnDateTime(Col: integer): TDateTime; overload; virtual; abstract;
    {/ return a column date and time value of the current Row, first Col is 0
    - call ColumnDateTime or ColumnUTF8 to convert into TTimeLogBits/Int64 time
     stamp from a TDateTime or text }
    function ColumnTimeStamp(Col: integer): TTimeLog; overload;
    {/ return a Column currency value of the current Row, first Col is 0 }
    function ColumnCurrency(Col: integer): currency; overload; virtual; abstract;
    {/ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(Col: integer): RawUTF8; overload; virtual; abstract;
    {/ return a Column text value as generic VCL string of the current Row, first Col is 0
     - this default implementation will call ColumnUTF8 }
    function ColumnString(Col: integer): string; overload; virtual;
    {/ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlob(Col: integer): RawByteString; overload; virtual; abstract;
    {/ return a Column as a blob value of the current Row, first Col is 0
      - this function will return the BLOB content as a TBytes
      - this default virtual method will call ColumnBlob()  }
    function ColumnBlobBytes(Col: integer): TBytes; overload; virtual;
    {$ifndef LVCL}
    {/ return a Column as a variant, first Col is 0
     - this default implementation will call ColumnToVariant() method
     - a ftUTF8 TEXT content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob BLOB content will be mapped into a TBlobData AnsiString variant }
    function ColumnVariant(Col: integer): Variant; overload;
    {/ return a Column as a variant, first Col is 0
     - this default implementation will call Column*() method above
     - a ftUTF8 TEXT content will be mapped into a generic WideString variant
       for pre-Unicode version of Delphi, and a generic UnicodeString (=string)
       since Delphi 2009: you may not loose any data during charset conversion
     - a ftBlob BLOB content will be mapped into a TBlobData AnsiString variant }
    function ColumnToVariant(Col: integer; var Value: Variant): TSQLDBFieldType; virtual;
    {$endif}
    {/ return a Column as a TSQLVar value, first Col is 0
     - the specified Temp variable will be used for temporary storage of
       svtUTF8/svtBlob values }
    procedure ColumnToSQLVar(Col: Integer; var Value: TSQLVar;
      var Temp: RawByteString; DoNotFetchBlob: boolean=false); virtual;
    {/ return a special CURSOR Column content as a SynDB result set
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - such columns are mapped as ftNull internally - so this method is the only
       one giving access to the data rows
     - this default method will raise an exception about unexpected behavior }
    function ColumnCursor(Col: integer): ISQLDBRows; overload; virtual;
    {/ return a Column integer value of the current Row, from a supplied column name }
    function ColumnInt(const ColName: RawUTF8): Int64; overload;
    {/ return a Column floating point value of the current Row, from a supplied column name }
    function ColumnDouble(const ColName: RawUTF8): double; overload;
    {/ return a Column date and time value of the current Row, from a supplied column name }
    function ColumnDateTime(const ColName: RawUTF8): TDateTime; overload;
    {/ return a column date and time value of the current Row, from a supplied column name
    - call ColumnDateTime or ColumnUTF8 to convert into TTimeLogBits/Int64 time
     stamp from a TDateTime or text }
    function ColumnTimeStamp(const ColName: RawUTF8): TTimeLog; overload;
    {/ return a Column currency value of the current Row, from a supplied column name }
    function ColumnCurrency(const ColName: RawUTF8): currency; overload;
    {/ return a Column UTF-8 encoded text value of the current Row, from a supplied column name }
    function ColumnUTF8(const ColName: RawUTF8): RawUTF8; overload;
    {/ return a Column text value as generic VCL string of the current Row, from a supplied column name }
    function ColumnString(const ColName: RawUTF8): string; overload;
    {/ return a Column as a blob value of the current Row, from a supplied column name }
    function ColumnBlob(const ColName: RawUTF8): RawByteString; overload;
    {/ return a Column as a blob value of the current Row, from a supplied column name }
    function ColumnBlobBytes(const ColName: RawUTF8): TBytes; overload;
    {$ifndef LVCL}
    {/ return a Column as a variant, from a supplied column name }
    function ColumnVariant(const ColName: RawUTF8): Variant; overload;
    {$ifndef DELPHI5OROLDER}
    /// create a TSQLDBRowVariantType able to access any field content via late binding
    // - i.e. you can use Data.Name to access the 'Name' column of the current row
    // - this Variant will point to the corresponding TSQLDBStatement instance,
    // so it's not necessary to retrieve its value for each row
    // - typical use is:
    // ! var Row: Variant;
    // ! (...)
    // !  with MyConnProps.Execute('select * from table where name=?',[aName]) do begin
    // !    Row := RowDaa;
    // !    while Step do
    // !      writeln(Row.FirstName,Row.BirthDate);
    // !  end;
    function RowData: Variant; virtual;
    {$endif}
    {$endif}
    {/ return a special CURSOR Column content as a SynDB result set
     - Cursors are not handled internally by mORMot, but some databases (e.g.
       Oracle) usually use such structures to get data from strored procedures
     - such columns are mapped as ftNull internally - so this method is the only
       one giving access to the data rows
     - this default method will raise an exception about unexpected behavior }
    function ColumnCursor(const ColName: RawUTF8): ISQLDBRows; overload;
    {/ append all columns values of the current Row to a JSON stream
     - will use WR.Expand to guess the expected output format
     - this default implementation will call Column*() methods above, but you
       should also implement a custom version with no temporary variable
     - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"
       format and contains true BLOB data }
    procedure ColumnsToJSON(WR: TJSONWriter; DoNotFletchBlobs: boolean); virtual;
    {/ compute the SQL INSERT statement corresponding to this columns row
    - and populate the Fields[] array with columns information (type and name)
    - the SQL statement is prepared with bound parameters, e.g.
    $ insert into TableName (Col1,Col2) values (?,N)
    - used e.g. to convert some data on the fly from one database to another }
    function ColumnsToSQLInsert(const TableName: RawUTF8;
      var Fields: TSQLDBColumnPropertyDynArray): RawUTF8; virtual;
    // Append all rows content as a JSON stream
    // - JSON data is added to the supplied TStream, with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - similar to corresponding TSQLRequest.Execute method in SynSQLite3 unit
    // - you can ignore all BLOB fields, if DoNotFletchBlobs is set to TRUE
    // - you can go back to the first row of data before creating the JSON, if
    // RewindToFirst is TRUE (could be used e.g. for TQuery.FetchAllAsJSON)
    // - returns the number of row data returned (excluding field names)
    // - warning: TSQLRestStorageExternal.EngineRetrieve in mORMotDB unit
    // expects the Expanded=true format to return '[{...}]'#10
    function FetchAllToJSON(JSON: TStream; Expanded: boolean;
      DoNotFletchBlobs: boolean=false; RewindToFirst: boolean=false): PtrInt;
    // Append all rows content as a CSV stream
    // - CSV data is added to the supplied TStream, with UTF-8 encoding
    // - if Tab=TRUE, will use TAB instead of ',' between columns
    // - you can customize the ',' separator - use e.g. the global ListSeparator
    // variable (from SysUtils) to reflect the current system definition (some
    // country use ',' as decimal separator, for instance our "douce France")
    // - AddBOM will add a UTF-8 Byte Order Mark at the beginning of the content
    // - BLOB fields will be appended as "blob" with no data
    // - returns the number of row data returned
    function FetchAllToCSVValues(Dest: TStream; Tab: boolean; CommaSep: AnsiChar=',';
      AddBOM: boolean=true): PtrInt;
    // return all rows content as a JSON string
    // - JSON data is retrieved with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - if ReturnedRowCount points to an integer variable, it will be filled with
    // the number of row data returned (excluding field names)
    // - you can ignore all BLOB fields, if DoNotFletchBlobs is set to TRUE
    // - you can go back to the first row of data before creating the JSON, if
    // RewindToFirst is TRUE (could be used e.g. for TQuery.FetchAllAsJSON)
    // - similar to corresponding TSQLRequest.Execute method in SynSQLite3 unit
    function FetchAllAsJSON(Expanded: boolean; ReturnedRowCount: PPtrInt=nil;
      DoNotFletchBlobs: boolean=false; RewindToFirst: boolean=false): RawUTF8;
    /// append all rows content as binary stream
    // - will save the column types and name, then every data row in optimized
    // binary format (faster and smaller than JSON)
    // - you can specify a LIMIT for the data extent (default 0 meaning all data)
    // - generates the format expected by TSQLDBProxyStatement
    function FetchAllToBinary(Dest: TStream; MaxRowCount: cardinal=0;
      DataRowPosition: PCardinalDynArray=nil): cardinal;
    /// append current row content as binary stream
    // - will save one data row in optimized binary format (if not in Null)
    // - virtual method called by FetchAllToBinary()
    // - follows the format expected by TSQLDBProxyStatement
    procedure ColumnsToBinary(W: TFileBufferWriter; const Null: TSQLDBProxyStatementColumns;
      const ColTypes: TSQLDBFieldTypeDynArray); virtual;

    /// the associated database connection
    property Connection: TSQLDBConnection read fConnection;
    /// the prepared SQL statement, as supplied to Prepare() method
    property SQL: RawUTF8 read fSQL;
    /// the prepared SQL statement, with all '?' changed into the supplied
    // parameter values
    property SQLWithInlinedParams: RawUTF8 read GetSQLWithInlinedParams;
    /// the current row after Execute call, corresponding to Column*() methods
    // - contains 0 in case of no (more) available data, or a number >=1
    property CurrentRow: Integer read fCurrentRow;
    /// the total number of data rows retrieved by this instance
    // - is not reset when there is no more row of available data (Step returns
    // false), or when Step() is called with SeekFirst=true
    property TotalRowsRetrieved: Integer read fTotalRowsRetrieved;
  end;

  /// abstract connection created from TSQLDBConnectionProperties
  // - this overridden class will defined an hidden thread ID, to ensure
  // that one connection will be create per thread
  // - e.g. OleDB, ODBC and Oracle connections will inherit from this class
  TSQLDBConnectionThreadSafe = class(TSQLDBConnection)
  protected
    fThreadID: DWORD;
  end;

  /// diverse threading modes used by TSQLDBConnectionPropertiesThreadSafe
  // - default mode is to use a Thread Pool, i.e. one connection per thread
  // - or you can force to use the main connection
  // - or you can use a shared background thread process
  // - last two modes could be used in database embedded mode (SQLite3/FireBird),
  // when multiple connections may break stability, consume too much resources
  // and/or decrease performance
  TSQLDBConnectionPropertiesThreadSafeThreadingMode = (
    tmThreadPool, tmMainConnection, tmBackgroundThread);

  /// connection properties which will implement an internal Thread-Safe
  // connection pool
  TSQLDBConnectionPropertiesThreadSafe = class(TSQLDBConnectionProperties)
  protected
    fConnectionPool: TObjectList;
    fLatestConnectionRetrievedInPool: integer;
    fConnectionCS: TRTLCriticalSection;
    fThreadingMode: TSQLDBConnectionPropertiesThreadSafeThreadingMode;
    /// returns nil if none was defined yet
    function CurrentThreadConnection: TSQLDBConnection;
    /// returns -1 if none was defined yet
    function CurrentThreadConnectionIndex: Integer;
    /// overridden method to properly handle multi-thread
    function GetMainConnection: TSQLDBConnection; override;
  public
    /// initialize the properties
    // - this overridden method will initialize the internal per-thread connection pool
    constructor Create(const aServerName, aDatabaseName, aUserID, aPassWord: RawUTF8); override;
    /// release related memory, and all per-thread connections
    destructor Destroy; override;
    /// get a thread-safe connection
    // - this overridden implementation will define a per-thread TSQLDBConnection
    // connection pool, via an internal  pool
    function ThreadSafeConnection: TSQLDBConnection; override;
    /// release all existing connections
    // - this overridden implementation will release all per-thread
    // TSQLDBConnection internal connection pool
    // - warning: no connection shall be still be used on the background, or
    // some unexpected border effects may occur
    procedure ClearConnectionPool; override;
    /// you can call this method just before a thread is finished to ensure
    // that the associated Connection will be released
    // - could be used e.g. in a try...finally block inside a TThread.Execute
    // overridden method
    // - could be used e.g. to call CoUnInitialize from thread in which
    // CoInitialize was made, for instance via a method defined as such:
    // ! procedure TMyServer.OnHttpThreadTerminate(Sender: TObject);
    // ! begin
    // !   fMyConnectionProps.EndCurrentThread;
    // ! end;
    // - this method shall be called from the thread about to be terminated: e.g.
    // if you call it from the main thread, it may fail to release resources
    // - within the mORMot server, mORMotDB unit will call this method
    // for every terminating thread created for TSQLRestServerNamedPipeResponse
    // or TSQLHttpServer multi-thread process
    procedure EndCurrentThread; virtual;
    /// set this property if you want to disable the per-thread connection pool
    // - to be used e.g. in database embedded mode (SQLite3/FireBird), when
    // multiple connections may break stability and decrease performance
    // - see TSQLDBConnectionPropertiesThreadSafeThreadingMode for the
    // possible values
    property ThreadingMode: TSQLDBConnectionPropertiesThreadSafeThreadingMode
      read fThreadingMode write fThreadingMode;
  end;

  /// a structure used to store a standard binding parameter
  // - you can use your own internal representation of parameters
  // (TOleDBStatement use its own TOleDBStatementParam type), but
  // this type can be used to implement a generic parameter
  // - used e.g. by TSQLDBStatementWithParams as a dynamic array
  // (and its inherited TSQLDBOracleStatement)
  TSQLDBParam = packed record
    /// storage used for TEXT (ftUTF8) and BLOB (ftBlob) values
    // - ftBlob are stored as RawByteString
    // - ftUTF8 are stored as RawUTF8
    // - sometimes, may be ftInt64 or ftCurrency provided as SQLT_AVC text,
    // or ftDate value converted to SQLT_TIMESTAMP
    VData: RawByteString;
    /// storage used for bound array values
    // - number of items in array is stored in VInt64
    // - values are stored as in SQL (i.e. number, 'quoted string',
    // 'YYYY-MM-DD hh:mm:ss', null)
    VArray: TRawUTF8DynArray;
    /// the column/parameter Value type
    VType: TSQLDBFieldType;
    /// define if parameter can be retrieved after a stored procedure execution
    VInOut: TSQLDBParamInOutType;
    /// used e.g. by TSQLDBOracleStatement
    VDBType: word;
    {$ifdef CPU64}
    // so that VInt64 will be 8 bytes aligned
    VFill: cardinal;
    {$endif}
    /// storage used for ftInt64, ftDouble, ftDate and ftCurrency value
    VInt64: Int64;
  end;

  PSQLDBParam = ^TSQLDBParam;

  /// dynamic array used to store standard binding parameters
  // - used e.g. by TSQLDBStatementWithParams (and its
  // inherited TSQLDBOracleStatement)
  TSQLDBParamDynArray = array of TSQLDBParam;

  /// generic abstract class handling prepared statements with binding
  // - will provide protected fields and methods for handling standard
  // TSQLDBParam parameters
  TSQLDBStatementWithParams = class(TSQLDBStatement)
  protected
    fParams: TSQLDBParamDynArray;
    fParam: TDynArray;
    fParamsArrayCount: integer;
    function CheckParam(Param: Integer; NewType: TSQLDBFieldType;
      IO: TSQLDBParamInOutType): PSQLDBParam; overload;
    function CheckParam(Param: Integer; NewType: TSQLDBFieldType;
      IO: TSQLDBParamInOutType; ArrayCount: integer): PSQLDBParam; overload;
    /// append the inlined value of a given parameter
    // - faster overridden method
    procedure AddParamValueAsText(Param: integer; Dest: TTextWriter); override;
  public
    /// create a statement instance
    // - this overridden version will initialize the internal fParam* fields
    constructor Create(aConnection: TSQLDBConnection); override;
    {/ bind a NULL value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindNull(Param: Integer; IO: TSQLDBParamInOutType=paramIn); override;
    {/ bind an integer value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure Bind(Param: Integer; Value: Int64;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a double value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure Bind(Param: Integer; Value: double;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a TDateTime value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindDateTime(Param: Integer; Value: TDateTime;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a currency value to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindCurrency(Param: Integer; Value: currency;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a UTF-8 encoded string to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindTextU(Param: Integer; const Value: RawUTF8;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a UTF-8 encoded buffer text (#0 ended) to a parameter
     - the leftmost SQL parameter has an index of 1 }
    procedure BindTextP(Param: Integer; Value: PUTF8Char;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a VCL string to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindTextS(Param: Integer; const Value: string;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind an OLE WideString to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindTextW(Param: Integer; const Value: WideString;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindBlob(Param: Integer; Data: pointer; Size: integer;
      IO: TSQLDBParamInOutType=paramIn); overload; override;
    {/ bind a Blob buffer to a parameter
     - the leftmost SQL parameter has an index of 1
     - raise an Exception on any error }
    procedure BindBlob(Param: Integer; const Data: RawByteString;
      IO: TSQLDBParamInOutType=paramIn); overload; override;

    /// bind an array of values to a parameter using OCI bind array feature
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. number, 'quoted string',
    // 'YYYY-MM-DD hh:mm:ss', null)
    // - values are stored as in SQL (i.e. 'YYYY-MM-DD hh:mm:ss')
    procedure BindArray(Param: Integer; ParamType: TSQLDBFieldType;
      const Values: TRawUTF8DynArray; ValuesCount: integer); overload; override;
    /// bind an array of integer values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will call BindArray() after conversion into
    // RawUTF8 items, stored in TSQLDBParam.VArray
    procedure BindArray(Param: Integer; const Values: array of Int64); overload; override;
    /// bind an array of double values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    // - this default implementation will call BindArray() after conversion into
    // RawUTF8 items, stored in TSQLDBParam.VArray
    procedure BindArray(Param: Integer; const Values: array of double); overload; override;
    /// bind an array of TDateTime values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as in SQL (i.e. 'YYYY-MM-DD hh:mm:ss')
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    // - this default implementation will call BindArray() after conversion into
    // RawUTF8 items, stored in TSQLDBParam.VArray
    procedure BindArrayDateTime(Param: Integer; const Values: array of TDateTime); override;
    /// bind an array of currency values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    // - this default implementation will call BindArray() after conversion into
    // RawUTF8 items, stored in TSQLDBParam.VArray
    procedure BindArrayCurrency(Param: Integer; const Values: array of currency); override;
    /// bind an array of RawUTF8 values to a parameter
    // - the leftmost SQL parameter has an index of 1
    // - values are stored as 'quoted string'
    // - this default implementation will raise an exception if the engine
    // does not support array binding
    procedure BindArray(Param: Integer; const Values: array of RawUTF8); overload; override;

    /// start parameter array binding per-row process
    // - BindArray*() methods expect the data to be supplied "verticaly": this
    // method allow-per row binding
    // - call this method, then BindArrayRow() with the corresponding values for
    // one statement row, then Execute to send the query
    procedure BindArrayRowPrepare(const aParamTypes: array of TSQLDBFieldType;
      aExpectedMinimalRowCount: integer=0);
    /// bind a set of parameters for further array binding
    // - supplied parameters shall follow the BindArrayRowPrepare() supplied
    // types (i.e. RawUTF8, Integer/Int64, double);  you can also bind directly
    // a TDateTime value if the corresponding binding has been defined as ftDate
    // by BindArrayRowPrepare()
    procedure BindArrayRow(const aValues: array of const);
    {/ bind an array of fields from an existing SQL statement for array binding
     - supplied Rows columns shall follow the BindArrayRowPrepare() supplied
       types (i.e. RawUTF8, Integer/Int64, double, date)
     - can be used e.g. after ColumnsToSQLInsert() method call for fast data
       conversion between tables }
    procedure BindFromRows(Rows: TSQLDBStatement); virtual;
       
    {$ifndef LVCL}
    {/ retrieve the parameter content, after SQL execution
     - the leftmost SQL parameter has an index of 1
     - to be used e.g. with stored procedures
     - this overridden function will retrieve the value stored in the protected
       fParams[] array: the ExecutePrepared method should have updated its
       content as exepcted}
    function ParamToVariant(Param: Integer; var Value: Variant;
      CheckIsOutParameter: boolean=true): TSQLDBFieldType; override;
    {$endif}

    {/ Reset the previous prepared statement
     - this overridden implementation will just do reset the internal fParams[] }
    procedure Reset; override;
  end;

  /// generic abstract class handling prepared statements with binding
  // and column description
  // - will provide protected fields and methods for handling both TSQLDBParam
  // parameters and standard TSQLDBColumnProperty column description
  TSQLDBStatementWithParamsAndColumns = class(TSQLDBStatementWithParams)
  protected
    fColumns: TSQLDBColumnPropertyDynArray;
    fColumn: TDynArrayHashed;
  public
    /// create a statement instance
    // - this overridden version will initialize the internal fColumn* fields
    constructor Create(aConnection: TSQLDBConnection); override;
    {/ retrieve a column name of the current Row
     - Columns numeration (i.e. Col value) starts with 0
     - it's up to the implementation to ensure than all column names are unique }
    function ColumnName(Col: integer): RawUTF8; override;
    {/ returns the Column index of a given Column name
     - Columns numeration (i.e. Col value) starts with 0
     - returns -1 if the Column name is not found (via case insensitive search) }
    function ColumnIndex(const aColumnName: RawUTF8): integer; override;
    {/ the Column type of the current Row
     - ftCurrency type should be handled specifically, for faster process and
       avoid any rounding issue, since currency is a standard OleDB type
     - FieldSize can be set to store the size in chars of a ftUTF8 column
       (0 means BLOB kind of TEXT column) - this implementation will store
       fColumns[Col].ColumnValueDBSize if ColumnValueInlined=true}
    function ColumnType(Col: integer; FieldSize: PInteger=nil): TSQLDBFieldType; override;
    /// direct access to the columns description
    // - gives more details than the default ColumnType() function
    property Columns: TSQLDBColumnPropertyDynArray read fColumns;
  end;

{$ifndef DELPHI5OROLDER}

  /// structure to embedd all needed parameters to execute a SQL statement
  // - used for cExecute, cExecuteToBinary, cExecuteToJSON and cExecuteToExpandedJSON
  // commands of TSQLDBProxyConnectionProperties.Process()
  // - set by TSQLDBProxyStatement.ParamsToCommand() protected method
  TSQLDBProxyConnectionCommandExecute = record
    /// the associated SQL statement
    SQL: RawUTF8;
    /// input parameters
    // - trunked to the exact number of parameters
    Params: TSQLDBParamDynArray;
    /// if input parameters expected BindArray() process
    ArrayCount: integer;
  end;

  /// implements an abstract proxy-like virtual connection to a DB engine
  // - can be used e.g. for remote access or execution in a background thread
  TSQLDBProxyConnection = class(TSQLDBConnection)
  protected
    fConnected: boolean;
    function GetServerTimeStamp: TTimeLog; override;
  public
    /// connect to the specified database
    procedure Connect; override;
    /// stop connection to the specified database
    procedure Disconnect; override;
    /// return TRUE if Connect has been already successfully called
    function IsConnected: boolean; override;
    /// initialize a new SQL query statement for the given connection
    function NewStatement: TSQLDBStatement; override;
    /// begin a Transaction for this connection
    procedure StartTransaction; override;
    /// commit changes of a Transaction for this connection
    procedure Commit; override;
    /// discard changes of a Transaction for this connection
    procedure Rollback; override;
  end;

  /// implements a proxy-like virtual connection statement to a DB engine
  // - abstract class, with no corresponding kind of connection, but allowing
  // access to the mapped data via Column*() methods
  // - will handle an internal binary buffer when the statement returned rows
  // data, as generated by TSQLDBStatement.FetchAllToBinary()
  TSQLDBProxyStatementAbstract = class(TSQLDBStatementWithParamsAndColumns)
  protected
    fDataRowCount: integer;
    fDataRowReaderOrigin, fDataRowReader: PByte;
    fDataRowNullSize: cardinal;
    fDataCurrentRowNull: TSQLDBProxyStatementColumns;
    fDataCurrentRowValues: array of pointer;
    function IntColumnType(Col: integer; out Data: PByte): TSQLDBFieldType;
      {$ifdef HASINLINE}inline;{$endif}
    procedure IntHeaderProcess(Data: PByte; DataLen: integer);
    procedure IntFillDataCurrent(var Reader: PByte);
  public
    /// the Column type of the current Row
    function ColumnType(Col: integer; FieldSize: PInteger=nil): TSQLDBFieldType; override;
    {{ returns TRUE if the column contains NULL }
    function ColumnNull(Col: integer): boolean; override;
    {{ return a Column integer value of the current Row, first Col is 0 }
    function ColumnInt(Col: integer): Int64; override;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDouble(Col: integer): double; override;
    {{ return a Column floating point value of the current Row, first Col is 0 }
    function ColumnDateTime(Col: integer): TDateTime; override;
    {{ return a Column currency value of the current Row, first Col is 0
     - should retrieve directly the 64 bit Currency content, to avoid
     any rounding/conversion error from floating-point types }
    function ColumnCurrency(Col: integer): currency; override;
    {{ return a Column UTF-8 encoded text value of the current Row, first Col is 0 }
    function ColumnUTF8(Col: integer): RawUTF8; override;
    {/ return a Column text value as generic VCL string of the current Row, first Col is 0 }
    function ColumnString(Col: integer): string; override;
    {{ return a Column as a blob value of the current Row, first Col is 0 }
    function ColumnBlob(Col: integer): RawByteString; override;
    {{ return all columns values into JSON content }
    procedure ColumnsToJSON(WR: TJSONWriter; DoNotFletchBlobs: boolean); override;
    /// direct access to the data buffer of the current row
    // - points to Double/Currency value, or variable-length Int64/UTF8/Blob
    // - points to nil if the column value is NULL
    function ColumnData(Col: integer): pointer;

    /// read-only access to the number of data rows stored
    property DataRowCount: integer read fDataRowCount;
  end;

  /// implements a proxy-like virtual connection statement to a DB engine
  // - is generated by TSQLDBProxyConnection kind of connection
  // - will use an internal binary buffer when the statement returned rows data,
  // as generated by TSQLDBStatement.FetchAllToBinary() or JSON for
  // ExecutePreparedAndFetchAllAsJSON() method (as expected by our ORM)
  TSQLDBProxyStatement = class(TSQLDBProxyStatementAbstract)
  protected
    fDataInternalCopy: RawByteString;
{$ifndef DELPHI5OROLDER}
    procedure ParamsToCommand(var Input: TSQLDBProxyConnectionCommandExecute);
{$endif}
  public
    /// Execute a SQL statement
    // - for TSQLDBProxyStatement, preparation and execution are processed in
    // one step, when this method is executed - as such, Prepare() won't call
    // the remote process, but will just set fSQL
    // - this overridden implementation will use out optimized binary format
    //  as generated by TSQLDBStatement.FetchAllToBinary(), and not JSON
    procedure ExecutePrepared; override;
    /// execute a prepared SQL statement and return all rows content as a JSON string
    // - JSON data is retrieved with UTF-8 encoding
    // - if Expanded is true, JSON data is an array of objects, for direct use
    // with any Ajax or .NET client:
    // & [ {"col1":val11,"col2":"val12"},{"col1":val21,... ]
    // - if Expanded is false, JSON data is serialized (used in TSQLTableJSON)
    // & { "FieldCount":1,"Values":["col1","col2",val11,"val12",val21,..] }
    // - BLOB field value is saved as Base64, in the '"\uFFF0base64encodedbinary"'
    // format and contains true BLOB data
    // - this overridden implementation will use JSON for transmission, and
    // binary encoding only for parameters (to avoid unneeded conversions, e.g.
    // when called from mORMotDB.pas)
    procedure ExecutePreparedAndFetchAllAsJSON(Expanded: boolean; out JSON: RawUTF8); override;

    /// after a statement has been prepared via Prepare() + ExecutePrepared() or
    //   Execute(), this method must be called one or more times to evaluate it
    function Step(SeekFirst: boolean=false): boolean; override;
    /// Reset the previous prepared statement
    // - always raise an ESQLDBException, since this method is not to be allowed
    procedure Reset; override;
  end;

  /// implements a proxy-like virtual connection statement to a DB engine
  // - will generate TSQLDBProxyConnection kind of connection
  TSQLDBProxyConnectionProperties = class(TSQLDBConnectionProperties)
  protected
    /// abstract process of internal commands
    // - one rough unique method is used, in order to make easier several
    // implementation schemes and reduce data marshalling as much as possible
    // - should raise an exception on error
    procedure Process(Command: TSQLDBProxyConnectionCommand;
      const Input; var Output); virtual; abstract;
    /// calls Process(cInitialize,self,fDBMS)
    procedure SetInternalProperties; override;
    /// calls Process(cGetForeignKeys,self,fForeignKeys)
    procedure GetForeignKeys; override;
  public
    /// create a new TSQLDBProxyConnection instance
    // - the caller is responsible of freeing this instance
    function NewConnection: TSQLDBConnection; override;
    /// retrieve the column/field layout of a specified table
    // - calls Process(cGetFields,aTableName,Fields)
    procedure GetFields(const aTableName: RawUTF8; var Fields: TSQLDBColumnDefineDynArray); override;
    /// retrieve the advanced indexed information of a specified Table
    // - calls Process(cGetIndexes,aTableName,Indexes)
    procedure GetIndexes(const aTableName: RawUTF8; var Indexes: TSQLDBIndexDefineDynArray); override;
    /// get all table names
    // - this default implementation will use protected SQLGetTableNames virtual
    // - calls Process(cGetTableNames,self,Tables)
    procedure GetTableNames(var Tables: TRawUTF8DynArray); override;
    /// determine if the SQL statement can be cached
    // - always returns false, to force a new fake statement to be created
    function IsCachable(P: PUTF8Char): boolean; override;
  end;

  /// implements a virtual statement with direct data access
  // - is generated with no connection, but allows direct random access to any
  // data row retrieved from TSQLDBStatement.FetchAllToBinary() binary data
  // - GotoRow() method allows direct access to a row data via Column*()
  // - is used e.g. by TSynSQLStatementDataSet of SynDBVCL unit
  TSQLDBProxyStatementRandomAccess = class(TSQLDBProxyStatementAbstract)
  protected
    fRowData: TCardinalDynArray;
  public
    /// initialize the internal structure from a given memory buffer
    constructor Create(Data: PByte; DataLen: integer;
      DataRowPosition: PCardinalDynArray=nil); reintroduce;

    /// Execute a prepared SQL statement
    // - this unexpected overridden method will raise a ESQLDBException
    procedure ExecutePrepared; override;
    /// Change cursor position to the next available row
    // - this unexpected overridden method will raise a ESQLDBException
    function Step(SeekFirst: boolean=false): boolean; override;

    /// change the current data Row
    // - if Index<DataRowCount, returns TRUE and you can access to the data
    // via regular Column*() methods
    // - can optionally raise an ESQLDBException if Index is not correct
    function GotoRow(Index: integer; RaiseExceptionOnWrongIndex: Boolean=false): boolean;
  end;


{$endif DELPHI5OROLDER}


const
  /// TSQLDBFieldType kind of columns which have a fixed width
  FIXEDLENGTH_SQLDBFIELDTYPE = [ftInt64, ftDouble, ftCurrency, ftDate];

  /// conversion matrix from TSQLDBFieldType into variant type
  MAP_FIELDTYPE2VARTYPE: array[TSQLDBFieldType] of Word = (
    varEmpty, varNull, varInt64, varDouble, varCurrency, varDate,
  {$ifdef UNICODE}varUString{$else}varOleStr{$endif}, varString);
// ftUnknown, ftNull, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob


/// function helper logging some column truncation information text
procedure LogTruncatedColumn(const Col: TSQLDBColumnProperty);

/// retrieve a table name without any left schema
// - e.g. TrimLeftSchema('SCHEMA.TABLENAME')='TABLENAME'
function TrimLeftSchema(const TableName: RawUTF8): RawUTF8;

/// replace all '?' in the SQL statement with named parameters like :AA :AB..
// - returns the number of ? parameters found within aSQL
// - won't generate any SQL keyword parameters (e.g. :AS :OF :BY), to be
// compliant with Oracle OCI expectations
function ReplaceParamsByNames(const aSQL: RawUTF8; var aNewSQL: RawUTF8): integer;


{ -------------- native connection interfaces, without OleDB }

type
  /// access to a native library
  // - this generic class is to be used for any native connection using an
  // external library
  // - is used e.g. in SynDBOracle by TSQLDBOracleLib to access the OCI library,
  // or by SynDBODBC to access the ODBC library
  TSQLDBLib = class
  protected
    fHandle: HMODULE;
  public
    /// release associated memory and linked library
    destructor Destroy; override;
    /// the associated library handle
    property Handle: HMODULE read fHandle write fHandle;
  end;


{$ifdef EMULATES_TQUERY}

{ -------------- TQuery TField TParam emulation classes and types }

type
  /// generic Exception type raised by the TQuery class
  ESQLQueryException = class(Exception)
  public
    constructor CreateFromError(aMessage: string; aConnection: TSQLDBConnection);
  end;

  /// generic type used by TQuery / TQueryValue for BLOBs fields
  TBlobData = RawByteString;

  /// represent the use of parameters on queries or stored procedures
  // - same enumeration as with the standard DB unit from VCL
  TParamType = (ptUnknown, ptInput, ptOutput, ptInputOutput, ptResult);

  TQuery = class;

  /// pseudo-class handling a TQuery bound parameter or column value
  // - will mimic both TField and TParam classes as defined in standard DB unit,
  // by pointing both classes types to PQueryValue
  // - usage of an object instead of a class allow faster access via a
  // dynamic array (and our TDynArrayHashed wrapper) for fast property name
  // handling (via name hashing) and pre-allocation
  // - it is based on an internal Variant to store the parameter or column value
  TQueryValue = {$ifndef UNICODE}object{$else}record{$endif}
  private
    /// fName should be the first property, i.e. the searched hashed value
    fName: string;
    fValue: Variant;
    fValueBlob: boolean;
    fParamType: TParamType;
    // =-1 if empty, =0 if eof, >=1 if cursor on row data
    fRowIndex: integer;
    fColumnIndex: integer;
    fQuery: TQuery;
    procedure CheckExists;
    procedure CheckValue;
    function GetIsNull: boolean;
    function GetDouble: double;
    function GetString: string;
    function GetAsWideString: SynUnicode;
    function GetCurrency: Currency;
    function GetDateTime: TDateTime;
    function GetVariant: Variant;
    function GetInteger: integer;
    function GetInt64: Int64;
    function GetBlob: TBlobData;
    function GetAsBytes: TBytes;
    function GetBoolean: Boolean;
    procedure SetDouble(const aValue: double);
    procedure SetString(const aValue: string);
    procedure SetAsWideString(const aValue: SynUnicode);
    procedure SetCurrency(const aValue: Currency);
    procedure SetDateTime(const aValue: TDateTime);
    procedure SetVariant(const aValue: Variant);
    procedure SetInteger(const aValue: integer);
    procedure SetInt64(const aValue: Int64);
    procedure SetBlob(const aValue: TBlobData);
    procedure SetAsBytes(const Value: TBytes);
    procedure SetBoolean(const aValue: Boolean);
    procedure SetBound(const aValue: Boolean);
  public
    /// set the column value to null
    procedure Clear;
    /// the associated (field) name
    property FieldName: string read fName;
    /// the associated (parameter) name
    property Name: string read fName;
    /// parameter type for queries or stored procedures
    property ParamType: TParamType read fParamType write fParamType;
    /// returns TRUE if the stored Value is null
    property IsNull: Boolean read GetIsNull;
    /// just do nothing - here for compatibility reasons with Clear + Bound := true
    property Bound: Boolean write SetBound;
    /// access the Value as Integer
    property AsInteger: integer read GetInteger write SetInteger;
    /// access the Value as Int64
    // - note that under Delphi 5, Int64 is not handled: the Variant type
    // only handle integer types, in this Delphi version :(
    property AsInt64: Int64 read GetInt64 write SetInt64;
    /// access the Value as Int64
    // - note that under Delphi 5, Int64 is not handled: the Variant type
    // only handle integer types, in this Delphi version :(
    property AsLargeInt: Int64 read GetInt64 write SetInt64;
    /// access the Value as boolean
    property AsBoolean: Boolean read GetBoolean write SetBoolean;
    /// access the Value as String
    // - used in the VCL world for both TEXT and BLOB content (BLOB content
    // will only work in pre-Unicode Delphi version, i.e. before Delphi 2009)
    property AsString: string read GetString write SetString;
    /// access the Value as an unicode String
    // - will return a WideString before Delphi 2009, and an UnicodeString
    // for Unicode versions of the compiler (i.e. our SynUnicode type)
    property AsWideString: SynUnicode read GetAsWideString write SetAsWideString;
    /// access the BLOB Value as an AnsiString
    // - will work for all Delphi versions, including Unicode versions (i.e.
    // since Delphi 2009)
    // - for a BLOB parameter or column, you should use AsBlob or AsBlob 
    // properties instead of AsString (this later won't work after Delphi 2007)
    property AsBlob: TBlobData read GetBlob write SetBlob;
    /// access the BLOB Value as array of byte (TBytes)
     // - will work for all Delphi versions, including Unicode versions (i.e.
    // since Delphi 2009)
    // - for a BLOB parameter or column, you should use AsBlob or AsBlob
    // properties instead of AsString (this later won't work after Delphi 2007)
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
    /// access the Value as double
    property AsFloat: double read GetDouble write SetDouble;
    /// access the Value as TDateTime
    property AsDateTime: TDateTime read GetDateTime write SetDateTime;
    /// access the Value as TDate
    property AsDate: TDateTime read GetDateTime write SetDateTime;
    /// access the Value as TTime
    property AsTime: TDateTime read GetDateTime write SetDateTime;
    /// access the Value as Currency
    // - avoid any rounding conversion, as with AsFloat
    property AsCurrency: Currency read GetCurrency write SetCurrency;
    /// access the Value as Variant
    property AsVariant: Variant read GetVariant write SetVariant;
  end;

  /// a dynamic array of TQuery bound parameters or column values
  // - TQuery will use TDynArrayHashed for fast search
  TQueryValueDynArray = array of TQueryValue;

  /// pointer to TQuery bound parameter or column value
  PQueryValue = ^TQueryValue;

  /// pointer mapping the VCL DB TField class
  // - to be used e.g. with code using local TField instances in a loop
  TField = PQueryValue;

  /// pointer mapping the VCL DB TParam class
  // - to be used e.g. with code using local TParam instances
  TParam = PQueryValue;

  /// class mapping VCL DB TQuery for direct database process
  // - this class can mimic basic TQuery VCL methods, but won't need any BDE
  // installed, and will be faster for field and parameters access than the
  // standard TDataSet based implementation; in fact, OleDB replaces the BDE
  // or the DBExpress layer, or access directly to the client library
  // (e.g. for TSQLDBOracleConnectionProperties which calls oci.dll)
  // - it is able to run basic queries as such:
  // !  Q := TQuery.Create(aSQLDBConnection);
  // !  try
  // !    Q.SQL.Clear; // optional
  // !    Q.SQL.Add('select * from DOMAIN.TABLE');
  // !    Q.SQL.Add('  WHERE ID_DETAIL=:detail;');
  // !    Q.ParamByName('DETAIL').AsString := '123420020100000430015';
  // !    Q.Open;
  // !    Q.First;    // optional
  // !    while not Q.Eof do begin
  // !      assert(Q.FieldByName('id_detail').AsString='123420020100000430015');
  // !      Q.Next;
  // !    end;
  // !    Q.Close;    // optional
  // !  finally
  // !    Q.Free;
  // !  end;
  // - since there is no underlying TDataSet, you can't have read and write
  // access, or use the visual DB components of the VCL: it's limited to
  // direct emulation of low-level SQL as in the above code, with one-direction
  // retrieval (e.g. the Edit, Post, Append, Cancel, Prior, Locate, Lookup
  // methods do not exist within this class)
  // - use QueryToDataSet() function from SynDBVCL.pas to create a TDataSet
  // from such a TQuery instance, and link this request to visual DB components
  // - this class is Unicode-ready even before Delphi 2009 (via the TQueryValue
  // AsWideString method), will natively handle Int64/TBytes field or parameter
  // data, and will have less overhead than the standard DB components of the VCL
  // - you should better use TSQLDBStatement instead of this wrapper, but
  // having such code-compatible TQuery replacement could make easier some
  // existing code upgrade (e.g. to avoid deploying the deprecated BDE, generate
  // smaller executable, access any database without paying a big fee,
  // avoid rewriting a lot of existing code lines of a big application...)
  TQuery = class
  protected
    fSQL: TStringList;
    fPrepared: ISQLDBStatement;
    fRowIndex: Integer;
    fConnection: TSQLDBConnection;
    fParams: TQueryValueDynArray;
    fResults: TQueryValueDynArray;
    fResult: TDynArrayHashed;
    fResultCount: integer;
    fParam: TDynArrayHashed;
    fParamCount: Integer;
    function GetIsEmpty: Boolean;
    function GetActive: Boolean;
    function GetFieldCount: integer;
    function GetParamCount: integer;
    function GetField(aIndex: integer): TField;
    function GetParam(aIndex: integer): TParam;
    function GetEof: boolean;
    function GetBof: Boolean;
    function GetRecordCount: integer;
    function GetSQLAsText: string;
    procedure OnSQLChange(Sender: TObject);
    /// prepare and execute the SQL query
    procedure Execute(ExpectResults: Boolean);
  public
    /// initialize a query for the associated database connection
    constructor Create(aConnection: TSQLDBConnection);
    /// release internal memory and statements
    destructor Destroy; override;
    /// a do-nothing method, just available for compatibility purpose
    procedure Prepare;
    /// begin the SQL query, for a SELECT statement
    // - will parse the entered SQL statement, and bind parameters
    // - will then execute the SELECT statement, ready to use First/Eof/Next
    // methods, the returned rows being available via FieldByName methods
    procedure Open;
    /// begin the SQL query, for a non SELECT statement
    // - will parse the entered SQL statement, and bind parameters
    // - the query will be released with a call to Close within this method
    procedure ExecSQL;
    /// after a successfull Open, will get the first row of results
    procedure First;
    /// after successfull Open and First, go the the next row of results
    procedure Next;
    { procedure Last;  BUGGY method -> use ORDER DESC instead }
    /// end the SQL query
    // - will release the SQL statement, results and bound parameters
    // - the query should be released with a call to Close before reopen
    procedure Close;
    /// access a SQL statement parameter, entered as :aParamName in the SQL
    // - if the requested parameter do not exist yet in the internal fParams
    // list, AND if CreateIfNotExisting=true, a new TQueryValue instance
    // will be created and registered
    function ParamByName(const aParamName: string; CreateIfNotExisting: boolean=true): TParam;
    /// retrieve a column value from the current opened SQL query row
    // - will raise an ESQLQueryException error in case of error, e.g. if no column
    // name matchs the supplied name
    function FieldByName(const aFieldName: string): TField;
    /// retrieve a column value from the current opened SQL query row
    // - will return nil in case of error, e.g. if no column name matchs the
    // supplied name
    function FindField(const aFieldName: string): TField;
    /// the associated database connection
    property Connection: TSQLDBConnection read fConnection;
    /// the SQL statement to be executed
    // - statement will be prepared and executed via Open or ExecSQL methods
    // - SQL.Clear will force a call to the Close method (i.e. reset the query,
    // just as with the default VCL implementation)
    property SQL: TStringList read fSQL;
    /// the SQL statement with inlined bound parameters
    property SQLAsText: string read GetSQLAsText;
    /// equals true if there is some rows pending
    property Eof: Boolean read GetEof;
    /// equals true if on first row
    property Bof: Boolean read GetBof;
    /// returns 0 if no record was retrievd, 1 if there was some records
    // - not the exact count: just here for compatibility purpose with code
    // like   if aQuery.RecordCount>0 then ...
    property RecordCount: integer read GetRecordCount;
    /// equals true if there is no row returned
    property IsEmpty: Boolean read GetIsEmpty;
    /// equals true if the query is opened
    property Active: Boolean read GetActive;
    /// the number of columns in the current opened SQL query row
    property FieldCount: integer read GetFieldCount;
    /// the number of bound parameters in the current SQL statement
    property ParamCount: integer read GetParamCount;
    /// retrieve a column value from the current opened SQL query row
    // - will return nil in case of error, e.g. out of range index
    property Fields[aIndex: integer]: TField read GetField;
    /// retrieve a  bound parameters in the current SQL statement
    // - will return nil in case of error, e.g. out of range index
    property Params[aIndex: integer]: TParam read GetParam;
    /// non VCL property to access the internal SynDB prepared statement
    // - is nil if the TQuery is not prepared (e.g. after Close)
    property PreparedSQLDBStatement: ISQLDBStatement read fPrepared;
  end;

{$endif EMULATES_TQUERY}

var
  /// the TSynLog class used for logging for all our SynDB related units
  // - you may override it with TSQLLog, if available from mORMot.pas
  // - since not all exceptions are handled specificaly by this unit, you
  // may better use a common TSynLog class for the whole application or module
  SynDBLog: TSynLogClass=TSynLog;



{ -------------- Database specific classes - shared by several SynDB units }

const
  /// the known column data types corresponding to our TSQLDBFieldType types
  // - will be used e.g. for TSQLDBConnectionProperties.SQLFieldCreate()
  // - see TSQLDBFieldTypeDefinition documentation to find out the mapping
  DB_FIELDS: array[TSQLDBDefinition] of TSQLDBFieldTypeDefinition = (
  // ftUnknown=ID, ftNull=UTF8, ftInt64, ftDouble, ftCurrency, ftDate, ftUTF8, ftBlob
  // dUnknown
  (' INT',' NVARCHAR(%)',' BIGINT',' DOUBLE',' NUMERIC(19,4)',' TIMESTAMP',' CLOB',' BLOB'),
  // dDefault
  (' INT',' NVARCHAR(%)',' BIGINT',' DOUBLE',' NUMERIC(19,4)',' TIMESTAMP',' CLOB',' BLOB'),
  // dOracle
  (' NUMBER(22,0)',' NVARCHAR2(%)',' NUMBER(22,0)',' BINARY_DOUBLE',' NUMBER(19,4)',' DATE',
   ' NCLOB',' BLOB'),
  // NCLOB (National Character Large Object) is an Oracle data type that can hold
  // up to 4 GB of character data. It's similar to a CLOB, but characters are
  // stored in a NLS or multibyte national character set (like NVARCHAR2)
  // dMSSQL
  (' int',' nvarchar(%)',' bigint',' float',' money',' datetime',' nvarchar(max)',
   ' varbinary(max)'),
  // dJet
  (' LONG',' VarChar(%)',' Decimal(19,0)',' Double',' Currency',' DateTime',
   ' LongText',' LongBinary'),
  // dMySQL
  (' INT',' varchar(%) character set UTF8',' bigint',' double',' decimal(19,4)',' datetime',
   ' mediumtext character set UTF8',' mediumblob'),
  // dSQLite
  (' INTEGER',' TEXT',' INTEGER',' FLOAT',' FLOAT',' TEXT',' TEXT',' BLOB'),
  // dFirebird
  (' INTEGER',' VARCHAR(%) CHARACTER SET UTF8',' BIGINT',' FLOAT',' DECIMAL(18,4)',' TIMESTAMP',
   // about BLOB: http://www.ibphoenix.com/resources/documents/general/doc_54
   ' BLOB SUB_TYPE 1 SEGMENT SIZE 2000 CHARACTER SET UTF8',
   ' BLOB SUB_TYPE 0 SEGMENT SIZE 2000'),
  // dNexusDB
  (' INTEGER',' NVARCHAR(%)',' LARGEINT',' REAL',' MONEY',' DATETIME',' NCLOB',' BLOB'),
  // VARCHAR(%) CODEPAGE 65001 just did not work well with Delphi<2009
  // dPostgreSQL - we will create TEXT column instead of VARCHAR(%)
  (' INTEGER',' TEXT',' BIGINT',' DOUBLE PRECISION',' NUMERIC(19,4)',
   ' TIMESTAMP',' TEXT',' BYTEA'),
  // dDB2 (for CCSID Unicode tables) - bigint needs 9.1 and up
  (' int',' varchar(%)',' bigint',' real',' decimal(19,4)',' timestamp',' clob', ' blob')
  );

  /// the known column data types corresponding to our TSQLDBFieldType types
  // - will be used e.g. for TSQLDBConnectionProperties.SQLFieldCreate()
  // - SQLite3 doesn't expect any field length, neither PostgreSQL, so set to 0
  DB_FIELDSMAX: array[TSQLDBDefinition] of cardinal = (
    1000, 1000, 1333, { =4000/3 since WideChar is up to 3 bytes in UTF-8 }
    4000, 255, 4000, 0, 32760, 32767, 0, 32700);

  /// the known SQL statement to retrieve the server date and time
  DB_SERVERTIME: array[TSQLDBDefinition] of RawUTF8 = (
    '','', // return local server time by default
    'select sysdate from dual',
    'select GETDATE()',
    '', // Jet is local -> return local time
    'SELECT NOW()',
    '', // SQlite is local -> return local time
    'select current_timestamp from rdb$database',
    'SELECT CURRENT_TIMESTAMP',
    'SELECT LOCALTIMESTAMP',
    'select current timestamp from sysibm.sysdummy1'
  );

  /// the known SQL syntax to limit the number of returned rows in a SELECT
  // - Positon indicates if should be included within the WHERE clause,
  // at the beginning of the SQL statement, or at the end of the SQL statement
  // - InsertFmt will replace '%' with the maximum number of lines to be retrieved
  // - used by TSQLDBConnectionProperties.AdaptSQLLimitForEngineList()
  DB_SQLLIMITCLAUSE: array[TSQLDBDefinition] of record
    Position: (posNone, posWhere, posSelect, posAfter);
    InsertFmt: PUTF8Char;
  end = (
    (Position: posNone;   InsertFmt:nil),
    (Position: posNone;   InsertFmt:nil),
    (Position: posWhere;  InsertFmt:'rownum<=%'),
    (Position: posSelect; InsertFmt:'top(%) '),
    (Position: posSelect; InsertFmt:'top % '),
    (Position: posAfter;  InsertFmt:' limit %'),
    (Position: posAfter;  InsertFmt:' limit %'),
    (Position: posSelect; InsertFmt:'first % '),
    (Position: posSelect; InsertFmt:'top % '),
    (Position: posAfter;  InsertFmt:' limit %'),
    (Position: posAfter;  InsertFmt:' fetch first % rows only'));

  /// the known database engines handling CREATE INDEX IF NOT EXISTS statement
  DB_HANDLECREATEINDEXIFNOTEXISTS = [dSQLite];

  /// the known database engines handling CREATE INDEX on BLOB columns
  DB_HANDLEINDEXONBLOBS = [dSQLite];

  /// where the DESC clause shall be used for a CREATE INDEX statement
  // - only identified syntax exception is for FireBird
  DB_SQLDESENDINGINDEXPOS: array[TSQLDBDefinition] of
    (posWithColumn, posGlobalBefore) = (
    posWithColumn, posWithColumn, posWithColumn, posWithColumn, posWithColumn,
    posWithColumn, posWithColumn, posGlobalBefore, posWithColumn, posWithColumn,
    posWithColumn);



implementation

function OracleSQLIso8601ToDate(Iso8601: RawUTF8): RawUTF8;
begin
  if (length(Iso8601)>10) and (Iso8601[11]='T') then
    Iso8601[11] := ' '; // 'T' -> ' '
  result := 'to_date('''+Iso8601+''',''YYYY-MM-DD HH24:MI:SS'')'; // from Iso8601
end;


{$ifdef EMULATES_TQUERY}

{ ESQLQueryException }

constructor ESQLQueryException.CreateFromError(aMessage: string; aConnection: TSQLDBConnection);
begin
  if aMessage='' then
    aMessage := 'Error';
  if (aConnection=nil) or (aConnection.fErrorMessage='') then
    Create(aMessage) else
  if aConnection.fErrorException=nil then
    CreateFmt('%s "%s"',[aMessage,aConnection.fErrorMessage]) else
    CreateFmt('%s as %s with message "%s"',
      [aMessage,aConnection.fErrorException.ClassName,aConnection.fErrorMessage]);
end;

{ TQueryValue }

procedure TQueryValue.CheckExists;
begin
  if @self=nil then
    raise ESQLQueryException.Create('Parameter/Field not existing');
end;

procedure TQueryValue.CheckValue;
begin
  CheckExists;
  if fQuery=nil then
    exit; // Params already have updated value
  if fQuery.fRowIndex<=0 then // =-1 if empty, =0 if eof, >=1 if row data
    fValue := Null else
  if fRowIndex<>fQuery.fRowIndex then begin // get column value once per row
    fRowIndex := fQuery.fRowIndex;
    fQuery.fPrepared.ColumnToVariant(fColumnIndex,fValue);
  end;
end;

// in code below, most of the work should have been done by the Variants unit :)
// but since Delphi 5 does not handle varInt64 type, we had do handle it :(
// in all cases, our version should speed up process a little bit ;)

procedure TQueryValue.Clear;
begin
  fValue := Null;
end;

function TQueryValue.GetAsBytes: TBytes;
var tmp: TBlobData;
    L: integer;
begin
  CheckValue;
  if TVarData(fValue).VType<>varNull then
    tmp := TBlobData(fValue);
  L := length(tmp);
  Setlength(result,L);
  move(pointer(tmp)^,pointer(result)^,L);
end;

function TQueryValue.GetAsWideString: SynUnicode;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := '';
    varInt64:    result := UTF8ToSynUnicode(Int64ToUtf8(VInt64));
  else Result := SynUnicode(fValue);
  end;
end;

function TQueryValue.GetBlob: TBlobData;
begin
  CheckValue;
  if TVarData(fValue).VType<>varNull then
    Result := TBlobData(fValue) else
    Result := '';
end;

function TQueryValue.GetBoolean: Boolean;
begin
  Result := GetInt64<>0;
end;

function TQueryValue.GetCurrency: Currency;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := VCurrency;
    varDouble, varDate:   result := VDouble;
    else result := fValue;
  end;
end;

function TQueryValue.GetDateTime: TDateTime;
begin
  Result := GetDouble;
end;

function TQueryValue.GetDouble: double;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := VCurrency;
    varDouble, varDate: result := VDouble;
    else result := fValue;
  end;
end;

function TQueryValue.GetInt64: Int64;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := trunc(VCurrency);
    varDouble, varDate: result := trunc(VDouble);
    else result := {$ifdef DELPHI5OROLDER}integer{$endif}(fValue);
  end;
end;

function TQueryValue.GetInteger: integer;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := 0;
    varInteger:  result := VInteger;
    varInt64:    result := VInt64;
    varCurrency: result := trunc(VCurrency);
    varDouble, varDate:   result := trunc(VDouble);
    else result := fValue;
  end;
end;

function TQueryValue.GetIsNull: boolean;
begin
  CheckValue;
  result := TVarData(fValue).VType=varNull;
end;

function TQueryValue.GetString: string;
begin
  CheckValue;
  with TVarData(fValue) do
  case VType of
    varNull:     result := '';
    varInteger:  result := IntToString(VInteger);
    varInt64:    result := IntToString(VInt64);
    varCurrency: result := Curr64ToString(VInt64);
    varDouble:   result := DoubleToString(VDouble);
    varDate:     result := Ansi7ToString(DateTimeToIso8601Text(VDate,' '));
    varString:   result := string(AnsiString(VAny));
    {$ifdef UNICODE}varUString: result := UnicodeString(VAny);{$endif}
    varOleStr:   result := WideString(VAny);
    else result := fValue;
  end;
end;

function TQueryValue.GetVariant: Variant;
begin
  CheckValue;
  {$ifdef DELPHI5OROLDER}
  with TVarData(fValue) do // Delphi 5 need conversion to float to avoid overflow
  if VType=varInt64 then
    if (VInt64<low(Integer)) or (VInt64>high(Integer)) then
      result := VInt64*1.0 else
      result := integer(VInt64) else
  {$endif}
    result := fValue;
end;

procedure TQueryValue.SetAsBytes(const Value: TBytes);
var tmp: TBlobData;
begin
  CheckExists;
  System.SetString(tmp,PAnsiChar(Value),length(Value));
  fValue := tmp;
  fValueBlob := true;
end;

procedure TQueryValue.SetAsWideString(const aValue: SynUnicode);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetBlob(const aValue: TBlobData);
begin
  CheckExists;
  fValue := aValue;
  fValueBlob := true;
end;

procedure TQueryValue.SetBoolean(const aValue: Boolean);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetBound(const aValue: Boolean);
begin
  ; // just do nothing
end;

procedure TQueryValue.SetCurrency(const aValue: Currency);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetDateTime(const aValue: TDateTime);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetDouble(const aValue: double);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetInt64(const aValue: Int64);
begin
  CheckExists;
{$ifdef DELPHI5OROLDER}
  with TVarData(fValue) do begin
    if not(VType in VTYPE_STATIC) then
      VarClear(fValue);
    VType := varInt64;
    VInt64 := aValue;
  end;
{$else}
  fValue := aValue;
{$endif}
end;

procedure TQueryValue.SetInteger(const aValue: integer);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetString(const aValue: string);
begin
  CheckExists;
  fValue := aValue;
end;

procedure TQueryValue.SetVariant(const aValue: Variant);
begin
  CheckExists;
  fValue := aValue;
end;


{ TQuery }

procedure TQuery.Close;
begin
  try
    fPrepared := nil;
  finally
    //fSQL.Clear; // original TQuery expect SQL content to be preserved
    fParam.Clear;
    fParam.ReHash; // ensure no GPF if reOpen
    fResult.Clear;
    fResult.ReHash; // ensure no GPF if reOpen
    fRowIndex := -1; // =-1 if empty
  end;
end;

constructor TQuery.Create(aConnection: TSQLDBConnection);
begin
  inherited Create;
  fConnection := aConnection;
  fSQL := TStringList.Create;
  fSQL.OnChange := OnSQLChange;
  fParam.Init(TypeInfo(TQueryValueDynArray),fParams,nil,nil,nil,@fParamCount,true);
  fResult.Init(TypeInfo(TQueryValueDynArray),fResults,nil,nil,nil,@fResultCount,true);
end;

destructor TQuery.Destroy;
begin
  try
    Close;
  finally
    fSQL.Free;
    inherited;
  end;
end;

procedure TQuery.Prepare;
begin
  // just available for compatibility purpose
end;

procedure TQuery.ExecSQL;
begin
  Execute(false);
  Close;
end;

function TQuery.FieldByName(const aFieldName: string): PQueryValue;
var i: integer;
begin
  if self=nil then
    result := nil else begin
    i := fResult.FindHashed(aFieldName);
    if i<0 then
      raise ESQLQueryException.CreateFmt(
        'FieldByName("%s"): unknown field name',[aFieldName]) else
      result := @fResults[i];
  end;
end;

function TQuery.FindField(const aFieldName: string): TField;
var i: integer;
begin
  result := nil;
  if (self=nil) or (fRowIndex<=0) then // -1=empty, 0=eof, >=1 if row data
    exit;
  i := fResult.FindHashed(aFieldName);
  if i>=0 then
    result := @fResults[i];
end;

procedure TQuery.First;
begin
  if (self=nil) or (fPrepared=nil) then
    raise ESQLQueryException.Create('First: Invalid call');
  if fRowIndex<>1 then // perform only if cursor not already on first data row 
    if fPrepared.Step(true) then
      // cursor sucessfully set to 1st row  
      fRowIndex := 1 else
      // no row is available -> empty result
      fRowIndex := -1; // =-1 if empty, =0 if eof, >=1 if cursor on row data
end;

function TQuery.GetEof: boolean;
begin
  result := (Self=nil) or (fRowIndex<=0);
end;

function TQuery.GetRecordCount: integer;
begin
  if IsEmpty then
    result := 0 else
    result := 1;
end;

function TQuery.GetBof: Boolean;
begin
  result := (Self<>nil) and (fRowIndex=1);
end;

function TQuery.GetIsEmpty: Boolean;
begin
  result := (Self=nil) or (fRowIndex<0); // =-1 if empty, =0 if eof
end;

function TQuery.GetActive: Boolean;
begin
  result := (self<>nil) and (fPrepared<>nil);
end;

function TQuery.GetFieldCount: integer;
begin
  if IsEmpty then
    result := 0 else
    result := fResultCount;
end;

function TQuery.GetParamCount: integer;
begin
  if IsEmpty then
    result := 0 else
    result := fParamCount;
end;

function TQuery.GetField(aIndex: integer): TField;
begin
  if (Self=nil) or (fRowIndex<0) or (cardinal(aIndex)>=cardinal(fResultCount)) then
    result := nil else
    result := @fResults[aIndex];
end;

function TQuery.GetParam(aIndex: integer): TParam;
begin
  if (Self=nil) or (cardinal(aIndex)>=cardinal(fParamCount)) then
    result := nil else
    result := @fParams[aIndex];
end;

function TQuery.GetSQLAsText: string;
begin
  if (self=nil) or (fPrepared=nil) then
    result := '' else
    result := Utf8ToString(fPrepared.Instance.GetSQLWithInlinedParams);
end;

procedure TQuery.OnSQLChange(Sender: TObject);
begin
  if (self<>nil) and (SQL.Count=0) then
    Close; // expected previous behavior
end;

procedure TQuery.Next;
begin
  if (self=nil) or (fPrepared=nil) then
    raise ESQLQueryException.Create('Next: Invalid call');
  Connection.InternalProcess(speActive);
  try
    if fPrepared.Step(false) then
      inc(fRowIndex) else
      // no more row is available
      fRowIndex := 0;
  finally
    Connection.InternalProcess(speNonActive);
  end;
end;

{
procedure TQuery.Last;
var i: integer;
begin
  if (self=nil) or (fPrepared=nil) then
    raise ESQLQueryException.Create('Next: Invalid call');
  while fPrepared.Step(false) do begin
    inc(fRowIndex);
    for i := 0 to fPrepared.ColumnCount-1 do begin
      fPrepared.ColumnToVariant(i,fResults[i].fValue);
      fResults[i].fRowIndex := fRowIndex;
    end;
  end;
end;
}

procedure TQuery.Open;
var i, h: integer;
    added: boolean;
    ColumnName: string;
begin
  if fResultCount>0 then
    Close;
  Execute(true);
  for i := 0 to fPrepared.ColumnCount-1 do begin
    ColumnName := UTF8ToString(fPrepared.ColumnName(i));
    h := fResult.FindHashedForAdding(ColumnName,added);
    if not added then
      raise ESQLQueryException.CreateFmt('Duplicated column name "%s"',[ColumnName]);
    with fResults[h] do begin
      fQuery := self;
      fRowIndex := 0;
      fColumnIndex := i;
      fName := ColumnName;
    end;
  end;
  assert(fResultCount=fPrepared.ColumnCount);
  // always read the first row
  First;
end;

function TQuery.ParamByName(const aParamName: string;
  CreateIfNotExisting: boolean): PQueryValue;
var i: integer;
    added: boolean;
begin
  if CreateIfNotExisting then begin
    i := fParam.FindHashedForAdding(aParamName,added);
    result := @fParams[i];
    if added then
      result^.fName := aParamName;
  end else begin
    i := fParam.FindHashed(aParamName);
    if i>=0 then
      result := @fParams[i] else
      result := nil;
  end;
end;

procedure TQuery.Execute(ExpectResults: Boolean);
const
  DB2OLE: array[TParamType] of TSQLDBParamInOutType = (
     paramIn,  paramIn, paramOut, paramInOut,    paramIn);
 // ptUnknown, ptInput, ptOutput, ptInputOutput, ptResult
var req, new, tmp: RawUTF8;
    paramName: string; // just like TQueryValue.Name: string
    P, B: PUTF8Char;
    col, i: Integer;
    cols: TIntegerDynArray;
begin
  if (self=nil) or (fResultCount>0) or
     (fConnection=nil) or (fPrepared<>nil) then
    raise ESQLQueryException.Create('TQuery.Prepare called with no previous Close');
  fRowIndex := -1;
  if fConnection=nil then
    raise ESQLQueryException.Create('No Connection to DB specified');
  req := Trim(StringToUTF8(SQL.Text));
  P := pointer(req);
  if P=nil then
    ESQLQueryException.Create('No SQL statement');
  col := 0;
  repeat
    B := P;
    while not (P^ in [':',#0]) do begin
      case P^ of
      '''': begin
        repeat // ignore chars inside ' quotes
          inc(P);
        until (P[0]=#0) or ((P[0]='''')and(P[1]<>''''));
        if P[0]=#0 then break;
        end;
      #1..#31:
        P^ := ' '; // convert #13/#10 into ' '
      end;
      inc(P);
    end;
   SetString(tmp,PAnsiChar(B),P-B);
    if P^=#0 then begin
      new := new+tmp;
      break;
    end;
    new := new+tmp+'?';
    inc(P); // jump ':'
    B := P;
    while ord(P^) in IsIdentifier do
      inc(P); // go to end of parameter name
    paramName := UTF8DecodeToString(B,P-B);
    i := fParam.FindHashed(paramName);
    if i<0 then
      raise ESQLQueryException.CreateFmt('Parameter "%s" not bound for "%s"',[paramName,req]);
    if col=length(cols) then
      SetLength(cols,col+64);
    cols[col] := i;
    inc(col);
  until P^=#0;
  Connection.InternalProcess(speActive);
  try
    fPrepared := Connection.NewStatementPrepared(new,ExpectResults);
    if fPrepared=nil then
      try
        if Connection.LastErrorWasAboutConnection then begin
          SynDBLog.Add.Log(sllDB,'TQuery.Execute() now tries to reconnect');
          Connection.Disconnect;
          Connection.Connect;
          fPrepared := Connection.NewStatementPrepared(new,ExpectResults);
          if fPrepared=nil then
            raise ESQLQueryException.CreateFromError('Unable to reconnect DB',Connection);
        end else
          raise ESQLQueryException.CreateFromError('DB Error',Connection);
      finally
        if fPrepared=nil then
          Connection.InternalProcess(speConnectionLost);
      end;
    for i := 0 to col-1 do
      try
        with fParams[cols[i]] do // the leftmost SQL parameter has an index of 1
          fPrepared.BindVariant(i+1,fValue,fValueBlob,DB2OLE[fParamType]);
      except
        on E: Exception do
          raise ESQLQueryException.CreateFmt(
            'Error "%s" at binding value for parameter "%s" in "%s"',
            [E.Message,fParams[cols[i]].fName,req]);
      end;
    fPrepared.ExecutePrepared;
  finally
    Connection.InternalProcess(speNonActive);
  end;
end;

{$endif EMULATES_TQUERY}


{ TSQLDBConnection }

procedure TSQLDBConnection.CheckConnection;
begin
  if self=nil then
    raise ESQLDBException.Create('TSQLDBConnection not created');
  if not Connected then
    raise ESQLDBException.CreateFmt('%s on %s/%s should be connected',
      [ClassName,Properties.ServerName,Properties.DataBaseName]);
end;

procedure TSQLDBConnection.InternalProcess(Event: TOnSQLDBProcessEvent);
begin
  if (self=nil) or not Assigned(OnProcess) then
    exit;
  case Event of
  speActive: begin
    if fInternalProcessActive=0 then
      OnProcess(self,Event);
    inc(fInternalProcessActive);
  end;
  speNonActive: begin
    dec(fInternalProcessActive);
    if fInternalProcessActive=0 then
      OnProcess(self,Event);
  end;
  else
    OnProcess(self,Event);
  end;
end;

procedure TSQLDBConnection.Commit;
begin
  CheckConnection;
  if TransactionCount<=0 then
    raise ESQLDBException.CreateFmt('Invalid %s.Commit call',[ClassName]);
  dec(fTransactionCount);
end;

constructor TSQLDBConnection.Create(aProperties: TSQLDBConnectionProperties);
begin
  fProperties := aProperties;
  if aProperties<>nil then begin
    fOnProcess := aProperties.OnProcess;
    fRollbackOnDisconnect := aProperties.RollbackOnDisconnect;
  end;
end;

procedure TSQLDBConnection.Connect;
begin
  inc(fTotalConnectionCount);
  if fTotalConnectionCount>1 then
    InternalProcess(speReconnected);
end;

procedure TSQLDBConnection.Disconnect;
var i: integer;
    Obj: PPointerArray;
begin
  if fCache<>nil then begin
    InternalProcess(speActive);
    try
      Obj := fCache.ObjectPtr;
      if Obj<>nil then
        for i := 0 to fCache.Count-1 do
          TSQLDBStatement(Obj[i]).FRefCount := 0; // force clean release
      FreeAndNil(fCache); // release all cached statements
    finally
      InternalProcess(speNonActive);
    end;
  end;
  if InTransaction then
    try
      if RollbackOnDisconnect then begin
        fTransactionCount := 1; // flush transaction nesting level
        Rollback;
      end;
    finally
      fTransactionCount := 0; // flush transaction nesting level
    end;
end;

destructor TSQLDBConnection.Destroy;
begin
  try
    Disconnect;
  except
    on E: Exception do
      SynDBLog.Add.Log(sllError,E);
  end;
  inherited;
end;

function TSQLDBConnection.GetInTransaction: boolean;
begin
  result := TransactionCount>0;
end;

function TSQLDBConnection.GetServerTimeStamp: TTimeLog;
// - since TTimeLog type is bit-oriented, you can't just use add or substract
// two TTimeLog values when doing such date/time computation: use temp TDateTime
var Current: TDateTime;
begin
  Current := Now;
  if (fServerTimeStampOffset=0) and
     (fProperties.fSQLGetServerTimeStamp<>'') then begin
    with fProperties do
      with Execute(fSQLGetServerTimeStamp,[]) do
        if Step then
        fServerTimeStampOffset := ColumnDateTime(0)-Current;
    if fServerTimeStampOffset=0 then
      fServerTimeStampOffset := 0.0001; // request server only once
  end;
  PTimeLogBits(@result)^.From(Current+fServerTimeStampOffset);
end;

function TSQLDBConnection.GetLastErrorWasAboutConnection: boolean;
begin
  result := (self<>nil) and (Properties<>nil) and
    Properties.ExceptionIsAboutConnection(fErrorException,fErrorMessage); 
end;

function TSQLDBConnection.NewStatementPrepared(const aSQL: RawUTF8;
  ExpectResults: Boolean; RaiseExceptionOnError: Boolean=false): ISQLDBStatement;
var Stmt: TSQLDBStatement;
    ToCache: boolean;
    ndx: integer;
begin
  fErrorMessage := '';
  if length(aSQL)<5 then begin
    result := nil;
    exit;
  end;
  ToCache := fProperties.IsCachable(Pointer(aSQL));
  if ToCache and (fCache<>nil) then begin
    ndx := fCache.IndexOf(aSQL);
    if ndx>=0 then begin
      Stmt := fCache.Objects[ndx] as TSQLDBStatement;
      Stmt.Reset;
      result := Stmt;
      exit;
    end;
  end;
  // default implementation with no cache
  Stmt := nil;
  try
    InternalProcess(speActive);
    try
      Stmt := NewStatement;
      Stmt.Prepare(aSQL,ExpectResults);
      if ToCache then begin
        if fCache=nil then
          fCache := TRawUTF8ListHashed.Create(true);
        fCache.AddObject(aSQL,Stmt);
        Stmt._AddRef;
      end;
      result := Stmt;
    finally
      InternalProcess(speNonActive);
    end;
  except
    on E: Exception do begin
      Stmt.Free;
      if RaiseExceptionOnError then
        raise;
      StringToUTF8(E.Message,fErrorMessage);
      fErrorException := PPointer(E)^;
      result := nil;
    end;
  end;
end;  

procedure TSQLDBConnection.Rollback;
begin
  CheckConnection;
  if TransactionCount<=0 then
    raise ESQLDBException.CreateFmt('Invalid %s.Rollback call',[ClassName]);
  dec(fTransactionCount);
end;

procedure TSQLDBConnection.StartTransaction;
begin
  CheckConnection;
  inc(fTransactionCount);
end;

function TSQLDBConnection.NewTableFromRows(const TableName: RawUTF8;
  Rows: TSQLDBStatement; WithinTransaction: boolean): integer;
var Fields: TSQLDBColumnPropertyDynArray;
    aTableName, SQL: RawUTF8;
    Tables: TRawUTF8DynArray;
    Ins: TSQLDBStatement;
begin
  result := 0;
  if (self=nil) or (Rows=nil) or (Rows.ColumnCount=0) then
    exit;
  aTableName := Properties.SQLTableName(TableName);
  if WithinTransaction then
    StartTransaction; // MUCH faster within a transaction
  try
    Ins := nil;
   InternalProcess(speActive);
    try
      while Rows.Step do begin
        // init when first row of data is available
        if Ins=nil then begin
          SQL := Rows.ColumnsToSQLInsert(aTableName,Fields);
          Properties.GetTableNames(Tables);
          if FindRawUTF8(Tables,TableName,false)<0 then
            with Properties do
              ExecuteNoResult(SQLCreate(aTableName,Fields,false),[]);
          Ins := NewStatement;
          Ins.Prepare(SQL,false);
        end;
        // write row data
        Ins.BindFromRows(Fields,Rows);
        Ins.ExecutePrepared;
        Ins.Reset;
        inc(result);
      end;
      if WithinTransaction then
        Commit;
    finally
      Ins.Free;
      InternalProcess(speNonActive);
    end;
  except
    on Exception do begin
      if WithinTransaction then
        Rollback;
      raise;
    end;
  end;
end;


{ TSQLDBConnectionProperties }

constructor TSQLDBConnectionProperties.Create(const aServerName, aDatabaseName,
  aUserID, aPassWord: RawUTF8);
var aDBMS: TSQLDBDefinition;
begin
  fServerName := aServerName;
  fDatabaseName := aDatabaseName;
  fUserID := aUserID;
  fPassWord := aPassWord;
  fEngineName := EngineName;
  fUseCache := true;
  SetInternalProperties; // virtual method used to override default parameters
  aDBMS := DBMS;
  if fForcedSchemaName='' then
    case aDBMS of // should make every one life's easier
    dMSSQL:      fForcedSchemaName := 'dbo';
    dPostgreSql: fForcedSchemaName := 'public';
    end;
  if fSQLCreateField[ftUnknown]='' then
    fSQLCreateField := DB_FIELDS[aDBMS];
  if fSQLCreateFieldMax=0 then
    fSQLCreateFieldMax := DB_FIELDSMAX[aDBMS];
  if fSQLGetServerTimeStamp='' then
    fSQLGetServerTimeStamp := DB_SERVERTIME[aDBMS];
  case aDBMS of
  dMSSQL, dJet: fStoreVoidStringAsNull := true;
  end;
  if byte(fBatchSendingAbilities)=0 then // if not already handled by driver
    case aDBMS of
    dSQlite,dMySQL,dPostgreSQL,dNexusDB,dMSSQL,dDB2, // INSERT with multi VALUES
    //dFirebird,  EXECUTE BLOCK with params is slower (at least for embedded)
    dOracle: begin // Oracle expects weird INSERT ALL INTO ... statement
      fBatchSendingAbilities := [cCreate];
      fOnBatchInsert := MultipleValuesInsert;
      fBatchMaxSentAtOnce := 4096; // MultipleValuesInsert will do chunking
    end;
    dFirebird: begin // will run EXECUTE BLOCK without parameters
      fBatchSendingAbilities := [cCreate];
      fOnBatchInsert := MultipleValuesInsertFirebird;
      fBatchMaxSentAtOnce := 4096; // MultipleValuesInsert will do chunking
    end;
    end;
end;

destructor TSQLDBConnectionProperties.Destroy;
begin
  fMainConnection.Free;
  inherited;
end;

function TSQLDBConnectionProperties.Execute(const aSQL: RawUTF8;
  const Params: array of const
  {$ifndef LVCL}{$ifndef DELPHI5OROLDER}; RowsVariant: PVariant=nil{$endif}{$endif}): ISQLDBRows;
var Stmt: ISQLDBStatement;
begin
  Stmt := NewThreadSafeStatementPrepared(aSQL,true,true);
  Stmt.Bind(Params);
  Stmt.ExecutePrepared;
  result := Stmt;
  {$ifndef LVCL}
  {$ifndef DELPHI5OROLDER}
  if RowsVariant<>nil then
    if result=nil then
      SetVariantNull(RowsVariant^) else
      RowsVariant^ := result.RowData;
  {$endif}
  {$endif}
end;

function TSQLDBConnectionProperties.ExecuteNoResult(const aSQL: RawUTF8;
  const Params: array of const): integer;
var Stmt: ISQLDBStatement;
begin
  Stmt := NewThreadSafeStatementPrepared(aSQL,false,true);
  Stmt.Bind(Params);
  Stmt.ExecutePrepared;
  try
    result := Stmt.UpdateCount;
  except // may occur e.g. for Firebird's CREATE DATABASE
    result := 0;
  end;
end;

function TSQLDBConnectionProperties.PrepareInlined(const aSQL: RawUTF8; ExpectResults: Boolean): ISQLDBStatement;
var Query: ISQLDBStatement;
    i, maxParam: integer;
    Types: TSQLParamTypeDynArray; 
    Nulls: TSQLFieldBits;
    Values: TRawUTF8DynArray;
    GenericSQL: RawUTF8;
begin                               
  result := nil; // returns nil interface on error
  if self=nil then
    exit;
  // convert inlined :(1234): parameters into Values[] for Bind*() calls
  GenericSQL := ExtractInlineParameters(aSQL,Types,Values,maxParam,Nulls);
  Query := NewThreadSafeStatementPrepared(GenericSQL,ExpectResults,true);
  if Query=nil then
    exit;
  for i := 0 to maxParam-1 do
  if i in Nulls then
    Query.BindNull(i+1) else
    case Types[i] of // returned sftInteger,sftFloat,sftUTF8Text,sftBlob,sftUnknown
      sptInteger:  Query.Bind(i+1,GetInt64(pointer(Values[i])));
      sptFloat:    Query.Bind(i+1,GetExtended(pointer(Values[i])));
      sptText:     Query.BindTextU(i+1,Values[i]);
      sptBlob:     if Values[i]='' then
                     Query.BindNull(i+1) else
                     Query.BindBlob(i+1,pointer(Values[i]),length(Values[i]));
      sptDateTime: Query.BindDateTime(i+1,Iso8601ToDateTime(Values[i]));
      else raise ESQLDBException.CreateFmt('Unrecognized parameter Type[%d] in "%s"',
        [i+1,UTF8ToString(aSQL)]);
    end;
  result := Query;
end;

function TSQLDBConnectionProperties.PrepareInlined(SQLFormat: PUTF8Char; const Args: array of const; ExpectResults: Boolean): ISQLDBStatement;
begin
  result := PrepareInlined(FormatUTF8(SQLFormat,Args),ExpectResults);
end;

function TSQLDBConnectionProperties.ExecuteInlined(const aSQL: RawUTF8; ExpectResults: Boolean): ISQLDBRows;
var Query: ISQLDBStatement;
begin
  result := nil; // returns nil interface on error
  if self=nil then
    exit;
  Query := PrepareInlined(aSQL,ExpectResults);
  Query.ExecutePrepared;
  result := Query;
end;

function TSQLDBConnectionProperties.ExecuteInlined(SQLFormat: PUTF8Char; const Args: array of const; ExpectResults: Boolean): ISQLDBRows;
begin
  result := ExecuteInlined(FormatUTF8(SQLFormat,Args),ExpectResults);
end;

function TSQLDBConnectionProperties.GetMainConnection: TSQLDBConnection;
begin
  if self=nil then
    result := nil else begin
    if fMainConnection=nil then
      fMainConnection := NewConnection;
    result := fMainConnection;
  end;
end;

function TSQLDBConnectionProperties.ThreadSafeConnection: TSQLDBConnection;
begin
  result := MainConnection; // provider should be thread-safe
end;

procedure TSQLDBConnectionProperties.ClearConnectionPool;
begin
  FreeAndNil(fMainConnection);
end;

function TSQLDBConnectionProperties.NewThreadSafeStatement: TSQLDBStatement;
begin
  result := ThreadSafeConnection.NewStatement;
end;

function TSQLDBConnectionProperties.NewThreadSafeStatementPrepared(
  const aSQL: RawUTF8; ExpectResults: Boolean; RaiseExceptionOnError: Boolean=false): ISQLDBStatement;
begin
  result := ThreadSafeConnection.NewStatementPrepared(aSQL,ExpectResults,RaiseExceptionOnError);
end;

function TSQLDBConnectionProperties.NewThreadSafeStatementPrepared(
  SQLFormat: PUTF8Char; const Args: array of const; ExpectResults: Boolean): ISQLDBStatement;
begin
  result := NewThreadSafeStatementPrepared(FormatUTF8(SQLFormat,Args),ExpectResults);
end;

procedure TSQLDBConnectionProperties.SetInternalProperties;
begin
  // nothing to do yet
end;

function TSQLDBConnectionProperties.IsCachable(P: PUTF8Char): boolean;
var NoWhere: Boolean;
begin // cachable if with ? parameter or SELECT without WHERE clause
  if (P<>nil) and fUseCache then begin
    while P^ in [#1..' '] do inc(P);
    NoWhere := IdemPChar(P,'SELECT ');
    if NoWhere or not (IdemPChar(P,'CREATE ') or IdemPChar(P,'ALTER ')) then begin
      result := true;
      while P^<>#0 do begin
        if P^='"' then begin // ignore chars within quotes
          repeat inc(P) until P^ in [#0,'"'];
          if P^=#0 then break;
        end else
        if P^='?' then
          exit else
        if (P^=' ') and IdemPChar(P+1,'WHERE ') then
          NoWhere := false;
        inc(P);
      end;
    end;
    result := NoWhere;
  end else
    result := false;
end;

class function TSQLDBConnectionProperties.GetFieldDefinition(
  const Column: TSQLDBColumnDefine): RawUTF8;
const EXE_FMT1: PUTF8Char = '% [%'; // for Delphi 5
      EXE_FMT2: PUTF8Char = '% % % %]';
begin
  with Column do begin
    result := FormatUTF8(EXE_FMT1,[ColumnName,ColumnTypeNative]);
    if (ColumnLength<>0) or (Column.ColumnPrecision<>0) or (Column.ColumnScale<>0) then
      result := FormatUTF8(EXE_FMT2,[result,ColumnLength,ColumnPrecision,ColumnScale]) else
      result := result+']';
    if ColumnIndexed then
      result := result+' *';
  end;
end;

class function TSQLDBConnectionProperties.GetFieldORMDefinition(
  const Column: TSQLDBColumnDefine): RawUTF8;
const EXE_FMT1: PUTF8Char = 'property %: %';
      EXE_FMT2: PUTF8Char = '% index %';
      EXE_FMT3: PUTF8Char = '% read f% write f%;';
begin // 'Name: RawUTF8 index 20 read fName write fName;';
  with Column do begin
    result := FormatUTF8(EXE_FMT1,
      [ColumnName,SQLDBFIELDTYPE_TO_DELPHITYPE[ColumnType]]);
    if (ColumnType=ftUTF8) and (ColumnLength>0) then
      result := FormatUTF8(EXE_FMT2,[result,ColumnLength]);
    result := FormatUTF8(EXE_FMT3,[result,ColumnName,ColumnName]);
  end;
end;  

procedure TSQLDBConnectionProperties.GetFieldDefinitions(const aTableName: RawUTF8;
  var Fields: TRawUTF8DynArray; WithForeignKeys: boolean);
var F: TSQLDBColumnDefineDynArray;
    Ref: RawUTF8;
    i: integer;
begin
  GetFields(aTableName,F);
  SetLength(Fields,length(F));
  for i := 0 to high(F) do begin
    Fields[i] := GetFieldDefinition(F[i]);
    if WithForeignKeys then begin
      Ref := GetForeignKey(aTableName,F[i].ColumnName);
      if Ref<>'' then
        Fields[i] := Fields[i] +' % '+Ref;
    end;
  end;
end;

procedure TSQLDBConnectionProperties.GetFields(const aTableName: RawUTF8;
  var Fields: TSQLDBColumnDefineDynArray);
var SQL: RawUTF8;
    n,i: integer;
    F: TSQLDBColumnDefine;
    FA: TDynArray;
begin
  SetLength(Fields,0);
  FA.Init(TypeInfo(TSQLDBColumnDefineDynArray),Fields,@n);
  FA.Compare := SortDynArrayAnsiStringI; // FA.Find() case insensitive
  fillchar(F,sizeof(F),0);
  if fDBMS=dSQLite then begin // SQLite3 has a specific PRAGMA metadata query
    try
      with Execute('PRAGMA table_info(`'+aTableName+'`)',[]) do
      while Step do begin
        // cid,name,type,notnull,dflt_value,pk
        F.ColumnName := ColumnUTF8(1);
        F.ColumnTypeNative := ColumnUTF8(2);
        F.ColumnType := ColumnTypeNativeToDB(F.ColumnTypeNative,0);
        F.ColumnIndexed := IsRowID(pointer(F.ColumnName)); // by definition for SQLite3
        FA.Add(F);
      end;
    except
      on Exception do
        n := 0; // external SQLite3 providers (e.g. UniDAC) are buggy
    end;
    try
      with Execute('PRAGMA index_list(`'+aTableName+'`)',[]) do
      while Step do
        // seq,name,unique
        with Execute('PRAGMA index_info('+ColumnUTF8(1)+')',[]) do
          while Step do begin
            F.ColumnName := ColumnUTF8(2); // seqno,cid,name
            i := FA.Find(F);
            if i>=0 then
              Fields[i].ColumnIndexed := true;
          end;
    except
      on Exception do
        ; // ignore any exception if no index is defined
    end;
  end else begin
    SQL := SQLGetField(aTableName);
    if SQL='' then
      exit;
    with Execute(SQL,[]) do
      while Step do begin
        F.ColumnName := trim(ColumnUTF8(0));
        F.ColumnTypeNative := trim(ColumnUTF8(1));
        F.ColumnLength := ColumnInt(2);
        F.ColumnPrecision := ColumnInt(3);
        F.ColumnScale := ColumnInt(4);
        F.ColumnType := ColumnTypeNativeToDB(F.ColumnTypeNative,F.ColumnScale);
        if ColumnInt(5)>0 then
          F.ColumnIndexed := true;
        FA.Add(F);
      end;
  end;
  SetLength(Fields,n);
end;

procedure TSQLDBConnectionProperties.GetIndexes(const aTableName: RawUTF8;
  var Indexes: TSQLDBIndexDefineDynArray);
var SQL: RawUTF8;
    n: integer;
    F: TSQLDBIndexDefine;
    FA: TDynArray;
begin
  SQL := SQLGetIndex(aTableName);
  SetLength(Indexes,0);
  if SQL='' then
    exit;
  FA.Init(TypeInfo(TSQLDBIndexDefineDynArray),Indexes,@n);
  with Execute(SQL,[]) do
    while Step do begin
      F.IndexName          := trim(ColumnUTF8(0));
      F.IsUnique           := ColumnInt (1)>0;
      F.TypeDesc           := trim(ColumnUTF8(2));
      F.IsPrimaryKey       := ColumnInt (3)>0;
      F.IsUniqueConstraint := ColumnInt (4)>0;
      F.Filter             := trim(ColumnUTF8(5));
      F.KeyColumns         := trim(ColumnUTF8(6));
      F.IncludedColumns    := trim(ColumnUTF8(7));
      FA.Add(F);
    end;
  SetLength(Indexes,n);
end;

procedure TSQLDBConnectionProperties.GetTableNames(var Tables: TRawUTF8DynArray);
var SQL: RawUTF8;
    count: integer;
begin
  SetLength(Tables,0);
  SQL := SQLGetTableNames;
  if SQL<>'' then
  try
    with Execute(SQL,[]) do begin
      count := 0;
      while Step do
        AddSortedRawUTF8(Tables,count,trim(ColumnUTF8(0)));
      SetLength(Tables,count);
    end;
  except
    on Exception do
      SetLength(Tables,0); // if the supplied SQL query is wrong, just ignore
  end;
end;

procedure TSQLDBConnectionProperties.SQLSplitTableName(const aTableName: RawUTF8;
  out Owner, Table: RawUTF8);
begin
  case fDBMS of
  dSQLite:
    Table := aTableName;
  else begin
    Split(aTableName,'.',Owner,Table);
    if Table='' then begin
      Table := Owner;
      if fForcedSchemaName='' then
        case fDBMS of
        dMySql:
          Owner := DatabaseName;
        else
          Owner := UserID;
        end else
        Owner := fForcedSchemaName;
    end;
  end;
  end;
end;

function TSQLDBConnectionProperties.SQLFullTableName(const aTableName: RawUTF8): RawUTF8;
begin
  if (aTableName<>'') and (fForcedSchemaName<>'') and (PosEx('.',aTableName)=0) then
    result := fForcedSchemaName+'.'+aTableName else
    result := aTableName;
end;

function TSQLDBConnectionProperties.SQLGetField(const aTableName: RawUTF8): RawUTF8;
var Owner, Table: RawUTF8;
    FMT: PUTF8Char;
begin
  result := '';
  case DBMS of
  dOracle: FMT :=
    'select c.column_name, c.data_type, c.data_length, c.data_precision, c.data_scale, '+
    ' (select count(*) from sys.all_indexes a, sys.all_ind_columns b'+
    '  where a.table_owner=c.owner and a.table_name=c.table_name and b.column_name=c.column_name'+
    '  and a.owner=b.index_owner and a.index_name=b.index_name and'+
    '  a.table_owner=b.table_owner and a.table_name=b.table_name) index_count'+
    ' from sys.all_tab_columns c'+
    ' where c.owner like ''%'' and c.table_name like ''%'';';
  dMSSQL, dMySQL, dPostgreSQL: FMT :=
    'select COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION,'+
    ' NUMERIC_SCALE, 0 INDEX_COUNT'+ // INDEX_COUNT=0 here (done via OleDB)
    ' from INFORMATION_SCHEMA.COLUMNS'+
    ' where UPPER(TABLE_SCHEMA) = ''%'' and UPPER(TABLE_NAME) = ''%''';
  dFirebird: begin
    result := // see http://edn.embarcadero.com/article/25259
      'select a.rdb$field_name, b.rdb$field_type || coalesce(b.rdb$field_sub_type, '''') as rdb$field_type,'+
      ' b.rdb$field_length, b.rdb$field_length, abs(b.rdb$field_scale) as rdb$field_scale,'+
      ' (select count(*) from rdb$indices i, rdb$index_segments s'+
      ' where i.rdb$index_name=s.rdb$index_name and i.rdb$index_name not like ''RDB$%'''+
      ' and i.rdb$relation_name=a.rdb$relation_name) as index_count '+
      'from rdb$relation_fields a left join rdb$fields b on a.rdb$field_source=b.rdb$field_name'+
      ' left join rdb$relations c on a.rdb$relation_name=c.rdb$relation_name '+
      'where a.rdb$relation_name='''+SynCommons.UpperCase(aTableName)+'''';
    exit;
  end;
  dNexusDB: begin
    result := 'select FIELD_NAME, FIELD_TYPE_SQL, FIELD_LENGTH, FIELD_UNITS,'+
    ' FIELD_DECIMALS, FIELD_INDEX from #fields where TABLE_NAME = '''+aTableName+'''';
    exit;
  end;
  else exit; // others (e.g. dDB2) will retrieve info from (ODBC) driver 
  end;
  SQLSplitTableName(aTableName,Owner,Table);
  result := FormatUTF8(FMT,[SynCommons.UpperCase(Owner),SynCommons.UpperCase(Table)]);
end;

function TSQLDBConnectionProperties.SQLGetIndex(const aTableName: RawUTF8): RawUTF8;
var Owner, Table: RawUTF8;
    FMT: PUTF8Char;
begin
  result := '';
  case DBMS of
  dOracle: FMT :=
   'select  index_name, decode(max(uniqueness),''NONUNIQUE'',0,1) as is_unique, '+
   ' max(index_type) as type_desc, 0 as is_primary_key, 0 as unique_constraint, '+
   ' cast(null as varchar(100)) as index_filter, '+
   ' ltrim(max(sys_connect_by_path(column_name, '', '')), '', '') as key_columns, '+
   ' cast(null as varchar(100)) as included_columns '+
   'from '+
   '( select c.index_name as index_name, i.index_type, i.uniqueness, c.column_name, '+
   '   row_number() over (partition by c.table_name, c.index_name order by c.column_position) as rn '+
   '  from user_ind_columns c inner join user_indexes i on c.table_name = i.table_name and c.index_name = i.index_name '+
   '  where c.table_name = ''%'' '+
   ') start with rn = 1 connect by prior rn = rn - 1 and prior index_name = index_name '+
   'group by index_name order by index_name';
  dMSSQL: FMT :=
    'select i.name as index_name, i.is_unique, i.type_desc, is_primary_key, is_unique_constraint, '+
    '  i.filter_definition as index_filter, key_columns, included_columns as included_columns, '+
    '  t.name as table_name '+
    'from '+
    ' sys.tables t inner join sys.indexes i on i.object_id = t.object_id '+
    ' cross apply(select STUFF('+
    '   (select '',''+c.name from sys.index_columns ic '+
    '   inner join sys.columns c on c.object_id = t.object_id and c.column_id = ic.column_id '+
    '   where i.index_id = ic.index_id and i.object_id = ic.object_id and ic.is_included_column = 0 '+
    '   order by ic.key_ordinal for xml path('''') '+
    '   ),1,1,'''') as key_columns) AS c '+
    ' cross apply(select STUFF( '+
    '   (select '','' + c.name  from sys.index_columns ic '+
    '   inner join	sys.columns c on	c.object_id = t.object_id	and c.column_id = ic.column_id '+
    '   where i.index_id = ic.index_id and i.object_id = ic.object_id and ic.is_included_column = 1 '+
    '   order by ic.key_ordinal for xml path('''') '+
    '   ),1,1,'''') as included_columns) AS ic '+
    'where t.type = ''U'' and t.name like ''%''';
{  fFirebird: FMT :=
    'select RDB$Index_name, RDB$Unique_Flag, RDB$Index_Type,  from rdb$indices i where i.rdb$relation_name like ''%'''; }
  else exit; // others (e.g. dDB2) will retrieve info from (ODBC) driver
  end;
  Split(aTableName,'.',Owner,Table);
  if Table='' then begin
    Table := Owner;
    Owner := UserID;
  end;
  result := FormatUTF8(FMT, [SynCommons.UpperCase(Table)]);
end;

function TSQLDBConnectionProperties.SQLGetTableNames: RawUTF8;
begin
  case DBMS of
  dOracle: result := 'select owner||''.''||table_name name '+
    'from sys.all_tables order by owner, table_name';
  dMSSQL:
    result := 'select (TABLE_SCHEMA + ''.'' + TABLE_NAME) as name '+
      'from INFORMATION_SCHEMA.TABLES where TABLE_TYPE=''BASE TABLE'' order by name';
  dMySQL:
    result := 'select concact(TABLE_SCHEMA,''.'',TABLE_NAME) as name '+
      'from INFORMATION_SCHEMA.TABLES where TABLE_TYPE=''BASE TABLE'' order by name';
  dPostgreSQL:
    result := 'select (TABLE_SCHEMA||''.''||TABLE_NAME) as name '+
      'from INFORMATION_SCHEMA.TABLES where TABLE_TYPE=''BASE TABLE'' order by name';
  dSQLite: result := 'select name from sqlite_master where type=''table'' '+
     'and name not like ''sqlite_%''';
  dFirebird: result := 'select rdb$relation_name from rdb$relations '+
    'where rdb$view_blr is null and (rdb$system_flag is null or rdb$system_flag=0)';
  dNexusDB: result := 'select table_name name from #tables order by table_name';
  else result := ''; // others (e.g. dDB2) will retrieve info from (ODBC) driver
  end;
end;

function TSQLDBConnectionProperties.SQLCreateDatabase(const aDatabaseName: RawUTF8;
  aDefaultPageSize: integer): RawUTF8;
const SQL_FMT1: PUTF8Char = // for Delphi 5
      'create database ''%'' user ''sysdba'' password ''masterkey'''+
      ' page_size % default character set utf8;';
begin
  case DBMS of
  dFirebird: begin
    if (aDefaultPageSize<>8192) or (aDefaultPageSize<>16384) then
      aDefaultPageSize := 4096;
    result := FormatUTF8(SQL_FMT1,[aDatabaseName,aDefaultPageSize]);
  end;
  else result := '';
  end;
end;

function TSQLDBConnectionProperties.ColumnTypeNativeToDB(
  const aNativeType: RawUTF8; aScale: integer): TSQLDBFieldType;
procedure ColumnTypeNativeDefault;
const
  DECIMAL=18; // change it if you update PCHARS[] below before 'DECIMAL'
  NUMERIC=DECIMAL+1;
  PCHARS: array[0..55] of PAnsiChar = (
    'TEXT COLLATE ISO8601',
    'TEXT','CHAR','NCHAR','VARCHAR','NVARCHAR','CLOB','NCLOB','DBCLOB',
    'BIT','INT','BIGINT', 'DOUBLE','NUMBER','FLOAT','REAL','DECFLOAT',
    'CURR','DECIMAL','NUMERIC', 'BLOB SUB_TYPE 1',  'BLOB',
    'DATE','SMALLDATE','TIME',
    'TINYINT','BOOL','SMALLINT','MEDIUMINT','SERIAL','YEAR',
    'TINYTEXT','MEDIUMTEXT','NTEXT','XML','ENUM','SET','UNIQUEIDENTIFIER',
    'MONEY','SMALLMONEY','NUM',
    'VARRAW','RAW','LONG RAW','LONG VARRAW','TINYBLOB','MEDIUMBLOB',
    'BYTEA','VARBIN','IMAGE','LONGBLOB','BINARY','VARBINARY',
    'GRAPHIC','VARGRAPHIC', 'NULL');
  TYPES: array[-1..high(PCHARS)] of TSQLDBFieldType = (
    ftUnknown, ftDate,
    ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,
    ftInt64,ftInt64,ftInt64, ftDouble,ftDouble,ftDouble,ftDouble,ftDouble,
    ftCurrency,ftCurrency,ftCurrency, ftUTF8, ftBlob,
    ftDate,ftDate,ftDate,
    ftInt64,ftInt64,ftInt64,ftInt64,ftInt64,ftInt64,
    ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,ftUTF8,
    ftCurrency,ftCurrency,ftCurrency,
    ftBlob,ftBlob,ftBlob,ftBlob,ftBlob,ftBlob,ftBlob,ftBlob,
    ftBlob,ftBlob,ftBlob,ftBlob,ftBlob,ftBlob,
    ftNull);
var ndx: integer;
begin
  //assert(StrComp(PCHARS[DECIMAL],'DECIMAL')=0);
  ndx := IdemPCharArray(pointer(aNativeType),PCHARS);
  if (aScale=0) and (ndx in [DECIMAL,NUMERIC]) then
    result := ftInt64 else
    result := TYPES[ndx];
end;
procedure ColumnTypeNativeToDBOracle;
begin
  if PosEx('CHAR',aNativeType)>0 then
    result := ftUTF8 else
  if IdemPropNameU(aNativeType,'NUMBER') then
    case aScale of
         0: result := ftInt64;
      1..4: result := ftCurrency;
    else    result := ftDouble;
    end else
  if (PosEx('RAW',aNativeType)>0) or
     IdemPropNameU(aNativeType,'BLOB') or
     IdemPropNameU(aNativeType,'BFILE') then
    result := ftBlob else
  if IdemPChar(pointer(aNativeType),'BINARY_') or
     IdemPropNameU(aNativeType,'FLOAT') then
    result := ftDouble else
  if IdemPropNameU(aNativeType,'DATE') or
     IdemPChar(pointer(aNativeType),'TIMESTAMP') then
    result := ftDate else
    // all other types will be converted to text
    result := ftUTF8;
end;
procedure ColumnTypeNativeToDBFirebird;
var i,err: integer;
begin
  i := GetInteger(pointer(aNativeType),err);
  if err<>0 then
    ColumnTypeNativeDefault else
    case i of // see blr_* definitions
    10,11,27: result := ftDouble;
    12,13,35,120: result := ftDate;
    7,8,9,16,23,70,80,160: result := ftInt64;
    161..169: case abs(aScale) of
            0: result := ftInt64;
         1..4: result := ftCurrency;
         else  result := ftDouble;
         end;
    2610: result := ftBlob;
    else result := ftUTF8;
    end;
end;
begin
  case DBMS of
  dOracle:   ColumnTypeNativeToDBOracle;
  dFireBird: ColumnTypeNativeToDBFirebird;
  else       ColumnTypeNativeDefault;
  end;
end;

function TSQLDBConnectionProperties.GetForeignKey(const aTableName,
  aColumnName: RawUTF8): RawUTF8;
begin
  if not fForeignKeys.Initialized then begin
    fForeignKeys.Init(false);
    GetForeignKeys;
  end;
  result := fForeignKeys.Value(aTableName+'.'+aColumnName);
end;

function TSQLDBConnectionProperties.GetForeignKeysData: RawByteString;
begin
  if not fForeignKeys.Initialized then begin
    fForeignKeys.Init(false);
    GetForeignKeys;
  end;
  result := fForeignKeys.BlobData;
end;

procedure TSQLDBConnectionProperties.SetForeignKeysData(const Value: RawByteString);
begin
  if not fForeignKeys.Initialized then 
    fForeignKeys.Init(false);
  fForeignKeys.BlobData := Value;
end;

function TSQLDBConnectionProperties.SQLIso8601ToDate(const Iso8601: RawUTF8): RawUTF8;
function TrimTInIso: RawUTF8;
begin
  result := Iso8601;
  if (length(result)>10) and (result[11]='T') then
    result[11] := ' '; // 'T' -> ' '
end;
begin
  case DBMS of
  dSQLite: result := TrimTInIso;
  dOracle: result := OracleSQLIso8601ToDate(Iso8601);
  dNexusDB: result := 'DATE '+Iso8601;
  dDB2: result := 'TIMESTAMP '''+TrimTInIso+'''';
  else  result := ''''+Iso8601+'''';
  end;
end;

function TSQLDBConnectionProperties.SQLCreate(const aTableName: RawUTF8;
  const aFields: TSQLDBColumnPropertyDynArray; aAddID: boolean): RawUTF8;
var i: integer;
    F: RawUTF8;
    AddPrimaryKey: RawUTF8;
const EXE_FMT: PUTF8Char = 'CREATE TABLE % (ID % PRIMARY KEY, %)'; // Delphi 5
begin // use 'ID' instead of 'RowID' here since some DB (e.g. Oracle) use it
  result := '';
  if high(aFields)<0 then
    exit; // nothing to create
  for i := 0 to high(aFields) do begin
    if (not aAddID) and (aFields[i].ColumnType=ftUnknown) then begin
      F := aFields[i].ColumnName+' '+fSQLCreateField[ftUnknown]+' NOT NULL';
      case DBMS of
      dSQLite, dMSSQL, dOracle, dJet, dPostgreSQL, dFirebird, dNexusDB:
        F := F+' PRIMARY KEY';
      dDB2, dMySQL:
        AddPrimaryKey := aFields[i].ColumnName;
      end;
    end else
      F := SQLFieldCreate(aFields[i]);
    if i<>high(aFields) then
      F := F+',';
    result := result+F;
  end;
  if AddPrimaryKey<>'' then
    result := result+', PRIMARY KEY('+AddPrimaryKey+')';
  if not aAddID then
    result := 'CREATE TABLE '+aTableName+' ('+result+')' else
    // fSQLCreateField[ftUnknown] is the datatype for ID field
    result := FormatUTF8(EXE_FMT,[aTableName,fSQLCreateField[ftUnknown],result]);
  case DBMS of
  dDB2: result := result+' CCSID Unicode';
  end;
end;

function TSQLDBConnectionProperties.SQLFieldCreate(const aField: TSQLDBColumnProperty): RawUTF8;
begin
  if (aField.ColumnType=ftUTF8) and (aField.ColumnAttr-1<fSQLCreateFieldMax) then
    result := FormatUTF8(pointer(fSQLCreateField[ftNull]),[aField.ColumnAttr]) else
    result := fSQLCreateField[aField.ColumnType];
  if aField.ColumnNonNullable or aField.ColumnUnique then
    result := result+' NOT NULL';
  if aField.ColumnUnique then
    result := result+' UNIQUE'; // see http://www.w3schools.com/sql/sql_unique.asp 
  result := aField.ColumnName+result;
end;

function TSQLDBConnectionProperties.SQLAddColumn(const aTableName: RawUTF8;
  const aField: TSQLDBColumnProperty): RawUTF8;
const EXE_FMT: PUTF8Char = 'ALTER TABLE % ADD %'; // Delphi 5
begin
  result := FormatUTF8(EXE_FMT,[aTableName,SQLFieldCreate(aField)]);
end;

function TSQLDBConnectionProperties.SQLAddIndex(const aTableName: RawUTF8;
  const aFieldNames: array of RawUTF8; aUnique, aDescending: boolean;
  const aIndexName: RawUTF8): RawUTF8;
const CREATNDX: PUTF8Char = 'CREATE %INDEX %% ON %(%)'; // Delphi 5
  CREATNDXIFNE: array[boolean] of RawUTF8 = ('','IF NOT EXISTS ');
var IndexName,FieldsCSV, ColsDesc, Owner,Table: RawUTF8;
begin
  result := '';
  if (self=nil) or (aTableName='') or (high(aFieldNames)<0) then
    exit;
  if aUnique then
    result := 'UNIQUE ';
  if aIndexName='' then begin
    SQLSplitTableName(aTableName,Owner,Table);
    if (Owner<>'') and
       not (fDBMS in [dMSSQL,dPostgreSQL,dMySQL,dFirebird,dDB2]) then
      // some DB engines do not expect any schema in the index name
      IndexName := Owner+'.';
    FieldsCSV := RawUTF8ArrayToCSV(aFieldNames,'');
    if length(FieldsCSV)+length(Table)>27 then
      // sounds like if some DB limit the identifier length to 32 chars
      IndexName := IndexName+'INDEX'+
        CardinalToHex(crc32c(0,pointer(Table),length(Table)))+
        CardinalToHex(crc32c(0,pointer(FieldsCSV),length(FieldsCSV)))+
        CardinalToHex(GetTickCount64) else
      IndexName := IndexName+'NDX'+Table+FieldsCSV;
  end else
    IndexName := aIndexName;
  if aDescending then
    case DB_SQLDESENDINGINDEXPOS[DBMS] of
    posGlobalBefore:
      result := result+'DESC ';
    posWithColumn:
      ColsDesc := RawUTF8ArrayToCSV(aFieldNames,' DESC,')+' DESC';
    end;
  if ColsDesc='' then
    ColsDesc := RawUTF8ArrayToCSV(aFieldNames,',');
  result := FormatUTF8(CREATNDX,
    [result,CREATNDXIFNE[DBMS in DB_HANDLECREATEINDEXIFNOTEXISTS],
     IndexName,aTableName,ColsDesc]);
end;

function TSQLDBConnectionProperties.SQLTableName(const aTableName: RawUTF8): RawUTF8;
var BeginQuoteChar, EndQuoteChar: RawUTF8;
    UseQuote: boolean;
begin
  BeginQuoteChar := '"';
  EndQuoteChar := '"';
  UseQuote := PosEx(' ',aTableName)>0;
  case fDBMS of
    dPostgresql:
      if PosEx('.',aTablename)=0 then
        UseQuote := true; // quote if not schema.identifier format
    dMySQL: begin
      BeginQuoteChar := '`';  // backtick/grave accent
      EndQuoteChar := '`';
    end;
    dJet: begin  // note: dMSSQL may SET IDENTIFIER ON to use doublequotes
      BeginQuotechar := '[';
      EndQuoteChar := ']';
    end;
    dSQLite: begin
      if PosEx('.',aTableName)>0 then
        UseQuote := true;
      BeginQuoteChar := '`';  // backtick/grave accent
      EndQuoteChar := '`';
    end;
  end;
  if UseQuote and (PosEx(BeginQuoteChar,aTableName)=0) then
    result := BeginQuoteChar+aTableName+EndQuoteChar else
    result := aTableName;
end;

procedure TSQLDBConnectionProperties.GetIndexesAndSetFieldsColumnIndexed(
  const aTableName: RawUTF8; var Fields: TSQLDBColumnDefineDynArray);
var i,j: integer;
    ColName: RawUTF8;
    Indexes: TSQLDBIndexDefineDynArray;
begin
  if Fields=nil then
    exit;
  GetIndexes(aTableName,Indexes);
  for i := 0 to high(Indexes) do begin
    ColName := Trim(GetCSVItem(pointer(Indexes[i].KeyColumns),0));
    if ColName<>'' then
    for j := 0 to high(Fields) do
      if IdemPropNameU(Fields[j].ColumnName,ColName) then begin
        Fields[j].ColumnIndexed := true;
        break;
      end;
  end;
end;

function TSQLDBConnectionProperties.ExceptionIsAboutConnection(
  aClass: ExceptClass; const aMessage: RawUTF8): boolean;
begin
  case fDBMS of
  dOracle:
    result := IdemPCharArray(pointer(aMessage),
      ['ORA-03113','ORA-03114','ORA-12154','ORA-12157',
       'ORA-12514','ORA-12537','TNS-12545'])>=0;
  else
    result := PosI(' CONNE',aMessage)>0;
  end;
end;

procedure TSQLDBConnectionProperties.MultipleValuesInsert(
  Props: TSQLDBConnectionProperties; const TableName: RawUTF8;
  const FieldNames: TRawUTF8DynArray; const FieldTypes: TSQLDBFieldTypeArray;
  RowCount: integer; const FieldValues: TRawUTF8DynArrayDynArray);
var SQL: RawUTF8;
    SQLCached: boolean;
    prevrowcount: integer;
    maxf: integer;
procedure ComputeSQL(rowcount,offset: integer);
var f,r,p,len: integer;
begin
  if (fDBMS<>dFireBird) and (rowcount=prevrowcount) then
    exit;
  prevrowcount := rowcount;
  with TTextWriter.CreateOwnedStream(8192) do
  try
    case Props.DBMS of
    dFirebird: begin
      AddShort('execute block('#10);
      p := 0;
      for r := offset to offset+rowcount-1 do begin
        for f := 0 to maxf do begin
          Add('i');
          inc(p);
          AddU(p);
          if FieldValues[f,r]='null' then
            AddShort(' CHAR(1)') else
            case FieldTypes[f] of
            ftNull: AddShort(' CHAR(1)');
            ftUTF8: begin
              len := length(FieldValues[f,r])-2; // unquoted UTF-8 text length
              if len<1 then
                len := 1;
              AddShort(' VARCHAR(');  // inlined Add(fmt...) for Delphi 5
              AddU(len);
              AddShort(') CHARACTER SET UTF8');
            end;
            else AddString(DB_FIELDS[dFirebird,FieldTypes[f]]);
            end;
          AddShort('=?,');
        end;
        CancelLastComma;
        Add(#10,',');
      end;
      CancelLastComma;
      AddShort(') as begin'#10);
      p := 0;
      for r := 1 to rowcount do begin
        AddShort('INSERT INTO ');
        AddString(TableName);
        Add(' ','(');
        for f := 0 to maxf do begin
          AddString(FieldNames[f]);
          Add(',');
        end;
        CancelLastComma;
        AddShort(') VALUES (');
        for f := 0 to maxf do begin
          inc(p);
          Add(':','i');
          AddU(p);
          Add(',');
        end;
        CancelLastComma;
        AddShort(');'#10);
      end;
      AddShort('end');
      if TextLength>32700 then
        raise ESQLDBException.CreateFmt('Execute Block length=%d',[TextLength]);
      SQLCached := false; // ftUTF8 values will have varying field length
    end;
    dOracle: begin // INSERT ALL INTO ... VALUES ... SELECT 1 FROM DUAL
      AddShort('insert all'#10); // see http://stackoverflow.com/a/93724/458259
      for r := 1 to rowcount do begin
        AddShort('into ');
        AddString(TableName);
        Add(' ','(');
        for f := 0 to maxf do begin
          AddString(FieldNames[f]);
          Add(',');
        end;
        CancelLastComma;
        AddShort(') VALUES (');
        for f := 0 to maxf do
          Add('?',',');
        CancelLastComma;
        AddShort(')'#10);
      end;
      AddShort('select 1 from dual');
      SQLCached := true; 
    end;
    else begin //  e.g. NexusDB/SQlite3/MySQL/PostgreSQL/MSSQL2008/DB2
      AddShort('INSERT INTO '); // INSERT .. VALUES (..),(..),(..),..
      AddString(TableName);
      Add(' ','(');
      for f := 0 to maxf do begin
        AddString(FieldNames[f]);
        Add(',');
      end;
      CancelLastComma;
      AddShort(') VALUES');
      for r := 1 to rowcount do begin
        Add(' ','(');
        for f := 0 to maxf do
          Add('?',',');
        CancelLastComma;
        Add(')',',');
      end;
      CancelLastComma;
      SQLCached := true;
    end;
    end;
    SetText(SQL);
  finally
    Free;
  end;
end;
var batchRowCount,paramCountLimit: integer;
    currentRow,f,p,i,sqllen: integer;
    Stmt: TSQLDBStatement;
    Query: ISQLDBStatement;
begin
  maxf := length(FieldNames);     // e.g. 2 fields
  if (Props=nil) or (FieldNames=nil) or (TableName='') or (length(FieldValues)<>maxf) then
    raise ESQLDBException.CreateFmt('Invalid %s.MultipleValuesInsert(%s) call',
      [ClassName,TableName]);
  batchRowCount := 0;
  paramCountLimit := 0;
  case Props.DBMS of
  // values below were done empirically, assuring < 667 (maximum :AA..:ZZ)
  // see http://stackoverflow.com/a/6582902/458259 for theoritical high limits
  dSQlite:     paramCountLimit := 200;  // theoritical=999
  dMySQL:      paramCountLimit := 500;  // theoritical=60000
  dPostgreSQL: paramCountLimit := 500;  // theoritical=34000
  dOracle:     paramCountLimit := 500;  // empirical value (from ODBC)
  dMSSQL:      paramCountLimit := 500;  // theoritical=2100
  dDB2:        paramCountLimit := 500;  // empirical value (from ODBC)
  dNexusDB:    paramCountLimit := 100;  // empirical limit (above is slower)
  dFirebird: begin // compute from max SQL statement size of 32KB
    sqllen := maxf*48; // worse case (with BLOB param)
    for f := 0 to maxf-1 do
      inc(sqllen,Length(FieldNames[f]));
    batchRowCount := 32000 div sqllen; 
    if batchRowCount>RowCount then
      batchRowCount := RowCount;
  end;
  end;
  if paramCountLimit<>0 then
    if RowCount*maxf>paramCountLimit then
      batchRowCount := paramCountLimit div maxf else
      batchRowCount := RowCount;
  if batchRowCount=0 then
    raise ESQLDBException.CreateFmt('%s.MultipleValuesInsert(%s) with # params = %d > %d',
      [ClassName,TableName,RowCount*maxf,paramCountLimit]);
  dec(maxf);
  prevrowcount := 0;
  SQLCached := false;
  currentRow := 0;
  repeat
    if RowCount-currentRow>batchRowCount then
      ComputeSQL(batchRowCount,currentRow) // low number of params may be re-used -> try cache
    else begin
      ComputeSQL(RowCount-currentRow,currentRow);
      SQLCached := false; // truncate number of parameters should not be unique
    end;
    if SQLCached then
      Query := Props.NewThreadSafeStatementPrepared(SQL,false) else begin
      Stmt := Props.NewThreadSafeStatement;
      try
        Stmt.Prepare(SQL,false);
        Query := Stmt;
      except
        on Exception do
          Stmt.Free; // avoid memory leak in case of invalid SQL statement
      end; // exception leaves Query=nil to raise exception
    end;
    if Query=nil then
      raise ESQLDBException.CreateFmt('%s.MultipleValuesInsert() Prepare(%s)',
        [ClassName,SQL]);
    try
      p := 1;
      for i := 1 to prevrowcount do begin
        for f := 0 to maxf do begin
          Query.Bind(p,FieldTypes[f],FieldValues[f,currentRow],false);
          inc(p);
        end;
        inc(currentRow);
      end;
      Query.ExecutePrepared;
    finally
      Query := nil;
    end;
  until currentRow=RowCount;
end;

procedure TSQLDBConnectionProperties.MultipleValuesInsertFirebird(
  Props: TSQLDBConnectionProperties; const TableName: RawUTF8;
  const FieldNames: TRawUTF8DynArray; const FieldTypes: TSQLDBFieldTypeArray;
  RowCount: integer; const FieldValues: TRawUTF8DynArrayDynArray);
var W: TTextWriter;
    maxf,sqllenwitoutvalues,sqllen,r,f: Integer;
begin
  maxf := length(FieldNames);     // e.g. 2 fields
  if (Props=nil) or (FieldNames=nil) or (TableName='') or (length(FieldValues)<>maxf) or
     (Props.DBMS<>dFirebird) then
    raise ESQLDBException.CreateFmt('Invalid %s.MultipleValuesInsertInlined(%s) call',
      [ClassName,TableName]);
  sqllenwitoutvalues := 3*maxf+24;
  dec(maxf);
  for f := 0 to maxf do
    case FieldTypes[f] of
    ftBlob: begin // not possible to inline BLOBs
      MultipleValuesInsert(Props,TableName,FieldNames,FieldTypes,RowCount,FieldValues);
      exit;
    end;
    ftDate: inc(sqllenwitoutvalues,Length(FieldNames[f])+20); // 'cast(..)'
    else
      inc(sqllenwitoutvalues,Length(FieldNames[f]));
    end;
  W := TTextWriter.CreateOwnedStream(49152);
  try
    r := 0;
    repeat
      W.AddShort('execute block as begin'#10);
      repeat
        sqllen := sqllenwitoutvalues;
        for f := 0 to maxf do
          inc(sqllen,length(FieldValues[f,r]));
        if sqllen+integer(W.TextLength)>30000 then
          break;
        W.AddShort('INSERT INTO ');
        W.AddString(TableName);
        W.Add(' ','(');
        for f := 0 to maxf do begin
          W.AddString(FieldNames[f]);
          W.Add(',');
        end;
        W.CancelLastComma;
        W.AddShort(') VALUES (');
        for f := 0 to maxf do begin
          if (FieldValues[f,r]='') or (FieldValues[f,r]='null') then
            W.AddShort('null') else
          if FieldTypes[f]=ftDate then
            if FieldValues[f,r]=#39#39 then
              W.AddShort('null') else begin
              W.AddShort('timestamp ');
              W.AddString(FieldValues[f,r]);
            end else
            W.AddString(FieldValues[f,r]);
          W.Add(',');
        end;
        W.CancelLastComma;
        W.AddShort(');'#10);
        inc(r);
      until r=RowCount;
      W.AddShort('end');
      with Props.NewThreadSafeStatement do
      try
        Execute(W.Text,false);
      finally
        Free;
      end;
      if r=RowCount then
        break;
      W.CancelAll;
    until false;
  finally
    W.Free;
  end;
end;

function TSQLDBConnectionProperties.FieldsFromList(const aFields: TSQLDBColumnDefineDynArray;
  aExcludeTypes: TSQLDBFieldTypes): RawUTF8;
var i,n: integer;
begin
  result := '';
  if byte(aExcludeTypes)<>0 then begin
    n := length(aFields);
    for i := 0 to n-1 do
    with aFields[i] do
    if not (ColumnType in aExcludeTypes) then begin
      dec(n);
      if result='' then
        result := ColumnName else
        result := result+','+ColumnName;
    end;
    if n=0 then
      result := '*';
  end else
    result := '*';
end;

function TSQLDBConnectionProperties.SQLSelectAll(const aTableName: RawUTF8;
  const aFields: TSQLDBColumnDefineDynArray; aExcludeTypes: TSQLDBFieldTypes): RawUTF8;
begin
  if (self=nil) or (aTableName='') then
    result := '' else
    result := 'select '+FieldsFromList(aFields,aExcludeTypes)+' from '+
      SQLTableName(aTableName);
end;

class function TSQLDBConnectionProperties.EngineName: RawUTF8;
var L: integer;
begin
  if self=nil then
    result := '' else begin
    result := RawUTF8(ClassName);
    if IdemPChar(pointer(result),'TSQLDB') then
      Delete(result,1,6) else
    if result[1]='T' then
      Delete(result,1,1);
    L := length(result);
    if (L>20) and IdemPropName('ConnectionProperties',@result[L-19],20) then
      SetLength(result,L-20);
    if (L>5) and IdemPropName('OleDB',pointer(result),5) then
      Delete(result,1,5);
  end;
end;

function TSQLDBConnectionProperties.GetDBMS: TSQLDBDefinition;
begin
  if fDBMS=dUnknown then
    result := dDefault else
    result := fDBMS;
end;

function TSQLDBConnectionProperties.AdaptSQLLimitForEngineList(
  var SQL: RawUTF8; LimitRowCount, AfterSelectPos, WhereClausePos, LimitPos: integer): boolean;
const EXE_FMT: PUTF8Char = 'where % ';
var ToBeInserted: RawUTF8;
    OrderByPosWithNoWhere: integer;
begin
  result := false;
  if (SQL<>'') and (SQL[length(SQL)]=';') then
    SQL[length(SQL)] := ' ';  // avoid syntax error for posWhere + WhereClausePos=0
  with DB_SQLLIMITCLAUSE[DBMS] do begin
    ToBeInserted := FormatUTF8(InsertFmt,[LimitRowCount]);
    case Position of
    posSelect: insert(ToBeInserted,SQL,AfterSelectPos);
    posWhere:
      if WhereClausePos=0 then
        SQL := SQL+' where '+ToBeInserted else
      if WhereClausePos<0 then begin
        OrderByPosWithNoWhere := -WhereClausePos;
        insert(FormatUTF8(EXE_FMT,[ToBeInserted]),SQL,OrderByPosWithNoWhere);
      end else
        insert(ToBeInserted+' and ',SQL,WhereClausePos);
    posAfter:  insert(ToBeInserted,SQL,LimitPos);
    else Exit;
    end;
    result := true;
  end;
end;

{$ifndef DELPHI5OROLDER}
procedure TSQLDBConnectionProperties.RemoteProcessExec(Command: TSQLDBProxyConnectionCommand;
  const Input; var Output);
var Stmt: ISQLDBStatement;
    Data: TRawByteStringStream;
    i: Integer;
    InputTableName: RawUTF8 absolute Input;
    InputExecute: TSQLDBProxyConnectionCommandExecute absolute Input;
    OutputSQLDBDefinition: TSQLDBDefinition absolute Output;
    OutputTimeLog: TTimeLog absolute Output;
    OutputSQLDBColumnDefineDynArray: TSQLDBColumnDefineDynArray absolute Output;
    OutputSQLDBIndexDefineDynArray: TSQLDBIndexDefineDynArray absolute Output;
    OutputRawUTF8DynArray: TRawUTF8DynArray absolute Output;
    OutputRawUTF8: RawUTF8 absolute Output;
    OutputRawByteString: RawByteString absolute Output;
    OutputSynNameValue: TSynNameValue absolute Output;
begin
  case Command of
  cInitialize:
    OutputSQLDBDefinition := DBMS;
  cConnect:
    ThreadSafeConnection.Connect;
  cDisconnect:
    ThreadSafeConnection.Disconnect;
  cStartTransaction:
    ThreadSafeConnection.StartTransaction;
  cCommit:
    ThreadSafeConnection.Commit;
  cRollback:
    ThreadSafeConnection.Rollback;
  cServerTimeStamp:
    OutputTimeLog := ThreadSafeConnection.ServerTimeStamp;
  cGetFields:
    GetFields(InputTableName,OutputSQLDBColumnDefineDynArray);
  cGetIndexes:
    GetIndexes(InputTableName,OutputSQLDBIndexDefineDynArray);
  cGetTableNames:
    GetTableNames(OutputRawUTF8DynArray);
  cGetForeignKeys: begin
    GetForeignKey('',''); // ensure Dest.fForeignKeys exists
    OutputSynNameValue := fForeignKeys;
  end;
  cExecute, cExecuteToBinary, cExecuteToJSON, cExecuteToExpandedJSON: begin
    Stmt := NewThreadSafeStatementPrepared(InputExecute.SQL,
      (Command<>cExecute),true);
    for i := 1 to Length(InputExecute.Params) do
    with InputExecute.Params[i-1] do
    if InputExecute.ArrayCount=0 then
      case VType of
        ftNull:     Stmt.BindNull(i,VInOut);
        ftInt64:    Stmt.Bind(i,VInt64,VInOut);
        ftDouble:   Stmt.Bind(i,PDouble(@VInt64)^,VInOut);
        ftCurrency: Stmt.Bind(i,PCurrency(@VInt64)^,VInOut);
        ftDate:     Stmt.BindDateTime(i,PDateTime(@VInt64)^,VInOut);
        ftUTF8:     Stmt.BindTextU(i,VData,VInOut);
        ftBlob:     Stmt.BindBlob(i,VData,VInOut);
        else raise ESQLDBException.CreateFmt(
          'Invalid parameter #%d in %s.ProcessExec(cExecute)',[i,ClassName]);
      end else
      Stmt.BindArray(i,VType,VArray,InputExecute.ArrayCount);
    Stmt.ExecutePrepared;
    case Command of
    cExecuteToBinary: begin
      Data := TRawByteStringStream.Create;
      try
        Stmt.FetchAllToBinary(Data);
        OutputRawByteString := Data.DataString;
      finally
        Data.Free;
      end;
    end;
    cExecuteToJSON, cExecuteToExpandedJSON:
      OutputRawUTF8 := Stmt.FetchAllAsJSON(Command=cExecuteToExpandedJSON);
    end;
  end;
  else raise ESQLDBException.CreateFmt('Unknown %s.ProcessExec() command %d',
    [ClassName,ord(Command)]);
  end;
end;
{$endif DELPHI5OROLDER}


{ TSQLDBConnectionPropertiesThreadSafe }

procedure TSQLDBConnectionPropertiesThreadSafe.ClearConnectionPool;
begin
  EnterCriticalSection(fConnectionCS);
  try
    inherited; // clear fMainConnection
    fConnectionPool.Clear;
    fLatestConnectionRetrievedInPool := -1;
  finally
    LeaveCriticalSection(fConnectionCS);
  end;
end;

constructor TSQLDBConnectionPropertiesThreadSafe.Create(const aServerName,
  aDatabaseName, aUserID, aPassWord: RawUTF8);
begin
  fConnectionPool := TObjectList.Create;
  fLatestConnectionRetrievedInPool := -1;
  InitializeCriticalSection(fConnectionCS);
  inherited Create(aServerName,aDatabaseName,aUserID,aPassWord);
end;

function TSQLDBConnectionPropertiesThreadSafe.CurrentThreadConnection: TSQLDBConnection;
var i: integer;
begin
  EnterCriticalSection(fConnectionCS);
  try
    i := CurrentThreadConnectionIndex;
    if i<0 then
      result := nil else
      result := fConnectionPool.List[i];
  finally
    LeaveCriticalSection(fConnectionCS);
   end;
end;

function TSQLDBConnectionPropertiesThreadSafe.CurrentThreadConnectionIndex: Integer;
var ID: DWORD;
begin
  if self<>nil then begin
    ID := GetCurrentThreadId;
    result := fLatestConnectionRetrievedInPool;
    if (result>=0) and
       (TSQLDBConnectionThreadSafe(fConnectionPool.List[result]).fThreadID=ID) then
      exit;
    for result := 0 to fConnectionPool.Count-1 do
      if TSQLDBConnectionThreadSafe(fConnectionPool.List[result]).fThreadID=ID then begin
        fLatestConnectionRetrievedInPool := result;
        exit;
      end;
  end;
  result := -1;
end;

destructor TSQLDBConnectionPropertiesThreadSafe.Destroy;
begin
  inherited Destroy; // do MainConnection.Free
  fConnectionPool.Free;
  DeleteCriticalSection(fConnectionCS);
end;

procedure TSQLDBConnectionPropertiesThreadSafe.EndCurrentThread;
var i: integer;
begin
  EnterCriticalSection(fConnectionCS);
  try
    i := CurrentThreadConnectionIndex;
    if i>=0 then begin // do nothing if this thread has no active connection
      fConnectionPool.Delete(i); // release thread's TSQLDBConnection instance
      if i=fLatestConnectionRetrievedInPool then
        fLatestConnectionRetrievedInPool := -1;
    end;
  finally
    LeaveCriticalSection(fConnectionCS);
  end;
end;

function TSQLDBConnectionPropertiesThreadSafe.GetMainConnection: TSQLDBConnection;
begin
  result := ThreadSafeConnection;
end;

function TSQLDBConnectionPropertiesThreadSafe.ThreadSafeConnection: TSQLDBConnection;
var i: integer;
begin
  case fThreadingMode of
  tmThreadPool: begin
    EnterCriticalSection(fConnectionCS);
    try
      i := CurrentThreadConnectionIndex;
      if i>=0 then begin
        result := fConnectionPool.List[i];
        exit;
      end;
      result := NewConnection;
      (result as TSQLDBConnectionThreadSafe).fThreadID := GetCurrentThreadId;
      fLatestConnectionRetrievedInPool := fConnectionPool.Add(result)
    finally
      LeaveCriticalSection(fConnectionCS);
     end;
  end;
  tmMainConnection:
    result := inherited GetMainConnection;
  else
    result := nil;
  end;
end;

{
  tmBackgroundThread should handle TSQLRestStorageExternal methods:
  Create: ServerTimeStamp+GetFields
  BeginTransaction
  Commit
  Rollback
  InternalBatchStop: PrepareSQL+BindArray+ExecutePrepared
  EngineUpdateBlob:  PrepareSQL+Bind/BindNull+ExecutePrepared
  ExecuteDirect:     PrepareSQL+Bind+ExecutePrepared
  ExecuteInlined:    ExecuteInlined

  Handling only TSQLDBStatementWithParams will allow all binding to be
  set in the calling thread, but the actual process to take place in the
  background thread
}

{ TSQLDBStatement }

procedure TSQLDBStatement.Bind(Param: Integer; const Data: TSQLVar; IO: TSQLDBParamInOutType);
begin
  with Data do
  case VType of
    ftNull:     BindNull(Param,IO);
    ftInt64:    Bind(Param,VInt64,IO);
    ftDate:     BindDateTime(Param,VDateTime,IO);
    ftDouble:   Bind(Param,VDouble,IO);
    ftCurrency: Bind(Param,VCurrency,IO);
    ftUTF8:     BindTextP(Param,VText,IO);
    ftBlob:     BindBlob(Param,VBlob,VBlobLen,IO);
    else raise ESQLDBException.CreateFmt(
      '%s.Bind(Param=%d,VType=%d)',[fStatementClassName,Param,ord(VType)]);
  end;
end;

procedure TSQLDBStatement.Bind(Param: Integer; ParamType: TSQLDBFieldType;
  const Value: RawUTF8; ValueAlreadyUnquoted: boolean; IO: TSQLDBParamInOutType=paramIn);
var tmp: RawUTF8;
begin
  if (not ValueAlreadyUnquoted) and (Value='null') then
    // bind null (ftUTF8 should be '"null"')
    BindNull(Param,IO) else
    case ParamType of
      ftNull:     BindNull(Param,IO);
      ftInt64:    Bind(Param,GetInt64(pointer(Value)),IO);
      ftDouble:   Bind(Param,GetExtended(pointer(Value)),IO);
      ftCurrency: BindCurrency(Param,StrToCurrency(pointer(Value)),IO);
      ftBlob:     BindBlob(Param,Value,IO); // already decoded
      ftDate: begin
        if ValueAlreadyUnquoted then
          tmp := Value else
          UnQuoteSQLStringVar(pointer(Value),tmp);
        BindDateTime(Param,Iso8601ToDateTime(tmp),IO);
      end;
      ftUTF8:
        if ((Value='') or (Value=#39#39)) and
            fConnection.fProperties.StoreVoidStringAsNull then
          BindNull(Param,IO) else begin
          if ValueAlreadyUnquoted then
            tmp := Value else
            UnQuoteSQLStringVar(pointer(Value),tmp);
          BindTextU(Param,tmp,IO);
        end;
      else raise ESQLDBException.CreateFmt('Invalid %s.Bind(%d,TSQLDBFieldType(%d),%s)',
        [fStatementClassName,Param,ord(ParamType),Value]);
    end;
end;

procedure TSQLDBStatement.Bind(const Params: array of const;
  IO: TSQLDBParamInOutType);
var i,c: integer;
begin
  for i := 1 to high(Params)+1 do
  with Params[i-1] do // bind parameter index starts at 1
  case VType of
    vtString:     // expect WinAnsi String for ShortString
      BindTextU(i,WinAnsiToUtf8(@VString^[1],ord(VString^[0])),IO);
    vtAnsiString:
      if VAnsiString=nil then
        BindTextU(i,'',IO) else begin
        c := PInteger(VAnsiString)^ and $00ffffff;
        if c=JSON_BASE64_MAGIC then
          BindBlob(i,Base64ToBin(PAnsiChar(VAnsiString)+3,length(RawUTF8(VAnsiString))-3)) else
        if c=JSON_SQLDATE_MAGIC then
          BindDateTime(i,Iso8601ToDateTimePUTF8Char(PUTF8Char(VAnsiString)+3,length(RawUTF8(VAnsiString))-3)) else
          // expect UTF-8 content only for AnsiString, i.e. RawUTF8 variables
          BindTextU(i,RawUTF8(VAnsiString),IO);
      end;
    vtPChar:      BindTextP(i,PUTF8Char(VPChar),IO);
    vtChar:       BindTextU(i,RawUTF8(VChar),IO);
    vtWideChar:   BindTextU(i,RawUnicodeToUtf8(@VWideChar,1),IO);
    vtPWideChar:  BindTextU(i,RawUnicodeToUtf8(VPWideChar,StrLenW(VPWideChar)),IO);
    vtWideString: BindTextW(i,WideString(VWideString),IO);
{$ifdef UNICODE}
    vtUnicodeString: BindTextS(i,string(VUnicodeString),IO);
{$endif}
    vtBoolean:    Bind(i,integer(VBoolean),IO);
    vtInteger:    Bind(i,VInteger,IO);
    vtInt64:      Bind(i,VInt64^,IO);
    vtCurrency:   BindCurrency(i,VCurrency^,IO);
    vtExtended:   Bind(i,VExtended^,IO);
    vtPointer:    if VPointer=nil then
                     BindNull(i,IO) else
                     raise ESQLDBException.Create('Unexpected BOUND pointer');
    else
      raise ESQLDBException.CreateFmt(
      '%s.BindArrayOfConst(Param=%d,Type=%d)',[fStatementClassName,i,VType]);
  end;
end;
      
procedure TSQLDBStatement.BindVariant(Param: Integer; const Data: Variant;
  DataIsBlob: boolean; IO: TSQLDBParamInOutType);
{$ifndef DELPHI5OROLDER}
var I64: Int64Rec;
{$endif}
begin
  case TVarData(Data).VType of
    varNull:
      BindNull(Param,IO);
    varBoolean:
      Bind(Param,ord(TVarData(Data).VBoolean),IO);
    varByte:
      Bind(Param,TVarData(Data).VInteger,IO);
    varSmallint:
      Bind(Param,TVarData(Data).VSmallInt,IO);
    {$ifndef DELPHI5OROLDER}
    varShortInt:
      Bind(Param,TVarData(Data).VShortInt,IO);
    varWord:
      Bind(Param,TVarData(Data).VWord,IO);
    varLongWord: begin
      I64.Lo := TVarData(Data).VLongWord;
      I64.Hi := 0;
      Bind(Param,Int64(I64),IO);
    end;
    {$endif}
    varInteger:
      Bind(Param,TVarData(Data).VInteger,IO);
    varInt64:
      Bind(Param,TVarData(Data).VInt64,IO);
    varSingle:
      Bind(Param,TVarData(Data).VSingle,IO);
    varDouble:
      Bind(Param,TVarData(Data).VDouble,IO);
    varDate:
      BindDateTime(Param,TVarData(Data).VDate,IO);
    varCurrency:
      BindCurrency(Param,TVarData(Data).VCurrency,IO);
    varOleStr: // handle special case if was bound explicitely as WideString
      BindTextW(Param,WideString(TVarData(Data).VAny),IO);
    {$ifdef UNICODE}
    varUString:
      if DataIsBlob then
        raise ESQLDBException.CreateFmt(
          '%s: BLOB should not be UnicodeString',[fStatementClassName]) else
        BindTextU(Param,StringToUTF8(UnicodeString(TVarData(Data).VAny)),IO);
    {$endif}
    varString:
      if DataIsBlob then
        // no conversion if was set via TQuery.AsBlob property e.g.
        BindBlob(Param,RawByteString(TVarData(Data).VAny),IO) else
        // direct bind of AnsiString as UTF-8 value
        BindTextU(Param,CurrentAnsiConvert.AnsiToUTF8(AnsiString(TVarData(Data).VAny)),IO);
    else
    {$ifdef LVCL}
      raise ESQLDBException.CreateFmt(
        'Unhandled variant type in %s.BindVariant',[fStatementClassName]);
    {$else}
      // also use TEXT for any non native VType parameter
      BindTextU(Param,StringToUTF8(string(Data)),IO);
    {$endif}
  end;
end;

function TSQLDBFieldTypeToString(aType: TSQLDBFieldType): string;
var PS: PShortString;
begin
  if cardinal(aType)<=cardinal(high(aType)) then begin
    PS := GetEnumName(TypeInfo(TSQLDBFieldType),ord(aType));
    result := Ansi7ToString(@PS^[3],ord(PS^[0])-2);
  end else
    result := IntToStr(ord(aType));
end;

procedure TSQLDBStatement.BindArray(Param: Integer; ParamType: TSQLDBFieldType;
  const Values: TRawUTF8DynArray; ValuesCount: integer);
begin
  if (Param<=0) or (ParamType in [ftUnknown,ftNull]) or (ValuesCount<=0) or
     (length(Values)<ValuesCount) or
     (fConnection.fProperties.BatchSendingAbilities*[cCreate,cUpdate,cDelete]=[]) then
    raise ESQLDBException.CreateFmt('Invalid call to %s.BindArray(Param=%d,Type=%s)',
      [fStatementClassName,Param,TSQLDBFieldTypeToString(ParamType)]);
end;

procedure TSQLDBStatement.BindArray(Param: Integer; const Values: array of Int64);
begin
  BindArray(Param,ftInt64,nil,0); // will raise an exception (Values=nil)
end;

procedure TSQLDBStatement.BindArray(Param: Integer; const Values: array of RawUTF8);
begin
  BindArray(Param,ftUTF8,nil,0); // will raise an exception (Values=nil)
end;

procedure TSQLDBStatement.BindArray(Param: Integer; const Values: array of double);
begin
  BindArray(Param,ftDouble,nil,0); // will raise an exception (Values=nil)
end;

procedure TSQLDBStatement.BindArrayCurrency(Param: Integer;
  const Values: array of currency);
begin
  BindArray(Param,ftCurrency,nil,0); // will raise an exception (Values=nil)
end;

procedure TSQLDBStatement.BindArrayDateTime(Param: Integer; const Values: array of TDateTime);
begin
  BindArray(Param,ftDate,nil,0); // will raise an exception (Values=nil)
end;

procedure TSQLDBStatement.CheckCol(Col: integer);
begin
  if (self=nil) or (cardinal(Col)>=cardinal(fColumnCount)) then
    raise ESQLDBException.CreateFmt('Invalid call to %s.Column*(Col=%d)',
      [fStatementClassName,Col]);
end;

constructor TSQLDBStatement.Create(aConnection: TSQLDBConnection);
begin
  // SynDBLog.Enter(self);
  inherited Create;
  fConnection := aConnection;
  fStatementClassName := string(ClassName);
end;

function TSQLDBStatement.ColumnCount: integer;
begin
  if self=nil then
    result := 0 else
    result := fColumnCount;
end;

function TSQLDBStatement.ColumnBlobBytes(Col: integer): TBytes;
var Res: RawByteString;
begin
  Res := ColumnBlob(Col);
  SetLength(result,length(Res));
  move(pointer(Res)^,pointer(result)^,length(Res));
end;

{$ifndef LVCL}
function TSQLDBStatement.ColumnVariant(Col: integer): Variant;
begin
  ColumnToVariant(Col,result);
end;

function TSQLDBStatement.ColumnToVariant(Col: integer; var Value: Variant): TSQLDBFieldType;
var tmp: RawByteString;
    V: TSQLVar;
begin
  ColumnToSQLVar(Col,V,tmp);
  result := V.VType;
  with TVarData(Value) do begin
    if not(VType in VTYPE_STATIC) then
      VarClear(Value);
    VType := MAP_FIELDTYPE2VARTYPE[V.VType];
    case result of
      ftNull: ; // do nothing
      ftInt64:    VInt64    := V.VInt64;
      ftDouble:   VDouble   := V.VDouble;
      ftDate:     VDate     := V.VDateTime;
      ftCurrency: VCurrency := V.VCurrency;
      ftBlob: begin
        VAny := nil;
        if V.VBlob<>nil then
          if V.VBlob=pointer(tmp) then
            RawByteString(VAny) := tmp else
            SetString(RawByteString(VAny),PAnsiChar(V.VBlob),V.VBlobLen);
      end;
      ftUTF8: begin
        VAny := nil; // avoid GPF below
        if V.VText<>nil then begin
          if V.VText=pointer(tmp) then
            V.VBlobLen := length(tmp) else
            V.VBlobLen := StrLen(V.VText);
        end;
          {$ifndef UNICODE}
          if not fConnection.Properties.VariantStringAsWideString then begin
            VType := varString;
            CurrentAnsiConvert.UTF8BufferToAnsi(V.VText,V.VBlobLen,AnsiString(VAny));
          end else
          {$endif}
            UTF8ToSynUnicode(V.VText,V.VBlobLen,SynUnicode(VAny));
      end;
      else raise ESQLDBException.CreateFmt(
        '%s.ColumnToVariant: Invalid ColumnType(%d)=%d',
        [fStatementClassName,Col,ord(result)]);
    end;
  end;
end;
{$endif}

function TSQLDBStatement.ColumnTimeStamp(Col: integer): TTimeLog;
begin
  case ColumnType(Col) of // will call GetCol() to check Col
    ftNull:  result := 0;
    ftInt64: result := ColumnInt(Col);
    ftDate:  PTimeLogBits(@result)^.From(ColumnDateTime(Col));
    else     PTimeLogBits(@result)^.From(Trim(ColumnUTF8(Col)));
  end;
end;

function TSQLDBStatement.ColumnTimeStamp(const ColName: RawUTF8): TTimeLog;
begin
  result := ColumnTimeStamp(ColumnIndex(ColName));
end;

procedure TSQLDBStatement.ColumnsToJSON(WR: TJSONWriter; DoNotFletchBlobs: boolean);
var col: integer;
    blob: RawByteString;
begin
  if WR.Expand then
    WR.Add('{');
  for col := 0 to fColumnCount-1 do begin
    if WR.Expand then
      WR.AddFieldName(ColumnName(col)); // add '"ColumnName":'
    if ColumnNull(col) then
      WR.AddShort('null') else
    case ColumnType(col) of
      ftNull:     WR.AddShort('null');
      ftInt64:    WR.Add(ColumnInt(col));
      ftDouble:   WR.Add(ColumnDouble(col));
      ftCurrency: WR.AddCurr64(ColumnCurrency(col));
      ftDate: begin
        WR.Add('"');
        WR.AddDateTime(ColumnDateTime(col));
        WR.Add('"');
      end;
      ftUTF8: begin
        WR.Add('"');
        WR.AddJSONEscape(pointer(ColumnUTF8(col)));
        WR.Add('"');
      end;
      ftBlob:
        if DoNotFletchBlobs then
          WR.AddShort('null') else begin
          blob := ColumnBlob(col);
          WR.WrBase64(pointer(blob),length(blob),true); // withMagic=true
        end;
      else raise ESQLDBException.CreateFmt(
        '%s.ColumnsToJSON: Invalid ColumnType(%d)=%d',
        [fStatementClassName,col,ord(ColumnType(col))]);
    end;
    WR.Add(',');
  end;
  WR.CancelLastComma; // cancel last ','
  if WR.Expand then
    WR.Add('}');
end;

procedure TSQLDBStatement.ColumnToSQLVar(Col: Integer; var Value: TSQLVar;
  var Temp: RawByteString; DoNotFetchBlob: boolean);
begin
  if ColumnNull(Col) then // will call GetCol() to check Col
    Value.VType := ftNull else
    Value.VType := ColumnType(Col);
  case Value.VType of
    ftInt64:    Value.VInt64  := ColumnInt(Col);
    ftDouble:   Value.VDouble := ColumnDouble(Col);
    ftDate:     Value.VDateTime := ColumnDateTime(Col);
    ftCurrency: Value.VCurrency := ColumnCurrency(Col);
    ftUTF8: begin
      Temp := ColumnUTF8(Col);
      Value.VText := pointer(Temp);
    end;
    ftBlob:
    if DoNotFetchBlob then begin
      Value.VBlob := nil;
      Value.VBlobLen := 0;
    end else begin
      Temp := ColumnBlob(Col);
      Value.VBlob := pointer(Temp);
      Value.VBlobLen := length(Temp);
    end;
  end;
end;

function TSQLDBStatement.ColumnToTypedValue(Col: integer;
  DestType: TSQLDBFieldType; var Dest): TSQLDBFieldType;
{$ifdef LVCL}
begin
  raise ESQLDBException.Create('ColumnToTypedValue non implemented in LVCL');
end;
{$else}
var Temp: Variant; // rely on a temporary variant value for the conversion
begin
  result := ColumnToVariant(Col,Temp);
  case DestType of
  ftInt64:    {$ifdef DELPHI5OROLDER}integer{$else}Int64{$endif}(Dest) := Temp;
  ftDouble:   Double(Dest) := Temp;
  ftCurrency: Currency(Dest) := Temp;
  ftDate:     TDateTime(Dest) := Temp;
  ftUTF8:     RawUTF8(Dest) := StringToUTF8(string(Temp));
  ftBlob:     TBlobData(Dest) := TBlobData(Temp);
    else raise ESQLDBException.CreateFmt('%s.ColumnToTypedValue: Invalid Type "%s"',
      [fStatementClassName,TSQLDBFieldTypeToString(result)]);
  end;
end;
{$endif}

{$ifndef LVCL}
function TSQLDBStatement.ParamToVariant(Param: Integer; var Value: Variant;
  CheckIsOutParameter: boolean=true): TSQLDBFieldType;
begin
  dec(Param); // start at #1
  if (self=nil) or (cardinal(Param)>=cardinal(fParamCount)) then
    raise ESQLDBException.CreateFmt('%s.ParamToVariant(%d)',
      [fStatementClassName,Param]);
  // overridden method should fill Value with proper data
  result := ftUnknown;
end;
{$endif}

procedure TSQLDBStatement.Execute(const aSQL: RawUTF8; ExpectResults: Boolean);
begin
  Connection.InternalProcess(speActive);
  try
    Prepare(aSQL,ExpectResults);
    ExecutePrepared;
  finally
    Connection.InternalProcess(speNonActive);
  end;
end;

function TSQLDBStatement.FetchAllToJSON(JSON: TStream; Expanded: boolean;
  DoNotFletchBlobs, RewindToFirst: boolean): PtrInt;
var W: TJSONWriter;
    col: integer;
begin
  result := 0;
  W := TJSONWriter.Create(JSON,Expanded,false);
  try
    Connection.InternalProcess(speActive);
    // get col names and types
    SetLength(W.ColNames,ColumnCount);
    for col := 0 to ColumnCount-1 do
      W.ColNames[col] := ColumnName(col);
    W.AddColumns; // write or init field names for appropriate JSON Expand
    if Expanded then
      W.Add('[');
    // write rows data
    while Step(RewindToFirst) do begin
      RewindToFirst := false;
      ColumnsToJSON(W,DoNotFletchBlobs);
      W.Add(',');
      inc(result);
    end;
    if (result=0) and W.Expand then begin   
      // we want the field names at least, even with no data (RowCount=0)
      W.Expand := false; //  {"FieldCount":2,"Values":["col1","col2"]}
      W.CancelAll;
      for col := 0 to ColumnCount-1 do
        W.ColNames[col] := ColumnName(col); // previous W.AddColumns did add ""
      W.AddColumns;
    end;
    W.EndJSONObject(0,result);
  finally
    W.Free;
    Connection.InternalProcess(speNonActive);
  end;
end;

function TSQLDBStatement.FetchAllToCSVValues(Dest: TStream; Tab: boolean;
  CommaSep: AnsiChar; AddBOM: boolean): PtrInt;
const NULL: array[boolean] of string[7] = ('"null"','null');
      BLOB: array[boolean] of string[7] = ('"blob"','blob');
var F, FMax: integer;
    W: TTextWriter;
    tmp: RawByteString;
    V: TSQLVar;
begin
  result := 0;
  if (Dest=nil) or (self=nil) or (ColumnCount=0) then
    exit;
  if Tab then
    CommaSep := #9;
  FMax := ColumnCount-1;
  W := TTextWriter.Create(Dest,65536);
  try
    if AddBOM then
      W.AddShort(#$ef#$bb#$bf); // add UTF-8 Byte Order Mark
    // add CSV header
    for F := 0 to FMax do begin
      if not Tab then
        W.Add('"');
      W.AddString(ColumnName(F));
      if Tab then
        W.Add(#9) else
        W.Add('"',CommaSep);
    end;
    W.CancelLastChar;
    W.AddCR;
    // add CSV rows
    while Step do begin
      for F := 0 to FMax do begin
        ColumnToSQLVar(F,V,tmp,true); // DoNotFetchBlobs=true
        case V.VType of
          ftNull:     W.AddShort(NULL[tab]);
          ftInt64:    W.Add(V.VInt64);
          ftDouble:   W.Add(V.VDouble);
          ftCurrency: W.AddCurr64(V.VCurrency);
          ftDate: begin
            if not Tab then
              W.Add('"');
            W.AddDateTime(V.VDateTime);
            if not Tab then
              W.Add('"');
          end;
          ftUTF8: begin
            if not Tab then begin
              W.Add('"');
              W.AddJSONEscape(V.VText);
              W.Add('"');
            end else
              W.AddNoJSONEscape(V.VText);
          end;
          ftBlob: W.AddShort(BLOB[Tab]);  // DoNotFetchBlobs=true
          else raise ESQLDBException.CreateFmt(
            '%s.FetchAllToCSVValues: Invalid ColumnType() %s',
            [fStatementClassName,TSQLDBFieldTypeToString(ColumnType(F))]);
        end;
        if F=FMax then
          W.AddCR else
          W.Add(CommaSep);
      end;
      inc(result);
    end;
    W.Flush;
  finally
    W.Free;
  end;
end;

function TSQLDBStatement.FetchAllAsJSON(Expanded: boolean;
  ReturnedRowCount: PPtrInt; DoNotFletchBlobs, RewindToFirst: boolean): RawUTF8;
var Stream: TRawByteStringStream;
    RowCount: PtrInt;
begin
  Stream := TRawByteStringStream.Create;
  try
    RowCount := FetchAllToJSON(Stream,Expanded,DoNotFletchBlobs,RewindToFirst);
    if ReturnedRowCount<>nil then
      ReturnedRowCount^ := RowCount;
    result := Stream.DataString;
  finally
    Stream.Free;
  end;
end;

procedure TSQLDBStatement.ColumnsToBinary(W: TFileBufferWriter;
  const Null: TSQLDBProxyStatementColumns; const ColTypes: TSQLDBFieldTypeDynArray);
var F: integer;
    VDouble: double;
    VCurrency: currency absolute VDouble;
    VDateTime: TDateTime absolute VDouble;
begin
  for F := 0 to length(ColTypes)-1 do
    if not (F in Null) then
    case ColTypes[F] of
    ftInt64:
      W.WriteVarInt64(ColumnInt(F));
    ftDouble: begin
      VDouble := ColumnDouble(F);
      W.Write(@VDouble,sizeof(VDouble));
    end;
    ftCurrency: begin
      VCurrency := ColumnCurrency(F);
      W.Write(@VCurrency,sizeof(VCurrency));
    end;
    ftDate: begin
      VDateTime := ColumnDateTime(F);
      W.Write(@VDateTime,sizeof(VDateTime));
    end;
    ftUTF8:
      W.Write(ColumnUTF8(F));
    ftBlob:
      W.Write(ColumnBlob(F));
    else raise ESQLDBException.CreateFmt(
      '%s.ColumnsToBinary: invalid ColTypes[%d]=%d',
      [fStatementClassName,F,ord(ColTypes[F])]);
    end;
end;

const
  FETCHALLTOBINARY_MAGIC = 1;

function TSQLDBStatement.FetchAllToBinary(Dest: TStream; MaxRowCount: cardinal;
  DataRowPosition: PCardinalDynArray): cardinal;
var F, FMax, FieldSize, NullRowSize: integer;
    StartPos: cardinal;
    Null: TSQLDBProxyStatementColumns;
    W: TFileBufferWriter;
    ColTypes: TSQLDBFieldTypeDynArray;
begin
  result := 0;
  W := TFileBufferWriter.Create(Dest);
  try
    FMax := ColumnCount;
    if FMax>0 then
      // write column description
      W.WriteVarUInt32(FETCHALLTOBINARY_MAGIC);
      W.WriteVarUInt32(FMax);
      SetLength(ColTypes,FMax);
      dec(FMax);
      for F := 0 to FMax do begin
        W.Write(ColumnName(F));
        ColTypes[F] := ColumnType(F,@FieldSize);
        W.Write(@ColTypes[F],sizeof(ColTypes[0]));
        W.WriteVarUInt32(FieldSize);
      end;
      // initialize null handling
      NullRowSize := (FMax shr 3)+1;
      if NullRowSize>sizeof(Null) then
        raise ESQLDBException.CreateFmt(
          '%s.FetchAllToBinary: too many columns',[fStatementClassName]);
      // save all data rows
      StartPos := W.TotalWritten;
      if (CurrentRow=1) or Step then // Step may already be done (e.g. TQuery.Open)
      repeat
        // save row position in DataRowPosition[] (if any)
        if DataRowPosition<>nil then begin
          if Length(DataRowPosition^)<=integer(result) then
            SetLength(DataRowPosition^,result+result shr 3+256);
          DataRowPosition^[result] := W.TotalWritten-StartPos;
        end;
        // first write null columns flags
        if NullRowSize>0 then begin
          FillChar(Null,NullRowSize,0);
          NullRowSize := 0;
        end;
        for F := 0 to FMax do
          if ColumnNull(F) then begin
            include(Null,F);
            NullRowSize := (F shr 3)+1;
          end;
        W.WriteVarUInt32(NullRowSize);
        if NullRowSize>0 then
          W.Write(@Null,NullRowSize);
        // then write data values
        ColumnsToBinary(W,Null,ColTypes);
        inc(result);
        if (MaxRowCount>0) and (result>=MaxRowCount) then
          break;
      until not Step;
    W.Write(@result,SizeOf(result)); // fixed size at the end for row count
    W.Flush;
  finally
    W.Free;
  end;
end;

procedure TSQLDBStatement.Execute(const aSQL: RawUTF8;
  ExpectResults: Boolean; const Params: array of const);
begin
  Connection.InternalProcess(speActive);
  try
    Prepare(aSQL,ExpectResults);
    Bind(Params);
    ExecutePrepared;
  finally
    Connection.InternalProcess(speNonActive);
  end;
end;

procedure TSQLDBStatement.Execute(SQLFormat: PUTF8Char;
  ExpectResults: Boolean; const Args, Params: array of const);
begin
  Execute(FormatUTF8(SQLFormat,Args),ExpectResults,Params);
end;

function TSQLDBStatement.UpdateCount: integer;
begin
  result := 0;
end;

procedure TSQLDBStatement.ExecutePreparedAndFetchAllAsJSON(Expanded: boolean; out JSON: RawUTF8);
begin
  ExecutePrepared;
  JSON := FetchAllAsJSON(Expanded);
end;

function TSQLDBStatement.ColumnString(Col: integer): string;
begin
  Result := UTF8ToString(ColumnUTF8(Col));
end;

function TSQLDBStatement.ColumnString(const ColName: RawUTF8): string;
begin
  result := ColumnString(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnBlob(const ColName: RawUTF8): RawByteString;
begin
  result := ColumnBlob(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnBlobBytes(const ColName: RawUTF8): TBytes;
begin
  result := ColumnBlobBytes(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnCurrency(const ColName: RawUTF8): currency;
begin
  result := ColumnCurrency(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnDateTime(const ColName: RawUTF8): TDateTime;
begin
  result := ColumnDateTime(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnDouble(const ColName: RawUTF8): double;
begin
  result := ColumnDouble(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnInt(const ColName: RawUTF8): Int64;
begin
  result := ColumnInt(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnUTF8(const ColName: RawUTF8): RawUTF8;
begin
  result := ColumnUTF8(ColumnIndex(ColName));
end;

{$ifndef LVCL}
function TSQLDBStatement.ColumnVariant(const ColName: RawUTF8): Variant;
begin
  ColumnToVariant(ColumnIndex(ColName),result);
end;

function TSQLDBStatement.GetColumnVariant(const ColName: RawUTF8): Variant;
begin
  ColumnToVariant(ColumnIndex(ColName),result);
end;
{$endif LVCL}

function TSQLDBStatement.ColumnCursor(const ColName: RawUTF8): ISQLDBRows;
begin
  result := ColumnCursor(ColumnIndex(ColName));
end;

function TSQLDBStatement.ColumnCursor(Col: integer): ISQLDBRows;
begin
  raise ESQLDBException.CreateFmt(
    '%s does not support CURSOR columns',[fStatementClassName]);
end;

function TSQLDBStatement.Instance: TSQLDBStatement;
begin
  Result := Self;
end;

function TSQLDBStatement.GetSQLWithInlinedParams: RawUTF8;
var P,B: PUTF8Char;
    num: integer;
    W: TTextWriter;
begin
  P := pointer(fSQL);
  if P=nil then begin
    result := '';
    exit;
  end;
  if fSQLWithInlinedParams<>'' then begin
    result := fSQLWithInlinedParams; // already computed
    exit;
  end;
  num := 1;
  W := nil;
  try
    repeat
      B := P;
      while not (P^ in ['?',#0]) do begin
        if (P[0]='''') and (P[1]<>'''') then begin
          repeat // ignore chars inside ' quotes
            inc(P);
          until (P[0]=#0) or ((P[0]='''')and(P[1]<>''''));
          if P[0]=#0 then break;
        end;
        inc(P);
      end;
      if W=nil then
        if P^=#0 then begin
          result := fSQL;
          exit;
        end else
        W := TTextWriter.CreateOwnedStream;
      W.AddNoJSONEscape(B,P-B);
      if P^=#0 then
        break;
      inc(P); // jump P^='?'
      AddParamValueAsText(num,W);
      inc(num);
    until P^=#0;
    result := W.Text;
    fSQLWithInlinedParams := result;
  finally
    W.Free;
  end;
end;

function TSQLDBStatement.GetParamValueAsText(Param: integer; MaxCharCount: integer=4096): RawUTF8;
{$ifdef LVCL}
begin
  raise ESQLDBException.Create('Unhandled GetParamValueAsText()');
end;
{$else}
var V: variant;
    i64: Int64;
    Truncated: boolean;
    L: integer;
begin
  if cardinal(Param-1)>=cardinal(fParamCount) then
    result := '?OOR?' else begin
    if MaxCharCount<=0 then
      MaxCharCount := maxInt;
    case ParamToVariant(Param,V,false) of
    ftUnknown:
      result := '???';
    ftNull:
      result := 'NULL';
    ftDate:
      result := ''''+DateTimeToIso8601Text(V,' ')+'''';
    ftInt64: begin
      VariantToInt64(V,i64);
      Int64ToUTF8(i64,result);
    end;
    ftBlob:
      result := '*BLOB*';
    ftDouble, ftCurrency:
      result := DoubleToStr(V);
    ftUTF8: begin
      Truncated := false;
      with TVarData(V) do
      case VType of
        varEmpty, varNull: result := '';
        varOleStr: begin // as returned e.g. by TOleDBStatement.ParamToVariant()
          L := StrLenW(VOleStr);
          if L>MaxCharCount then begin
            Truncated := true;
            L := MaxCharCount;
          end;
          RawUnicodeToUtf8(VOleStr,L,result);
        end;
        varString: begin // RawUTF8 by TSQLDBStatementWithParams.ParamToVariant()
          L := length(AnsiString(VAny));
          if L>MaxCharCount then begin
            Truncated := true;
            L := MaxCharCount;
            while (L>0) and (PByteArray(VAny)^[L-1]>126) do
              dec(L); // avoid return of invalid UTF-8 buffer
            if L=0 then
              L := MaxCharCount;
            SetString(result,PAnsiChar(VAny),L);
          end else
            result := RawUTF8(VAny);
        end;
        {$ifdef UNICODE}
        varUString: begin
          L := length(string(VAny));
          if L>MaxCharCount then begin
            Truncated := true;
            L := MaxCharCount;
          end;
          RawUnicodeToUtf8(VAny,L,result);
        end;
        {$endif}
        else result := StringToUTF8(string(V));
      end;
      if truncated then // truncate very long TEXT in log
        result := QuotedStr(result+'...') else
        result := QuotedStr(result);
    end;
    else result := StringToUTF8(string(V));
    end;
  end;
end;
{$endif}

procedure TSQLDBStatement.AddParamValueAsText(Param: integer; Dest: TTextWriter);
begin
  Dest.AddString(GetParamValueAsText(Param));
end;

{$ifndef DELPHI5OROLDER}
{$ifndef LVCL}
var
  SQLDBRowVariantType: TCustomVariantType = nil;

function TSQLDBStatement.RowData: Variant;
begin
  if SQLDBRowVariantType=nil then
    SQLDBRowVariantType := SynRegisterCustomVariantType(TSQLDBRowVariantType);
  with TVarData(result) do begin
    if not(VType in VTYPE_STATIC) then
      VarClear(result);
    VType := SQLDBRowVariantType.VarType;
    VPointer := self;
  end;
end;
{$endif}
{$endif}

procedure TSQLDBStatement.Prepare(const aSQL: RawUTF8;
  ExpectResults: Boolean);
var L: integer;
begin
  Connection.InternalProcess(speActive);
  try
    L := length(aSQL);
    if (L>5) and (aSQL[L]=';') and // avoid syntax error for some drivers
       not IdemPChar(@aSQL[L-4],' END') then
      fSQL := copy(aSQL,1,L-1) else
      fSQL := aSQL;
    fExpectResults := ExpectResults;
    if not fConnection.IsConnected then
      fConnection.Connect;
  finally
    Connection.InternalProcess(speNonActive);
  end;
end;

procedure TSQLDBStatement.Reset;
begin
  fSQLWithInlinedParams := '';
  // a do-nothing default method (used e.g. for OCI)
end;

function TSQLDBStatement.ColumnsToSQLInsert(const TableName: RawUTF8;
  var Fields: TSQLDBColumnPropertyDynArray): RawUTF8;
var F: integer;
begin
  Result := '';
  if (self=nil) or (TableName='') then
    exit;
  SetLength(Fields,ColumnCount);
  if Fields=nil then
    exit;
  Result := 'insert into '+TableName+' (';
  for F := 0 to high(Fields) do
    with Fields[F] do begin
      ColumnName := self.ColumnName(F);
      ColumnType := self.ColumnType(F);
      case ColumnType of
      ftNull:
        ColumnType := ftUTF8; // if not identified, we'll set a flexible content
      ftUnknown:
        raise ESQLDBException.CreateFmt(
          '%s.ColumnsToSQLInsert: Invalid column %s',[fStatementClassName,ColumnName]);
      end;
      Result := Result+ColumnName+',';
    end;
  Result[length(Result)] := ')';
  Result := Result+' values (';
  for F := 0 to high(Fields) do
    Result := Result+'?,'; // MUCH faster with a prepared statement
  Result[length(Result)] := ')';
end;

procedure TSQLDBStatement.BindFromRows(
  const Fields: TSQLDBColumnPropertyDynArray; Rows: TSQLDBStatement);
var F: integer;
begin
  if (self<>nil) and (Fields<>nil) and (Rows<>nil) then
    for F := 0 to high(Fields) do
      if Rows.ColumnNull(F) then
        BindNull(F+1) else
      case Fields[F].ColumnType of
        ftNull:     BindNull(F+1);
        ftInt64:    Bind(F+1,Rows.ColumnInt(F));
        ftDouble:   Bind(F+1,Rows.ColumnDouble(F));
        ftCurrency: BindCurrency(F+1,Rows.ColumnCurrency(F));
        ftDate:     BindDateTime(F+1,Rows.ColumnDateTime(F));
        ftUTF8:     BindTextU(F+1,Rows.ColumnUTF8(F));
        ftBlob:     BindBlob(F+1,Rows.ColumnBlob(F));
      end;
end;

procedure TSQLDBStatement.BindCursor(Param: integer);
begin
  raise ESQLDBException.CreateFmt(
    '%s does not support CURSOR parameter',[fStatementClassName]);
end;

function TSQLDBStatement.BoundCursor(Param: Integer): ISQLDBRows;
begin
  raise ESQLDBException.CreateFmt(
    '%s does not support CURSOR parameter',[fStatementClassName]);
end;


{$ifndef DELPHI5OROLDER}
{$ifndef LVCL}

{ TSQLDBRowVariantType }

procedure TSQLDBRowVariantType.IntGet(var Dest: TVarData;
  const V: TVarData; Name: PAnsiChar);
var Rows: TSQLDBStatement;
begin
  Rows := TSQLDBStatement(TVarData(V).VPointer);
  if Rows=nil then
    ESQLDBException.Create('Invalid TSQLDBRowVariantType call');
  Rows.ColumnToVariant(Rows.ColumnIndex(RawByteString(Name)),Variant(Dest));
end;

procedure TSQLDBRowVariantType.IntSet(const V, Value: TVarData;
  Name: PAnsiChar);
begin
  ESQLDBException.Create('TSQLDBRowVariantType is read-only');
end;

{$endif}
{$endif}


{ TSQLDBStatementWithParams }

function TSQLDBStatementWithParams.CheckParam(Param: Integer;
  NewType: TSQLDBFieldType; IO: TSQLDBParamInOutType): PSQLDBParam;
begin
  if self=nil then
    raise ESQLDBException.CreateFmt('Invalid %s.Bind*()',[fStatementClassName]);
  if Param>fParamCount then
    fParam.Count := Param; // resize fParams[] dynamic array if necessary
  result := @fParams[Param-1];
  result^.VType := NewType;
  result^.VInOut := IO;
end;

function TSQLDBStatementWithParams.CheckParam(Param: Integer;
  NewType: TSQLDBFieldType; IO: TSQLDBParamInOutType; ArrayCount: integer): PSQLDBParam;
begin
  result := CheckParam(Param,NewType,IO);
  if (NewType in [ftUnknown,ftNull]) or
     (fConnection.fProperties.BatchSendingAbilities*[cCreate,cUpdate,cDelete]=[]) then
    raise ESQLDBException.CreateFmt('Invalid call to %s.BindArray(Param=%d,Type=%s)',
      [fStatementClassName,Param,TSQLDBFieldTypeToString(NewType)]);
  SetLength(result^.VArray,ArrayCount);
  result^.VInt64 := ArrayCount;
  fParamsArrayCount := ArrayCount;
end;

constructor TSQLDBStatementWithParams.Create(aConnection: TSQLDBConnection);
begin
  inherited Create(aConnection);
  fParam.Init(TypeInfo(TSQLDBParamDynArray),fParams,@fParamCount);
end;

procedure TSQLDBStatementWithParams.Bind(Param: Integer; Value: double;
  IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftDouble,IO)^.VInt64 := PInt64(@Value)^;
end;

procedure TSQLDBStatementWithParams.Bind(Param: Integer; Value: Int64;
  IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftInt64,IO)^.VInt64 := Value;
end;

procedure TSQLDBStatementWithParams.BindBlob(Param: Integer;
  const Data: RawByteString; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftBlob,IO)^.VData := Data;
end;

procedure TSQLDBStatementWithParams.BindBlob(Param: Integer; Data: pointer;
  Size: integer; IO: TSQLDBParamInOutType);
begin
  SetString(CheckParam(Param,ftBlob,IO)^.VData,PAnsiChar(Data),Size);
end;

procedure TSQLDBStatementWithParams.BindCurrency(Param: Integer;
  Value: currency; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftCurrency,IO)^.VInt64 := PInt64(@Value)^;
end;

procedure TSQLDBStatementWithParams.BindDateTime(Param: Integer;
  Value: TDateTime; IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftDate,IO)^.VInt64 := PInt64(@Value)^;
end;

procedure TSQLDBStatementWithParams.BindNull(Param: Integer;
  IO: TSQLDBParamInOutType);
begin
  CheckParam(Param,ftNull,IO);
end;

procedure TSQLDBStatementWithParams.BindTextS(Param: Integer;
  const Value: string; IO: TSQLDBParamInOutType);
begin
  if (Value='') and fConnection.fProperties.StoreVoidStringAsNull then
    CheckParam(Param,ftNull,IO) else
    CheckParam(Param,ftUTF8,IO)^.VData := StringToUTF8(Value);
end;

procedure TSQLDBStatementWithParams.BindTextU(Param: Integer;
  const Value: RawUTF8; IO: TSQLDBParamInOutType);
begin
  if (Value='') and fConnection.fProperties.StoreVoidStringAsNull then
    CheckParam(Param,ftNull,IO) else
    CheckParam(Param,ftUTF8,IO)^.VData := Value;
end;

procedure TSQLDBStatementWithParams.BindTextP(Param: Integer;
  Value: PUTF8Char; IO: TSQLDBParamInOutType);
begin
  if (Value=nil) and fConnection.fProperties.StoreVoidStringAsNull then
    CheckParam(Param,ftNull,IO) else
    SetString(CheckParam(Param,ftUTF8,IO)^.VData,PAnsiChar(Value),StrLen(Value));
end;

procedure TSQLDBStatementWithParams.BindTextW(Param: Integer;
  const Value: WideString; IO: TSQLDBParamInOutType);
begin
  if (Value='') and fConnection.fProperties.StoreVoidStringAsNull then
    CheckParam(Param,ftNull,IO) else
    CheckParam(Param,ftUTF8,IO)^.VData := RawUnicodeToUtf8(pointer(Value),length(Value));
end;

{$ifndef LVCL}
function TSQLDBStatementWithParams.ParamToVariant(Param: Integer;
  var Value: Variant; CheckIsOutParameter: boolean): TSQLDBFieldType;
begin
  inherited ParamToVariant(Param,Value); // raise exception if Param incorrect
  dec(Param); // start at #1
  if CheckIsOutParameter and (fParams[Param].VInOut=paramIn) then
    raise ESQLDBException.CreateFmt('%s.ParamToVariant expects an [In]Out parameter',
      [fStatementClassName]);
  // OleDB provider should have already modified the parameter in-place, i.e.
  // in our fParams[] buffer, especialy for TEXT parameters (OleStr/WideString)
  // -> we have nothing to do but return the current value! :)
  with fParams[Param] do begin
    result := VType;
    case VType of
      ftInt64:     Value := {$ifdef DELPHI5OROLDER}integer{$endif}(VInt64);
      ftDouble:    Value := PDouble(@VInt64)^;
      ftCurrency:  Value := PCurrency(@VInt64)^;
      ftDate:      Value := PDateTime(@VInt64)^;
      ftUTF8:      Value := RawUTF8(VData);
      ftBlob:      Value := VData;
      else         Value := Null;
    end;
  end;
end;
{$endif}

procedure TSQLDBStatementWithParams.AddParamValueAsText(Param: integer; Dest: TTextWriter);
begin
  dec(Param);
  if cardinal(Param)>=cardinal(fParamCount) then
    Dest.AddShort('?OOR?') else
    with fParams[Param] do
    case VType of
      ftNull:     Dest.AddShort('NULL');
      ftInt64:    Dest.Add({$ifdef DELPHI5OROLDER}integer{$endif}(VInt64));
      ftDouble:   Dest.Add(PDouble(@VInt64)^);
      ftCurrency: Dest.AddCurr64(VInt64);
      ftDate:     Dest.AddDateTime(PDateTime(@VInt64),' ','''');
      ftUTF8:     Dest.AddQuotedStr(pointer(VData),'''');
      ftBlob:     Dest.AddShort('*BLOB*');
      else        Dest.AddShort('???');
    end;
end;

procedure TSQLDBStatementWithParams.BindArray(Param: Integer;
  const Values: array of double);
var i: integer;
begin
  with CheckParam(Param,ftDouble,paramIn,length(Values))^ do
    for i := 0 to high(Values) do
      VArray[i] := DoubleToStr(Values[i]);
end;

procedure TSQLDBStatementWithParams.BindArray(Param: Integer;
  const Values: array of Int64);
var i: integer;
begin
  with CheckParam(Param,ftInt64,paramIn,length(Values))^ do
    for i := 0 to high(Values) do
      VArray[i] := Int64ToUtf8(Values[i]);
end;

procedure TSQLDBStatementWithParams.BindArray(Param: Integer;
  ParamType: TSQLDBFieldType; const Values: TRawUTF8DynArray; ValuesCount: integer);
begin
  inherited; // raise an exception in case of invalid parameter
  with CheckParam(Param,ParamType,paramIn)^ do begin
    VArray := Values; // immediate COW reference-counted assignment
    VInt64 := ValuesCount;
  end;
  fParamsArrayCount := ValuesCount;
end;

procedure TSQLDBStatementWithParams.BindArray(Param: Integer;
  const Values: array of RawUTF8);
var i: integer;
    StoreVoidStringAsNull: boolean;
begin
  StoreVoidStringAsNull := fConnection.Properties.StoreVoidStringAsNull;
  with CheckParam(Param,ftUTF8,paramIn,length(Values))^ do
    for i := 0 to high(Values) do
      if StoreVoidStringAsNull and (Values[i]='') then
        VArray[i] := 'null' else
        QuotedStr(pointer(Values[i]),'''',VArray[i]);
end;

procedure TSQLDBStatementWithParams.BindArrayCurrency(Param: Integer;
  const Values: array of currency);
var i: integer;
begin
  with CheckParam(Param,ftCurrency,paramIn,length(Values))^ do
    for i := 0 to high(Values) do
      VArray[i] := Curr64ToStr(PInt64(@Values[i])^);
end;

procedure TSQLDBStatementWithParams.BindArrayDateTime(Param: Integer;
  const Values: array of TDateTime);
var i: integer;
begin
  with CheckParam(Param,ftDate,paramIn,length(Values))^ do
    for i := 0 to high(Values) do
      VArray[i] := ''''+DateTimeToIso8601Text(Values[i])+'''';
end;

procedure TSQLDBStatementWithParams.BindArrayRowPrepare(
  const aParamTypes: array of TSQLDBFieldType; aExpectedMinimalRowCount: integer);
var i: integer;
begin
  fParam.Count := 0;
  for i := 0 to high(aParamTypes) do
    CheckParam(i+1,aParamTypes[i],paramIn,aExpectedMinimalRowCount);
  fParamsArrayCount := 0;
end;

procedure TSQLDBStatementWithParams.BindArrayRow(const aValues: array of const);
var i: integer;
begin
  if length(aValues)<>fParamCount then
    raise ESQLDBException.CreateFmt('Invalid %s.BindArrayRow call',[fStatementClassName]);
  for i := 0 to high(aValues) do
    with fParams[i] do begin
      if length(VArray)<=fParamsArrayCount then
        SetLength(VArray,fParamsArrayCount+fParamsArrayCount shr 3+64);
      VInt64 := fParamsArrayCount;
      if (VType=ftDate) and (aValues[i].VType=vtExtended) then
        VArray[fParamsArrayCount] := // direct binding of TDateTime value
          ''''+DateTimeToIso8601Text(aValues[i].VExtended^)+'''' else begin
        VarRecToUTF8(aValues[i],VArray[fParamsArrayCount]);
        case VType of
        ftUTF8:
          if (VArray[fParamsArrayCount]='') and
             fConnection.Properties.StoreVoidStringAsNull then
          VArray[fParamsArrayCount] := 'null' else   
          VArray[fParamsArrayCount] := QuotedStr(VArray[fParamsArrayCount]);
        ftDate:
          VArray[fParamsArrayCount] := QuotedStr(VArray[fParamsArrayCount]);
        end;
      end;
    end;
  inc(fParamsArrayCount);
end;

procedure TSQLDBStatementWithParams.BindFromRows(Rows: TSQLDBStatement);
var F: integer;
    U: RawUTF8;
begin
  if Rows<>nil then
    if Rows.ColumnCount<>fParamCount then
      raise ESQLDBException.CreateFmt('Invalid %s.BindFromRows call',[fStatementClassName]) else
    for F := 0 to fParamCount-1 do
    with fParams[F] do begin
      if length(VArray)<=fParamsArrayCount then
        SetLength(VArray,fParamsArrayCount+fParamsArrayCount shr 3+64);
      if Rows.ColumnNull(F) then
        VArray[fParamsArrayCount] := 'null' else
      case Rows.ColumnType(F) of
        ftNull:
          VArray[fParamsArrayCount] := 'null';
        ftInt64:
          VArray[fParamsArrayCount] := Int64ToUtf8(Rows.ColumnInt(F));
        ftDouble:
          VArray[fParamsArrayCount] := DoubleToStr(Rows.ColumnDouble(F));
        ftCurrency:
          VArray[fParamsArrayCount] := CurrencyToStr(Rows.ColumnCurrency(F));
        ftDate:
          VArray[fParamsArrayCount] := ''''+DateTimeToSQL(Rows.ColumnDateTime(F))+'''';
        ftUTF8: begin
          U := Rows.ColumnUTF8(F);
          if (U='') and fConnection.Properties.StoreVoidStringAsNull then
            VArray[fParamsArrayCount] := 'null' else
            VArray[fParamsArrayCount] := QuotedStr(U,'''');
        end;
        ftBlob:
          VArray[fParamsArrayCount] := Rows.ColumnBlob(F);
      end;
    end;
  inc(fParamsArrayCount);
end;

procedure TSQLDBStatementWithParams.Reset;
begin
  inherited Reset;
  fParam.Clear;
end;


{ TSQLDBStatementWithParamsAndColumns }

function TSQLDBStatementWithParamsAndColumns.ColumnIndex(const aColumnName: RawUTF8): integer;
begin
  result := fColumn.FindHashed(aColumnName);
end;

function TSQLDBStatementWithParamsAndColumns.ColumnName(Col: integer): RawUTF8;
begin
  CheckCol(Col);
  result := fColumns[Col].ColumnName;
end;

function TSQLDBStatementWithParamsAndColumns.ColumnType(Col: integer; FieldSize: PInteger=nil): TSQLDBFieldType;
begin
  with fColumns[Col] do begin
    result := ColumnType;
    if FieldSize<>nil then
      if ColumnValueInlined then
        FieldSize^ := ColumnValueDBSize else
        FieldSize^ := 0;
  end;
end;

constructor TSQLDBStatementWithParamsAndColumns.Create(aConnection: TSQLDBConnection);
begin
  inherited Create(aConnection);
  fColumn.Init(TypeInfo(TSQLDBColumnPropertyDynArray),fColumns,nil,nil,nil,@fColumnCount,True);
end;


procedure LogTruncatedColumn(const Col: TSQLDBColumnProperty);
begin
  {$ifdef DELPHI5OROLDER}
  SynDBLog.Add.Log(sllDB,'Truncated column '+Col.ColumnName);
  {$else}
  SynDBLog.Add.Log(sllDB,'Truncated column %',Col.ColumnName);
  {$endif}
end;

function TrimLeftSchema(const TableName: RawUTF8): RawUTF8;
var i,j: integer;
begin
  j := 1;
  repeat
    i := PosEx('.',TableName,j);
    if i=0 then break;
    j := i+1;
  until false;
  if j=1 then
    result := TableName else
    result := copy(TableName,j,maxInt);
end;

function ReplaceParamsByNames(const aSQL: RawUTF8; var aNewSQL: RawUTF8): integer;
var i,j,B,L: integer;
    P: PAnsiChar;
    c: array[0..3] of AnsiChar;
    tmp: RawUTF8;
const SQL_KEYWORDS: array[0..17] of AnsiChar = 'ASBYIFINISOFONORTO';
begin
  result := 0;
  L := Length(aSQL);
  while (L>0) and (aSQL[L] in [#1..' ',';']) do
    if (aSQL[L]=';') and (L>5) and IdemPChar(@aSQL[L-3],'END') then
      break else // allows 'END;' at the end of a statement
      dec(L);    // trim ' ' or ';' right (last ';' could be found incorrect)
  if PosEx('?',aSQL)>0 then begin
    // change ? into :AA :BA ..
    c := ':AA';
    i := 0;
    P := pointer(aSQL);
    if P<>nil then
    repeat
      B := i;
      while (i<L) and (P[i]<>'?') do begin
        if P[i]='''' then begin
          repeat // ignore chars inside ' quotes
            inc(i);
          until (i=L) or ((P[i]='''')and(P[i+1]<>''''));
          if i=L then break;
        end;
        inc(i);
      end;
      SetString(tmp,P+B,i-B);
      aNewSQL := aNewSQL+tmp;
      if i=L then break;
      // store :AA :BA ..
      j := length(aNewSQL);
      SetLength(aNewSQL,j+3);
      PCardinal(PtrInt(aNewSQL)+j)^ := PCardinal(@c)^;
      repeat
        if c[1]='Z' then begin
          if c[2]='Z' then
            raise ESQLDBException.Create('Parameters :AA to :ZZ');
          c[1] := 'A';
          inc(c[2]);
        end else
          inc(c[1]);
      until WordScanIndex(@SQL_KEYWORDS,length(SQL_KEYWORDS)shr 1,PWord(@c[1])^)<0;
      inc(result);
      inc(i); // jump '?'
    until i=L;
  end else
    aNewSQL := copy(aSQL,1,L); // trim right ';' if any
end;


{ TSQLDBLib }

destructor TSQLDBLib.Destroy;
begin
  if Handle<>0 then
    FreeLibrary(Handle);
  inherited;
end;


{$ifndef DELPHI5OROLDER}

{ TSQLDBProxyConnectionProperties }

procedure TSQLDBProxyConnectionProperties.SetInternalProperties;
begin
  Process(cInitialize,self,fDBMS);
end;

procedure TSQLDBProxyConnectionProperties.GetForeignKeys;
begin
  Process(cGetForeignKeys,self,fForeignKeys);
end;

function TSQLDBProxyConnectionProperties.NewConnection: TSQLDBConnection;
begin
  result := TSQLDBProxyConnection.Create(self);
end;

procedure TSQLDBProxyConnectionProperties.GetFields(const aTableName: RawUTF8;
  var Fields: TSQLDBColumnDefineDynArray);
begin
  Process(cGetFields,aTableName,Fields);
end;

procedure TSQLDBProxyConnectionProperties.GetIndexes(const aTableName: RawUTF8;
  var Indexes: TSQLDBIndexDefineDynArray);
begin
  Process(cGetIndexes,aTableName,Indexes);
end;

procedure TSQLDBProxyConnectionProperties.GetTableNames(var Tables: TRawUTF8DynArray);
begin
  Process(cGetTableNames,self,Tables);
end;

function TSQLDBProxyConnectionProperties.IsCachable(P: PUTF8Char): boolean;
begin
  result := False;
end;


{ TSQLDBProxyConnection }

procedure TSQLDBProxyConnection.Commit;
begin
  inherited Commit;
  (fProperties as TSQLDBProxyConnectionProperties).
    Process(cCommit,self,self);
end;

procedure TSQLDBProxyConnection.Connect;
begin
  inherited Connect;
  (fProperties as TSQLDBProxyConnectionProperties).
    Process(cConnect,self,self);
  fConnected := true;
end;

procedure TSQLDBProxyConnection.Disconnect;
begin
  inherited Disconnect;
  (fProperties as TSQLDBProxyConnectionProperties).
    Process(cDisconnect,self,self);
  fConnected := false;
end;

function TSQLDBProxyConnection.GetServerTimeStamp: TTimeLog;
begin
  (fProperties as TSQLDBProxyConnectionProperties).
    Process(cServerTimeStamp,self,result);
end;

function TSQLDBProxyConnection.IsConnected: boolean;
begin
  result := fConnected;
end;

function TSQLDBProxyConnection.NewStatement: TSQLDBStatement;
begin // always create a new proxy statement instance (cached on remote side)
  result := TSQLDBProxyStatement.Create(self);
end;

procedure TSQLDBProxyConnection.Rollback;
begin
  inherited Rollback;
  (fProperties as TSQLDBProxyConnectionProperties).
    Process(cRollback,self,self);
end;

procedure TSQLDBProxyConnection.StartTransaction;
begin
  inherited StartTransaction;
  (fProperties as TSQLDBProxyConnectionProperties).
    Process(cStartTransaction,self,self);
end;


{ TSQLDBProxyStatementAbstract }

procedure TSQLDBProxyStatementAbstract.IntHeaderProcess(Data: PByte; DataLen: integer);
var Magic,F: integer;
begin
  repeat
    if DataLen<=5 then
      break;
    fDataRowCount := PInteger(PtrInt(Data)+DataLen-sizeof(Integer))^;
    Magic := FromVarUInt32(Data);
    if Magic<>FETCHALLTOBINARY_MAGIC then
      break;
    for F := 1 to FromVarUInt32(Data) do
    with PSQLDBColumnProperty(fColumn.AddAndMakeUniqueName(FromVarString(Data)))^ do begin
      ColumnType := TSQLDBFieldType(Data^);
      inc(Data);
      ColumnValueDBSize := FromVarUInt32(Data);
    end;
    if fColumnCount=0 then
      exit; // no data returned
    if (fColumnCount>sizeof(TSQLDBProxyStatementColumns)shl 3) or
       (cardinal(fDataRowCount)>=cardinal(DataLen) div cardinal(fColumnCount)) then
      break;
    fDataRowReaderOrigin := Data;
    fDataRowReader := Data;
    fDataRowNullSize := ((fColumnCount-1) shr 3)+1;
    SetLength(fDataCurrentRowValues,fColumnCount);
    exit;
  until false;
  fDataRowCount := 0;
  fColumnCount := 0;
  raise ESQLDBException.CreateFmt('Invalid %s.IntHeaderProcess',[fStatementClassName]);
end;

procedure TSQLDBProxyStatementAbstract.IntFillDataCurrent(var Reader: PByte);
var F, Len: Integer;
    NullLen: cardinal;
begin
  FillChar(fDataCurrentRowNull,fDataRowNullSize,0);
  NullLen := FromVarUInt32(Reader);
  if NullLen>fDataRowNullSize then
    raise ESQLDBException.CreateFmt('Invalid %s.IntFillDataCurrent',[fStatementClassName]);
  if NullLen>0 then begin
    Move(Reader^,fDataCurrentRowNull,NullLen);
    inc(Reader,NullLen);
  end;
  for F := 0 to fColumnCount-1 do
    if F in fDataCurrentRowNull then
      fDataCurrentRowValues[F] := nil else begin
      fDataCurrentRowValues[F] := Reader;
      with fColumns[F] do
      case ColumnType of
      ftInt64:
        Reader := GotoNextVarInt(Reader);
      ftDouble, ftCurrency, ftDate:
        inc(Reader,SizeOf(Int64));
      ftUTF8, ftBlob: begin
        Len := FromVarUInt32(Reader);
        if Len>ColumnDataSize then
          ColumnDataSize := Len;
        inc(Reader,Len); // jump string/blob content
      end;
      else raise ESQLDBException.CreateFmt('%s.IntStep: Invalid ColumnType(%s)=%d',
        [fStatementClassName,ColumnName,ord(ColumnType)]);
      end;
    end;
end;

procedure TSQLDBProxyStatementAbstract.ColumnsToJSON(WR: TJSONWriter; DoNotFletchBlobs: boolean);
var col, DataLen: integer;
    Data: PByte;
begin
  if WR.Expand then
    WR.Add('{');
  for col := 0 to fColumnCount-1 do begin
    if WR.Expand then
      WR.AddFieldName(fColumns[col].ColumnName); // add '"ColumnName":'
    Data := fDataCurrentRowValues[col];
    if Data=nil then
      WR.AddShort('null') else
    case fColumns[col].ColumnType of
      ftInt64:
        WR.Add(FromVarInt64Value(Data));
      ftDouble:
        WR.Add(PDouble(Data)^);
      ftCurrency:
        WR.AddCurr64(PInt64(Data)^);
      ftDate: begin
        WR.Add('"');
        WR.AddDateTime(PDateTime(Data)^);
        WR.Add('"');
      end;
      ftUTF8: begin
        WR.Add('"');
        DataLen := FromVarUInt32(Data);
        WR.AddJSONEscape(Data,DataLen);
        WR.Add('"');
      end;
      ftBlob:
        if DoNotFletchBlobs then
          WR.AddShort('null') else begin
          // WrBase64(..,withMagic=true)
          DataLen := FromVarUInt32(Data);
          WR.WrBase64(PAnsiChar(Data),DataLen,true);
        end;
    end;
    WR.Add(',');
  end;
  WR.CancelLastComma; // cancel last ','
  if WR.Expand then
    WR.Add('}');
end;

function TSQLDBProxyStatementAbstract.ColumnData(Col: integer): pointer;
begin
  if (fDataCurrentRowValues<>nil) and (cardinal(Col)<cardinal(fColumnCount)) then
    result := fDataCurrentRowValues[col] else
    result := nil;
end;

function TSQLDBProxyStatementAbstract.ColumnType(Col: integer; FieldSize: PInteger=nil): TSQLDBFieldType;
begin
  if (fDataRowCount>0) and (cardinal(Col)<cardinal(fColumnCount)) then
    if Col in fDataCurrentRowNull then
      result := ftNull else
      with fColumns[Col] do begin
        if FieldSize<>nil then
          FieldSize^ := ColumnDataSize; // true max size as computed at loading 
        result := ColumnType;
      end else
    raise ESQLDBException.CreateFmt('Invalid %s.ColumnType()',[fStatementClassName]);
end;

function TSQLDBProxyStatementAbstract.IntColumnType(Col: integer; out Data: PByte): TSQLDBFieldType;
begin
  if (cardinal(Col)>=cardinal(fColumnCount)) or (fDataCurrentRowValues=nil) then
    result := ftUnknown else begin
    Data := fDataCurrentRowValues[Col];
    if Data=nil then
      result := ftNull else
      result := fColumns[Col].ColumnType;
  end;
end;

function TSQLDBProxyStatementAbstract.ColumnCurrency(Col: integer): currency;
var Data: PByte;
begin
  case IntColumnType(Col,Data) of
  ftNull: result := 0;
  ftInt64: result := FromVarInt64Value(Data);
  ftDouble, ftDate: result := PDouble(Data)^;
  ftCurrency: result := PCurrency(Data)^;
  else raise ESQLDBException.CreateFmt('%s.ColumnCurrency()',[fStatementClassName]);
  end;
end;

function TSQLDBProxyStatementAbstract.ColumnDateTime(Col: integer): TDateTime;
var Data: PByte;
begin
  case IntColumnType(Col,Data) of
  ftNull: result := 0;
  ftInt64: result := FromVarInt64Value(Data);
  ftDouble, ftDate: result := PDouble(Data)^;
  ftUTF8: with FromVarBlob(Data) do
            result := Iso8601ToDateTimePUTF8Char(PUTF8Char(Ptr),Len);
  else raise ESQLDBException.CreateFmt('%s.ColumnDateTime()',[fStatementClassName]);
  end;
end;

function TSQLDBProxyStatementAbstract.ColumnDouble(Col: integer): double;
var Data: PByte;
begin
  case IntColumnType(Col,Data) of
  ftNull: result := 0;
  ftInt64: result := FromVarInt64Value(Data);
  ftDouble, ftDate: result := PDouble(Data)^;
  ftCurrency: result := PCurrency(Data)^;
  else raise ESQLDBException.CreateFmt('%s.ColumnDouble()',[fStatementClassName]);
  end;
end;

function TSQLDBProxyStatementAbstract.ColumnInt(Col: integer): Int64;
var Data: PByte;
begin
  case IntColumnType(Col,Data) of
  ftNull: result := 0;
  ftInt64: result := FromVarInt64Value(Data);
  ftDouble, ftDate: result := Trunc(PDouble(Data)^);
  ftCurrency: result := PInt64(Data)^ div 10000;
  else raise ESQLDBException.CreateFmt('%s.ColumnInt()',[fStatementClassName]);
  end;
end;

function TSQLDBProxyStatementAbstract.ColumnNull(Col: integer): boolean;
begin
  result := Col in fDataCurrentRowNull;
end;

function TSQLDBProxyStatementAbstract.ColumnBlob(Col: integer): RawByteString;
var Data: PByte;
begin
  case IntColumnType(Col,Data) of
  ftNull: result := '';
  ftDouble, ftCurrency, ftDate: SetString(result,PAnsiChar(Data),sizeof(Int64));
  ftBlob, ftUTF8: with FromVarBlob(Data) do SetString(result,Ptr,Len);
  else raise ESQLDBException.CreateFmt('%s.ColumnBlob()',[fStatementClassName]);
  end;
end;

function TSQLDBProxyStatementAbstract.ColumnUTF8(Col: integer): RawUTF8;
var Data: PByte;
begin
  case IntColumnType(Col,Data) of
  ftNull: result := '';
  ftInt64: result := Int64ToUtf8(FromVarInt64Value(Data));
  ftDouble: result := DoubleToStr(PDouble(Data)^);
  ftCurrency: result := Curr64ToStr(PInt64(Data)^);
  ftDate: DateTimeToIso8601TextVar(PDateTime(Data)^,'T',result);
  ftBlob, ftUTF8: with FromVarBlob(Data) do SetString(result,Ptr,Len);
  else raise ESQLDBException.CreateFmt('%s.ColumnUTF8()',[fStatementClassName]);
  end;
end;

function TSQLDBProxyStatementAbstract.ColumnString(Col: integer): string;
var Data: PByte;
begin
  case IntColumnType(Col,Data) of
  ftNull: result := '';
  ftInt64: result := IntToString(FromVarInt64Value(Data));
  ftDouble: result := DoubleToString(PDouble(Data)^);
  ftCurrency: result := Curr64ToString(PInt64(Data)^);
  ftDate: DateTimeToIso8601StringVar(PDateTime(Data)^,'T',result);
  ftUTF8: with FromVarBlob(Data) do UTF8DecodeToString(PUTF8Char(Ptr),Len,result);
  ftBlob: with FromVarBlob(Data) do SetString(result,Ptr,Len shr 1);
  else raise ESQLDBException.CreateFmt('%s.ColumnString()',[fStatementClassName]);
  end;
end;


{ TSQLDBProxyStatement }

procedure TSQLDBProxyStatement.ParamsToCommand(var Input: TSQLDBProxyConnectionCommandExecute);
begin
  if (fColumnCount>0) or (fDataInternalCopy<>'') then
    raise ESQLDBException.CreateFmt('Invalid %s.ExecutePrepared* call',[fStatementClassName]);
  Input.SQL := fSQL;
  if length(fParams)<>fParamCount then // strip to only needed memory
    SetLength(fParams,fParamCount);
  Input.Params := fParams;
  Input.ArrayCount := fParamsArrayCount;
end;

procedure TSQLDBProxyStatement.ExecutePrepared;
var Input: TSQLDBProxyConnectionCommandExecute;
const CMD: array[boolean] of TSQLDBProxyConnectionCommand = (
  cExecute, cExecuteToBinary);
begin
  // execute the statement
  ParamsToCommand(Input);
  (fConnection.fProperties as TSQLDBProxyConnectionProperties).
    Process(CMD[fExpectResults],Input,fDataInternalCopy);
  // retrieve columns information from TSQLDBStatement.FetchAllToBinary() format
  IntHeaderProcess(pointer(fDataInternalCopy),Length(fDataInternalCopy));
end;

procedure TSQLDBProxyStatement.ExecutePreparedAndFetchAllAsJSON(Expanded: boolean; out JSON: RawUTF8);
var Input: TSQLDBProxyConnectionCommandExecute;
const CMD: array[boolean] of TSQLDBProxyConnectionCommand = (
  cExecuteToJSON, cExecuteToExpandedJSON);
begin
  ParamsToCommand(Input);
  (fConnection.fProperties as TSQLDBProxyConnectionProperties).
    Process(CMD[Expanded],Input,JSON);
end;

procedure TSQLDBProxyStatement.Reset;
begin
  raise ESQLDBException.CreateFmt('%s should not be Reset',[fStatementClassName]);
end;

function TSQLDBProxyStatement.Step(SeekFirst: boolean): boolean;
begin // retrieve one row of data from TSQLDBStatement.FetchAllToBinary() format
  if SeekFirst then
    fCurrentRow := 0;
  if (cardinal(fCurrentRow)>=cardinal(fDataRowCount)) then begin
    result := false; // no data was retrieved
    exit;
  end;
  if fCurrentRow=0 then // first row should rewind the TFileBufferReader
    fDataRowReader := fDataRowReaderOrigin;
  IntFillDataCurrent(fDataRowReader);
  inc(fCurrentRow);
  result := true;
end;


{ TSQLDBProxyStatementRandomAccess }

constructor TSQLDBProxyStatementRandomAccess.Create(Data: PByte; DataLen: integer;
  DataRowPosition: PCardinalDynArray);
var i,f: integer;
    Reader: PByte;
begin
  inherited Create(nil);
  IntHeaderProcess(Data,DataLen);
  Reader := fDataRowReaderOrigin;
  if DataRowPosition<>nil then begin
    fRowData := DataRowPosition^; // fast copy-on-write
    for f := 0 to fColumnCount-1 do
      with fColumns[f] do
      if ColumnType in [ftUTF8,ftBlob] then
        if ColumnValueDBSize=0 then begin // unknown size -> compute
          for i := 0 to DataRowCount-1 do
            IntFillDataCurrent(Reader); // will compute ColumnDataSize
          break;
        end else
          ColumnDataSize := ColumnValueDBSize; // use declared maximum size
  end else begin
    SetLength(fRowData,DataRowCount);
    for i := 0 to DataRowCount-1 do begin
      fRowData[i] := PtrUInt(Reader)-PtrUInt(fDataRowReaderOrigin);
      IntFillDataCurrent(Reader); // will also compute ColumnDataSize
    end;
  end;
end;

function TSQLDBProxyStatementRandomAccess.GotoRow(Index: integer;
  RaiseExceptionOnWrongIndex: Boolean): boolean;
var Reader: PByte;
begin
  result := (cardinal(Index)<cardinal(fDataRowCount)) and (fColumnCount>0);
  if not result then
    if RaiseExceptionOnWrongIndex then
      raise ESQLDBException.CreateFmt('Invalid %s.GotoRow(%d)',[fStatementClassName,Index]) else
      exit;
  Reader := @PAnsiChar(fDataRowReaderOrigin)[fRowData[Index]];
  IntFillDataCurrent(Reader);
end;

procedure TSQLDBProxyStatementRandomAccess.ExecutePrepared;
begin
  raise ESQLDBException.CreateFmt('Unexpected %s.ExecutePrepared',[fStatementClassName]);
end;

function TSQLDBProxyStatementRandomAccess.Step(SeekFirst: boolean=false): boolean;
begin
  raise ESQLDBException.CreateFmt('Unexpected %s.Step',[fStatementClassName]);
end;


{$endif DELPHI5OROLDER}



initialization
  assert(SizeOf(TSQLDBColumnProperty)=sizeof(PTrUInt)*2+20);
  assert(SizeOf(TSQLDBParam)=sizeof(PTrUInt)*3+sizeof(Int64));
end.
