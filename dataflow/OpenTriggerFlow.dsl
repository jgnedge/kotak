parameters{
	partitionValue as string
}
source(output(
		TRIGGER_UNIQUE_ID as string,
		ROW_ID as string,
		CRN_ID as string,
		CP_ID as string,
		LOB as string,
		CUSTOMER_NAME as string,
		INDUSTRY as string,
		ADDRESS as string,
		CITY as string,
		STATE as string,
		CM_NAME as string,
		RM_NAME as string,
		TRIGGER_DATE as timestamp,
		TRIGGER_USECASE as string,
		TRIGGER_NAME as string,
		TRIGGER_ID as string,
		TRIGGER_COUNT as integer,
		VERTICAL as string,
		CRN_LOB_KEY as string
	),
	allowSchemaDrift: true,
	validateSchema: false,
	ignoreNoFilesFound: false,
	format: 'parquet') ~> ewsTrigger
ewsTrigger derive({_created_ts} = fromUTC(currentUTC(), 'IST'),
		{_state} = iif( VERTICAL === 'WBG','Non Suspicious','Open'),
		{_created_by} = 'EWS',
		{_feedback_id} = uuid(),
		{_p_date} = $partitionValue) ~> deriveStatus
deriveStatus sink(allowSchemaDrift: true,
	validateSchema: false,
	umask: 0022,
	preCommands: [],
	postCommands: [],
	skipDuplicateMapInputs: true,
	skipDuplicateMapOutputs: true,
	mapColumn(
		trigger_unique_id = TRIGGER_UNIQUE_ID,
		created_by = {_created_by},
		feedback_id = {_feedback_id},
		state = {_state},
		created_ts = {_created_ts},
		crn = CRN_ID,
		p_date = {_p_date},
		row_id = ROW_ID,
		vertical = VERTICAL
	)) ~> loadAdls