
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
		enumError
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
		Refresh : BOOL; (*Refresh entries*)
		ResetError : BOOL; (*Reset error*)
	END_STRUCT;
	logbookPAR : 	STRUCT  (*Parameter structure*)
		TableConfig : STRING[100]; (*Hide unused rows*)
		FilterErrorNo : UDINT; (*Filter by error number*)
		FilterErrorText : STRING[100]; (*Filter by error text*)
		FilterSeverity : ARRAY[0..3]OF BOOL := [4(TRUE)]; (*Filter by severity*)
		FilterFacility : ARRAY[0..LOGBOOK_FACILITIES_TOTAL]OF BOOL := [14(TRUE)]; (*Filter by facility*)
		FilterDateStart : DATE; (*Filter by date*)
		FilterDateEnd : DATE;
		DateNow : DATE_AND_TIME; (*Current date and time*)
		Sorting : enumSorting := sortingDESC; (*Sort date asc or desc*)
		AbortOnEntriesLimit : BOOL; (*Stop looking for additional entries when limit is reached*)
	END_STRUCT;
	logbookERR : 	STRUCT  (*Error structure*)
		State : enumLogbook; (*State where the error occured*)
	END_STRUCT;
	logbookDAT : 	STRUCT  (*Data structure*)
		Entries : logbookENTRIES;
		EntriesTotal : UINT;
		CntSeverity : ARRAY[0..3]OF UINT;
		CntFacility : ARRAY[0..LOGBOOK_FACILITIES_TOTAL]OF UINT;
	END_STRUCT;
	logbookENTRIES : 	STRUCT  (*Entries structure*)
		EventID : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF DINT; (*Event ID*)
		Timestamp : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF STRING[25]; (*Date and time*)
		DTsec : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF UDINT; (*Date and time in sec*)
		DTmsec : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF UDINT; (*Additional milliseconds*)
		Severity : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF USINT; (*Severity*)
		Code : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF UINT; (*Code*)
		FacilityCode : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF UINT; (*Facility code*)
		FacilityText : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF STRING[30]; (*Facility text*)
		ErrorNo : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF DINT; (*Error number*)
		ErrorText : ARRAY[1..LOGBOOK_ENTRIES_TOTAL]OF STRING[LOGBOOK_TEXT_LEN]; (*Error text*)
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
