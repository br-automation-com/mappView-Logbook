
TYPE
	enumLogbook : 
		( (*State machine*)
		enumWait,
		enumOpen,
		enumLatest,
		enumNext,
		enumDetails1,
		enumDetails2,
		enumDetails3,
		enumDetails4,
		enumFilter,
		enumPrep,
		enumError,
		enumNone
		);
	enumSeverity : 
		(
		severityNotification,
		severityInformation,
		severityWarning,
		severityError
		);
	enumFacility : 
		(
		facilityAccessSecurity,
		facilityCommisioning,
		facilityConnectivity,
		facilityFieldbus,
		facilityFirewall,
		facilityMapp,
		facilityMotion,
		facilitySafety,
		facilitySystem,
		facilityTextSystem,
		facilityUnitSystem,
		facilityUser,
		facilityVisualization
		);
	enumSorting : 
		(
		sortingASC,
		sortingDESC
		);
	logbookCMD : 	STRUCT  (*Command structure*)
		Refresh : BOOL; (*Read all entries*)
		Update : BOOL; (*Update entries*)
		ResetError : BOOL; (*Reset error*)
	END_STRUCT;
	logbookPAR : 	STRUCT  (*Parameter structure*)
		DateNow : DATE_AND_TIME; (*Current date and time*)
		TableConfig : STRING[100]; (*Hide unused rows*)
		EntriesMax : UINT; (*Maximum number of entries, shadow of LOGBOOK_ENTRIES_MAX*)
		FilterErrorNo : UDINT; (*Filter by error number*)
		FilterErrorText : STRING[100]; (*Filter by error text*)
		FilterSeverity : ARRAY[0..3]OF BOOL := [4(TRUE)]; (*Filter by severity*)
		FilterFacility : ARRAY[0..LOGBOOK_FACILITIES_MAX]OF BOOL := [14(TRUE)]; (*Filter by facility*)
		FilterDateStart : DATE; (*Filter by date*)
		FilterDateEnd : DATE;
		Sorting : enumSorting := sortingDESC; (*Sort date asc or desc*)
		AbortOnEntriesLimit : BOOL; (*Stop looking for additional entries when limit is reached*)
		AutoUpdate : BOOL; (*Automatically update data*)
		AutoUpdateInterval : UINT := 10; (*Interval for auto update in s*)
	END_STRUCT;
	logbookERR : 	STRUCT  (*Error structure*)
		State : enumLogbook; (*State where the error occured*)
	END_STRUCT;
	logbookDAT : 	STRUCT  (*Data structure*)
		Entries : logbookENTRIES;
		EntriesTotal : UINT; (*Total number of entries*)
		CntSeverity : ARRAY[0..3]OF UINT; (*Counts by severity*)
		CntFacility : ARRAY[0..LOGBOOK_FACILITIES_MAX]OF UINT; (*Counts by facility*)
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
		FacilityText : ARRAY[1..LOGBOOK_ENTRIES_MAX]OF STRING[30]; (*Facility text*)
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
