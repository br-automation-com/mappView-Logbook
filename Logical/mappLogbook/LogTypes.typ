
TYPE
	enumLogbookState : 
		( (*State machine*)
		stateWait,
		stateCreate,
		stateOpen,
		stateLatest,
		stateNext,
		stateDetails1,
		stateDetails2,
		stateDetails3,
		stateDetails4,
		stateFilter,
		statePrep,
		stateError,
		stateNone
		);
	enumSeverity : 
		(
		severityNotification,
		severityInformation,
		severityWarning,
		severityError
		);
	enumLogbookType : 
		(
		logAccessSecurity,
		logCommisioning,
		logConnectivity,
		logFieldbus,
		logFirewall,
		logMapp,
		logMotion,
		logSafety,
		logSystem,
		logTextSystem,
		logUnitSystem,
		logUser,
		logVisualization
		);
	enumSorting : 
		(
		sortingASC,
		sortingDESC
		);
	logbookCMD : 	STRUCT  (*Command structure*)
		Refresh : BOOL; (*Read all entries*)
		Update : BOOL; (*Update entries*)
		Create : BOOL; (*Create a new entry*)
		ResetError : BOOL; (*Reset error*)
	END_STRUCT;
	logbookPAR : 	STRUCT  (*Parameter structure*)
		DateNow : DATE_AND_TIME; (*Current date and time*)
		TableConfig : STRING[100]; (*Hide unused rows*)
		EntriesMax : UINT; (*Maximum number of entries, shadow of LOGBOOK_ENTRIES_MAX*)
		FilterErrorNo : UDINT; (*Filter by error number*)
		FilterErrorText : STRING[LOGBOOK_TEXT_LEN]; (*Filter by error text*)
		FilterSeverity : ARRAY[0..3]OF BOOL := [4(TRUE)]; (*Filter by severity*)
		FilterLogbook : ARRAY[0..LOGBOOK_BOOKS_MAX]OF BOOL := [14(TRUE)]; (*Filter by logbook*)
		FilterDateStart : DATE; (*Filter by date*)
		FilterDateEnd : DATE;
		Sorting : enumSorting := sortingDESC; (*Sort date asc or desc*)
		AbortOnEntriesLimit : BOOL; (*Stop looking for additional entries when limit is reached*)
		AutoUpdate : BOOL; (*Automatically update data*)
		AutoUpdateInterval : UINT := 60; (*Interval for auto update in s*)
		CreateErrorNo : UINT; (*Error no for new entry*)
		CreateErrorText : STRING[LOGBOOK_TEXT_LEN]; (*Error text for new entry*)
		CreateSeverity : enumSeverity := severityNotification; (*Error severiry for new entry*)
		CreateLogbook : enumLogbookType := logUser; (*Error logbook for new entry*)
	END_STRUCT;
	logbookERR : 	STRUCT  (*Error structure*)
		State : enumLogbookState; (*State where the error occured*)
	END_STRUCT;
	logbookDAT : 	STRUCT  (*Data structure*)
		Entries : logbookENTRIES;
		EntriesTotal : UINT; (*Total number of entries*)
		CntSeverity : ARRAY[0..3]OF UINT; (*Counts by severity*)
		CntLogbook : ARRAY[0..LOGBOOK_BOOKS_MAX]OF UINT; (*Counts by logbook*)
		LastUpdate : STRING[25]; (*Last refresh run*)
	END_STRUCT;
	logbookENTRIES : 	STRUCT  (*Entries structure*)
		EventID : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF DINT; (*Event ID*)
		Timestamp : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF STRING[25]; (*Date and time*)
		DTsec : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF UDINT; (*Date and time in sec*)
		DTmsec : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF UDINT; (*Additional milliseconds*)
		Severity : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF USINT; (*Severity*)
		Code : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF UINT; (*Code*)
		FacilityCode : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF UINT; (*Facility code*)
		LogbookName : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF STRING[30]; (*Logbook text*)
		ErrorNo : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF DINT; (*Error number*)
		ErrorText : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF STRING[LOGBOOK_TEXT_LEN]; (*Error text*)
	END_STRUCT;
	logbookMAIN : 	STRUCT  (*Main structure*)
		CMD : logbookCMD;
		PAR : logbookPAR;
		DAT : logbookDAT;
		ERR : logbookERR;
		Status : DINT;
		StatusText : STRING[80];
	END_STRUCT;
END_TYPE
