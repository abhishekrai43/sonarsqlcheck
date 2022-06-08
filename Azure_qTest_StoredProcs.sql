/****** Object:  StoredProcedure [sq].[DeleteData]    Script Date: 6/6/2022 1:25:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================
-- Create Stored Procedure To Delete qTest Data From SQL DB on Azure
-- ===========================================================================
--exec [sq].[DeleteData] '{"objectname":"TestCase","instancenameurl":"https://db.qtestnet.com","delobjid":"55964717"}'
CREATE PROCEDURE [sq].[DeleteData]
 
	@json NVARCHAR(max)
 
AS
BEGIN
	declare	 @objType		varchar(15)
			,@instURL		varchar(100)
			,@instName		varchar(20)
			,@objectId		int
			,@recCount		int

	 select 
		 @objType=objectname
		,@instURL=instancenameurl
		,@objectId=delobjid
	 from openjson (@json)
	 with(
			objectname			varchar(15),
			instancenameurl		varchar(100),
			delobjid				int
		) as jsonValues

	select @instName=instance_name from [sq].[sq_instance] where instance_url=@instURL
	select @instName
	if isnull(@instName,'NA')<>'NA'
	begin
	
		if isnull(@objType,'NA')='Requirement'
		begin
		   
			select @recCount=count(*) from [sq].[sq_requirement] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)>0
			begin
				delete from [sq].[sq_objectlink] where id =@objectId and instance_name=@instName

				delete from [sq].[sq_objectlink]
				where object_id=@objectId and instance_name=@instName and object_type='requirements'

				delete from [sq].[sq_property] where object_id=@objectId and instance_name=@instName

				delete from [sq].[sq_requirement]
				where id=@objectId and instance_name=@instName
			end
		end 
		/**** Since Defects cannot be deleted in qTest, hence Defects are can also not be deleted from the Database **************
		--else if isnull(@objType,'NA')='Defects'
		--begin
		--	select @recCount=count(*) from [sq].[sq_defect] where id=@objectId and instance_name=@instName
		--	if isnull(@recCount,0)>0
		--	begin
		--		delete from [sq].[sq_defect]
		--		where id=@objectId and instance_name=@instName
		--	end
		--end
		****************************************************************************************************************************/
		else if (isnull(@objType,'NA'))='TestCase'
		begin
			select @recCount=count(*) from [sq].[sq_testcase] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)>0
			begin
				
				delete from [sq].[sq_testrun] 
				where instance_name=@instName and
				id in (select id from [sq].[sq_objectlink] where object_id=@objectId and instance_name=@instName and object_type='test-cases' and pid like '%TR%')
				
				delete from [sq].[sq_objectlink] where id =@objectId and instance_name=@instName

				delete from [sq].[sq_objectlink]
				where object_id=@objectId and instance_name=@instName and object_type='test-cases'

				delete from [sq].[sq_teststep] where testcase_id=@objectId and instance_name=@instName

				delete from [sq].[sq_property] where object_id=@objectId and instance_name=@instName

				delete from [sq].[sq_testcase]
				where id=@objectId and instance_name=@instName
			end
		end
		else if (isnull(@objType,'NA'))='TestRun'
		begin
			select @recCount=count(*) from [sq].[sq_testrun] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)>0
			begin
				
				delete from [sq].[sq_objectlink] where id =@objectId and instance_name=@instName

				delete from [sq].[sq_objectlink] 
				where object_id=@objectId and instance_name=@instName and object_type='test-runs'

				delete from [sq].[sq_property] where object_id=@objectId and instance_name=@instName

				delete from [sq].[sq_testrun]
				where id=@objectId and instance_name=@instName

			end
		end
		
	end
END
GO
/****** Object:  StoredProcedure [sq].[InsertData]    Script Date: 6/6/2022 1:25:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================
-- Create Stored Procedure To Insert qTest REquirement Data to SQL DB on Azure
-- ===========================================================================

CREATE PROCEDURE [sq].[InsertData]
 
	@json NVARCHAR(max)
 
AS
BEGIN
	declare	 @objType		varchar(15)
			,@instURL		varchar(100)
			,@instName		varchar(20)
			,@objectId		int
			,@recCount		int

	 select 
		 @objType=objectname
		,@instURL=instancenameurl
		,@objectId=[objId]
	 from openjson (@json)
	 with(
			objectname			varchar(15),
			instancenameurl		varchar(100),
			[objId]				int
		) as jsonValues

	select @instName=instance_name from [sq].[sq_instance] where instance_url=@instURL
	select @instName
	if isnull(@instName,'NA')<>'NA'
	begin
		if isnull(@objType,'NA')='Project'
		begin
			select @recCount=count(*) from [sq].[sq_project] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				  INSERT INTO [sq].[sq_project]
					   ([instance_name]
					   ,[id]
					   ,[name]
					   ,[description]
					   ,[status_id]
					   ,[start_date]
					   ,[end_date]
					   ,[sample]
					   ,[x_explorer_access_level]
					   ,[date_format]
					   ,[automation]
					   ,[template_id]
					   ,[uuid])
					SELECT
						@instName
					   ,[objId]
					   ,projname
					   ,projdesc
					   ,statusId
					   ,startdate
					   ,enddate
					   ,samples
					   ,exploreraccesslevel
					   ,dateformat
					   ,automations
					   ,templateId
					   ,uuids
					FROM OPENJSON(@json)
					WITH (
						instancenameurl			varchar(100) 
					   ,[objId]					int 
					   ,projname				varchar(25)
					   ,projdesc				varchar(255)
					   ,statusId				int
					   ,startdate				datetimeoffset(7)
					   ,enddate					datetimeoffset(7)
					   ,samples					bit
					   ,exploreraccesslevel		int
					   ,dateformat				varchar(20)
					   ,automations				bit
					   ,templateId				int
					   ,uuids					varchar(25)
					   ) AS jsonValues
			end
			else
			begin
				
				update [sq].[sq_project] 
					set [name]=projname
						,[description]=projdesc 
						,[status_id]=statusId
						,[start_date]=startdate
					    ,[end_date]=enddate
					    ,[sample]=samples
					    ,[x_explorer_access_level]=exploreraccesslevel
					    ,[date_format]=dateformat
					    ,[automation]=automations
					    ,[template_id]=templateId
					    ,[uuid]=uuid
					from openjson (@json)
					with(
						projname				varchar(25)
					   ,projdesc				varchar(255)
					   ,statusId				int
					   ,startdate				datetimeoffset(7)
					   ,enddate					datetimeoffset(7)
					   ,samples					bit
					   ,exploreraccesslevel		int
					   ,dateformat				varchar(20)
					   ,automations				bit
					   ,templateId				int
					   ,uuids					varchar(25)
						) as jsonValues
					where id=@objectId and instance_name=@instName
			end
		end 
		else if isnull(@objType,'NA')='Requirement'
		begin
			select @recCount=count(*) from [sq].[sq_requirement] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_requirement]
			  ( [instance_name]
			   ,[id]
			   ,[parent_id]
			   ,[pid]
			   ,[name]
			   ,[order]
			   ,[web_url]
			   ,[created_date]
			   ,[last_modified_date])
			select
					@instName
				   ,[objId]
				   ,reqparentid
				   ,reqpid
				   ,reqname
				   ,reqorder
				   ,reqweb_url
				   ,reqcreated_date
				   ,reqlast_modified_date
			   
			FROM OPENJSON(@json)
				WITH (
						instancenameurl			varchar(20) 
					   ,[objId]					int 
					   ,reqparentid				int
					   ,reqpid						varchar(15)
					   ,reqname					varchar(max)
					   ,reqorder					int
					   ,reqweb_url					varchar(256)
					   ,reqcreated_date			datetimeoffset(7)
					   ,reqlast_modified_date		datetimeoffset(7)			  
				   ) AS jsonValues
			end
			else
			begin
				update [sq].[sq_requirement]
				set [parent_id]=reqparentid
				   ,[pid]=reqpid
				   ,[name]=reqname
				   ,[order]=reqorder
				   ,[web_url]=reqweb_url
				   ,[created_date]=reqcreated_date
				   ,[last_modified_date]=reqlast_modified_date
				FROM OPENJSON(@json)
				WITH (
						reqparentid				int
					   ,reqpid						varchar(15)
					   ,reqname					varchar(max)
					   ,reqorder					int
					   ,reqweb_url					varchar(256)
					   ,reqcreated_date			datetimeoffset(7)
					   ,reqlast_modified_date		datetimeoffset(7)			  
				   ) AS jsonValues
				where id=@objectId and instance_name=@instName
			end
		end 
		else if isnull(@objType,'NA')='Defects'
		begin
			select @recCount=count(*) from [sq].[sq_defect] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_defect]
			   ([instance_name]
			   ,[id]
			   ,[pid]
			   ,[submitter_id]
			   ,[submitted_date]
			   ,[last_modified_user_id]
			   ,[last_modified_date]
			   ,[web_url])
			select
					@instName
				   ,[objId]
				   ,defpid
				   ,defsubmitterid
				   ,defsubmitdate
				   ,deflastmoduserid
				   ,deflastmoddate
				   ,defweburl
			   
			FROM OPENJSON(@json)
				WITH (
					instancenameurl			varchar(20) 
				   ,[objId]					int 
				   ,defpid					varchar(15)
				   ,defsubmitterid			int
				   ,defsubmitdate			datetimeoffset(7)
				   ,deflastmoduserid		int
				   ,deflastmoddate			datetimeoffset(7)
				   ,defweburl				varchar(256)
				   ) AS jsonValues
			end
			else
			begin
				update [sq].[sq_defect]
				set [pid]=defpid
				   ,[submitter_id]=defsubmitterid
				   ,[submitted_date]=defsubmitdate
				   ,[last_modified_user_id]=deflastmoduserid
				   ,[last_modified_date]=deflastmoddate
				   ,[web_url]=defweburl
				FROM OPENJSON(@json)
				WITH (
						defpid					varchar(15)
					   ,defsubmitterid			int
					   ,defsubmitdate			datetimeoffset(7)
					   ,deflastmoduserid		int
					   ,deflastmoddate			datetimeoffset(7)
					   ,defweburl				varchar(256)			  
				   ) AS jsonValues
				where id=@objectId and instance_name=@instName
			end
		end
		else if (isnull(@objType,'NA'))='TestCases'
		begin
			select @recCount=count(*) from [sq].[sq_testcase] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_testcase]
				   ([instance_name]
				   ,[id]
				   ,[pid]
				   ,[name]
				   ,[test_case_version_id]
				   ,[version]
				   ,[description]
				   ,[order]
				   ,[parent_id]
				   ,[precondition]
				   ,[tosca_node_path]
				   ,[tosca_guid]
				   ,[tosca_url]
				   ,[tosca_test_case_unique_id]
				   ,[creator_id]
				   ,[created_date]
				   ,[last_modified_date]
				   ,[web_url])
			select
					@instName
				   ,[objId]
				   ,tc_pid
				   ,tc_name
				   ,tc_versionid
				   ,tc_version
				   ,tc_description
				   ,tc_order
				   ,tc_parent_id
				   ,tc_precondition
				   ,tc_toscanodepath
				   ,tc_toscaguid
				   ,tc_toscaurl
				   ,tc_toscatestcaseuniqueid
				   ,tc_creatorid
				   ,tc_created_date
				   ,tc_last_modified_date
				   ,tc_web_url
			   
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20) 
				   ,[objId]							int
				   ,tc_pid							varchar(25)
					,tc_name						varchar(256)
					,tc_versionid					int
					,tc_version						decimal(8,5)
					,tc_description					varchar(max)
					,tc_order						int
					,tc_parent_id					int
					,tc_precondition				varchar(max)
					,tc_toscanodepath				varchar(256)
					,tc_toscaguid					varchar(50)
					,tc_toscaurl					varchar(256)
					,tc_toscatestcaseuniqueid		varchar(50)
					,tc_creatorid					int
					,tc_created_date				datetimeoffset(7)
					,tc_last_modified_date			datetimeoffset(7)
					,tc_web_url						varchar(256)
				   ) AS jsonValues
			end
			else
			begin
				update [sq].[sq_testcase]
				set [pid]=tc_pid
				   ,[name]=tc_name
				   ,[test_case_version_id]=tc_versionid
				   ,[version]=tc_version
				   ,[description]=tc_description
				   ,[order]=tc_order
				   ,[parent_id]=tc_parent_id
				   ,[precondition]=tc_precondition
				   ,[tosca_node_path]=tc_toscanodepath
				   ,[tosca_guid]=tc_toscaguid
				   ,[tosca_url]=tc_toscaurl
				   ,[tosca_test_case_unique_id]=tc_toscatestcaseuniqueid
				   ,[creator_id]=tc_creatorid
				   ,[created_date]=tc_created_date
				   ,[last_modified_date]=tc_last_modified_date
				   ,[web_url]=tc_web_url
				FROM OPENJSON(@json)
				WITH (
						tc_pid							varchar(25)
					   ,tc_name							varchar(256)
					   ,tc_versionid					int
					   ,tc_version						decimal(8,5)
					   ,tc_description					varchar(max)
					   ,tc_order						int
					   ,tc_parent_id					int
					   ,tc_precondition					varchar(max)
					   ,tc_toscanodepath				varchar(256)
					   ,tc_toscaguid					varchar(50)
					   ,tc_toscaurl						varchar(256)
					   ,tc_toscatestcaseuniqueid		varchar(50)
					   ,tc_creatorid					int
					   ,tc_created_date					datetimeoffset(7)
					   ,tc_last_modified_date			datetimeoffset(7)
					   ,tc_web_url						varchar(256)			  
				   ) AS jsonValues
				where id=@objectId and instance_name=@instName
			end
		end
		else if (isnull(@objType,'NA'))='Modules'
		begin
			select @recCount=count(*) from [sq].[sq_module] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_module]
				   ([instance_name]
				   ,[project_id]
				   ,[id]
				   ,[pid]
				   ,[parent_id]
				   ,[name]
				   ,[order]
				   ,[description]
				   ,[recursive]
				   ,[default]
				   ,[shared]
				   ,[tosca_guid]
				   ,[tosca_node_path]
				   ,[created_date]
				   ,[last_modified_date])
			select
					@instName
				   ,modprojid
				   ,[objId]
				   ,modpid
				   ,modparentid
				   ,modname
				   ,modorder
				   ,moddescription
				   ,modrecursive
				   ,moddefault
				   ,modshared
				   ,modtoscaguid
				   ,modtoscanodepath
				   ,modcreateddate
				   ,modlastmodifieddate
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
				   ,modprojid						int
				   ,[objId]							int
				   ,modpid							varchar(15)
				   ,modparentid						int
				   ,modname							varchar(100)
				   ,modorder						int
				   ,moddescription					varchar(256)
				   ,modrecursive					bit
				   ,moddefault						bit
				   ,modshared						bit
				   ,modtoscaguid					varchar(50)
				   ,modtoscanodepath				varchar(150)
				   ,modcreateddate					datetimeoffset(7)
				   ,modlastmodifieddate				datetimeoffset(7)
				   ) AS jsonValues
			end
			else
			begin
				update [sq].[sq_module]
				set
					[project_id]=modprojid
				   ,[pid]=modpid
				   ,[parent_id]=modparentid
				   ,[name]=modname
				   ,[order]=modorder
				   ,[description]=moddescription
				   ,[recursive]=modrecursive
				   ,[default]=moddefault
				   ,[shared]=modshared
				   ,[tosca_guid]=modtoscaguid
				   ,[tosca_node_path]=modtoscanodepath
				   ,[created_date]=modcreateddate
				   ,[last_modified_date]=modlastmodifieddate
				FROM OPENJSON(@json)
				WITH (
					modprojid						int
				   ,modpid							varchar(15)
				   ,modparentid						int
				   ,modname							varchar(100)
				   ,modorder						int
				   ,moddescription					varchar(256)
				   ,modrecursive					bit
				   ,moddefault						bit
				   ,modshared						bit
				   ,modtoscaguid					varchar(50)
				   ,modtoscanodepath				varchar(150)
				   ,modcreateddate					datetimeoffset(7)
				   ,modlastmodifieddate				datetimeoffset(7)
				   ) AS jsonValues
				where id=@objectId and instance_name=@instName
			end
		end
		else if (isnull(@objType,'NA'))='Releases'
		begin
			select @recCount=count(*) from [sq].[sq_release] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_release]
				   ([instance_name]
				   ,[project_id]
				   ,[id]
				   ,[web_url]
				   ,[created_date]
				   ,[start_date]
				   ,[pid]
				   ,[name]
				   ,[order]
				   ,[end_date]
				   ,[note]
				   ,[last_modified_date]
				   ,[description])
			select
					@instName
				   ,relprojid
				   ,[objId]
				   ,relweburl
				   ,relcreateddate
				   ,relstartdate
				   ,relpid
				   ,relname
				   ,relorder
				   ,relenddate
				   ,relnode
				   ,rellastmodifieddate
				   ,reldescription
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
				   ,relprojid						int
				   ,[objId]							int
				   ,relweburl						varchar(256)
				   ,relcreateddate					datetimeoffset(7)
				   ,relstartdate					datetimeoffset(7)
				   ,relpid							varchar(15)
				   ,relname							varchar(50)
				   ,relorder						int
				   ,relenddate						datetimeoffset(7)
				   ,relnode							varchar(256)
				   ,rellastmodifieddate				datetimeoffset(7)
				   ,reldescription					varchar(256)
				   ) AS jsonValues
			end
		end
		else if (isnull(@objType,'NA'))='TestBuilds'
		begin
			select @recCount=count(*) from [sq].[sq_testbuild] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_testbuild]
				   ([instance_name]
				   ,[id]
				   ,[release_id]
				   ,[pid]
				   ,[name]
				   ,[order]
				   ,[created_date]
				   ,[last_modified_date])
			select
					@instName
				   ,[objId]
				   ,tbreleaseid
				   ,tbpid
				   ,tbname
				   ,tborder
				   ,tbcreateddate
				   ,tblastmodifieddate
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
				   ,[objId]							int
				   ,tbreleaseid						int
				   ,tbpid							varchar(15)
				   ,tbname							varchar(256)
				   ,tborder							int
				   ,tbcreateddate					datetimeoffset(7)
				   ,tblastmodifieddate				datetimeoffset(7)
				   ) AS jsonValues
			end
		end
		else if (isnull(@objType,'NA'))='TestCycle'
		begin
			select @recCount=count(*) from [sq].[sq_testcycle] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_testcycle]
				   ([instance_name]
				   ,[id]
				   ,[pid]
				   ,[target_release_id]
				   ,[created_date]
				   ,[name]
				   ,[order]
				   ,[target_build_id]
				   ,[last_modified_date]
				   ,[description]
				   ,[web_url])
			select
					@instName
				   ,[objId]
				   ,tclpid
				   ,tcltargetreleaseid
				   ,tclcreateddate
				   ,tclname
				   ,tclorder
				   ,tcltargetbuild
				   ,tcllastmodifieddate
				   ,tcldescription
				   ,tclweburl
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
				   ,[objId]							int
				   ,tclpid							varchar(15)
				   ,tcltargetreleaseid				int
				   ,tclcreateddate					datetimeoffset(7)
				   ,tclname							varchar(256)
				   ,tclorder						int
				   ,tcltargetbuild					int
				   ,tcllastmodifieddate				datetimeoffset(7)
				   ,tcldescription					varchar(256)
				   ,tclweburl						varchar(256)
				   ) AS jsonValues
			end
		end
		else if (isnull(@objType,'NA'))='TestLog'
		begin
			select @recCount=count(*) from [sq].[sq_testlog] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_testlog]
				   ([instance_name]
				   ,[id]
				   ,[build_number]
				   ,[test_run_id]
				   ,[test_case_version_id]
				   ,[actual_exe_time]
				   ,[result_number]
				   ,[name]
				   ,[note]
				   ,[planned_exe_time]
				   ,[exe_start_date]
				   ,[build_url]
				   ,[exe_end_date])
			select
					@instName
				   ,[objId]
				   ,tlbuildno
				   ,tltestrunid
				   ,tltcversionid
				   ,tlactexetime
				   ,tlresultno
				   ,tlname
				   ,tlnote
				   ,tlplannedexetime
				   ,tlexestartdate
				   ,tlbuildurl
				   ,tlexeenddate
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
				   ,[objId]							int
				   ,tlbuildno						varchar(50)
				   ,tltestrunid						int
				   ,tltcversionid					int
				   ,tlactexetime					int
				   ,tlresultno						int
				   ,tlname							varchar(256)
				   ,tlnote							varchar(256)
				   ,tlplannedexetime				int
				   ,tlexestartdate					datetimeoffset(7)
				   ,tlbuildurl						varchar(256)
				   ,tlexeenddate					datetimeoffset(7)
				   ) AS jsonValues
			end
			else
			begin
				update [sq].[sq_testlog]
				set [build_number]=tlbuildno
				   ,[test_run_id]=tltestrunid
				   ,[test_case_version_id]=tltcversionid
				   ,[actual_exe_time]=tlactexetime
				   ,[result_number]=tlresultno
				   ,[name]=tlname
				   ,[note]=tlnote
				   ,[planned_exe_time]=tlplannedexetime
				   ,[exe_start_date]=tlexestartdate
				   ,[build_url]=tlbuildurl
				   ,[exe_end_date]=tlexeenddate
				FROM OPENJSON(@json)
				WITH (
						tlbuildno						varchar(50)
					   ,tltestrunid						int
					   ,tltcversionid					int
					   ,tlactexetime					int
					   ,tlresultno						int
					   ,tlname							varchar(256)
					   ,tlnote							varchar(256)
					   ,tlplannedexetime				int
					   ,tlexestartdate					datetimeoffset(7)
					   ,tlbuildurl						varchar(256)
					   ,tlexeenddate					datetimeoffset(7)			  
				   ) AS jsonValues
				where id=@objectId and instance_name=@instName
			end
		end
		else if (isnull(@objType,'NA'))='TestRun'
		begin
			select @recCount=count(*) from [sq].[sq_testrun] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_testrun]
				   ([instance_name]
				   ,[id]
				   ,[parentType]
				   ,[parentId]
				   ,[pid]
				   ,[test_case_version_id]
				   ,[created_date]
				   ,[created]
				   ,[name]
				   ,[order]
				   ,[tosca_testevent_guid]
				   ,[creator_id]
				   ,[tosca_guid]
				   ,[testCaseId]
				   ,[test_case_version]
				   ,[automation]
				   ,[tosca_node_path]
				   ,[tosca_workspace_url])
			select
					@instName
				   ,[objId]
				   ,trparenttype
				   ,trparentid
				   ,trpid
				   ,trtestcaseversionid
				   ,trcreateddate
				   ,trcreated
				   ,trname
				   ,trorder
				   ,trtoscatesteventguid
				   ,trcreatorid
				   ,trtoscaguid
				   ,trtestcaseid
				   ,trtestcaseversion
				   ,trautomation
				   ,trtoscanodepath
				   ,trtoscaworkspaceurl
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
				   ,[objId]							int
				   ,trparenttype					varchar(10)
				   ,trparentid						int
				   ,trpid							varchar(15)
				   ,trtestcaseversionid				int
				   ,trcreateddate					datetimeoffset(7)
				   ,trcreated						varchar(25)
				   ,trname							varchar(256)
				   ,trorder							int
				   ,trtoscatesteventguid			varchar(50)
				   ,trcreatorid						int
				   ,trtoscaguid						varchar(50)
				   ,trtestcaseid					int
				   ,trtestcaseversion				decimal(8,5)
				   ,trautomation					varchar(3)
				   ,trtoscanodepath					varchar(150)
				   ,trtoscaworkspaceurl				varchar(256)
				   ) AS jsonValues
			end
			else
			begin
				update [sq].[sq_testrun]
				set [parentType]=trparenttype
				   ,[parentId]=trparentid
				   ,[pid]=trpid
				   ,[test_case_version_id]=trtestcaseversionid
				   ,[created_date]=trcreateddate
				   ,[created]=trcreated
				   ,[name]=trname
				   ,[order]=trorder
				   ,[tosca_testevent_guid]=trtoscatesteventguid
				   ,[creator_id]=trcreatorid
				   ,[tosca_guid]=trtoscaguid
				   ,[testCaseId]=trtestcaseid
				   ,[test_case_version]=trtestcaseversion
				   ,[automation]=trautomation
				   ,[tosca_node_path]=trtoscanodepath
				   ,[tosca_workspace_url]=trtoscaworkspaceurl
				FROM OPENJSON(@json)
				WITH (
						trparenttype					varchar(10)
					   ,trparentid						int
					   ,trpid							varchar(15)
					   ,trtestcaseversionid				int
					   ,trcreateddate					datetimeoffset(7)
					   ,trcreated						varchar(25)
					   ,trname							varchar(256)
					   ,trorder							int
					   ,trtoscatesteventguid			varchar(50)
					   ,trcreatorid						int
					   ,trtoscaguid						varchar(50)
					   ,trtestcaseid					int
					   ,trtestcaseversion				decimal(8,5)
					   ,trautomation					varchar(3)
					   ,trtoscanodepath					varchar(150)
					   ,trtoscaworkspaceurl				varchar(256)			  
				   ) AS jsonValues
				where id=@objectId and instance_name=@instName
			end
		end
		else if (isnull(@objType,'NA'))='TestSuit'
		begin
			select @recCount=count(*) from [sq].[sq_testsuite] where id=@objectId and instance_name=@instName
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_testsuite]
				   ([instance_name]
				   ,[parentType]
				   ,[parentId]
				   ,[id]
				   ,[pid]
				   ,[target_release_id]
				   ,[created_date]
				   ,[name]
				   ,[order]
				   ,[target_build_id]
				   ,[last_modified_date]
				   ,[web_url])
			select
					@instName
				   ,tstparenttype
				   ,tstparentid
				   ,[objId]
				   ,tstpid
				   ,tsttargetreleaseid
				   ,tstcreateddate
				   ,tstname
				   ,tstorder
				   ,tsttargetbuildid
				   ,tstlastmodifieddate
				   ,tstweburl
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
					,tstparenttype					varchar(20)
				   ,tstparentid						int
				   ,[objId]							int
				   ,tstpid							varchar(15)
				   ,tsttargetreleaseid				int
				   ,tstcreateddate					datetimeoffset(7)
				   ,tstname							varchar(256)
				   ,tstorder						int
				   ,tsttargetbuildid				int
				   ,tstlastmodifieddate				datetimeoffset(7)
				   ,tstweburl						varchar(256)
				   ) AS jsonValues
			end
		end
	end
END
GO
/****** Object:  StoredProcedure [sq].[InsertObjectLinkData]    Script Date: 6/6/2022 1:25:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================
-- Create Stored Procedure To Insert qTest REquirement Data to SQL DB on Azure
-- ===========================================================================
--exec [sq].[InsertObjectLinkData] '{"instancenameurl":"https://demoinstance.qtestnet.com","objId":"18829289","objType":"ObjLink","objlnkid":"52051622","objlnkpid":"TC-1","objlnktype":"is_covered_by","objlnkself":"https://demoinstance.qtestnet.com/api/v3/projects/121914/test-cases/52051622?versionId=70757623"}'
CREATE PROCEDURE [sq].[InsertObjectLinkData]
 
	@json NVARCHAR(max)
 
AS
BEGIN
declare	 @objType		varchar(15)
			,@instURL		varchar(100)
			,@instName		varchar(20)
			,@objectId		int
			,@recCount		int
			,@objlinkid			varchar(10)
	 select 
		 @objType=objType
		,@instURL=instancenameurl
		,@objectId=[objId]
		,@objlinkid=objlnkid
	 from openjson (@json)
	 with(
			objType			varchar(15),
			instancenameurl		varchar(100),
			[objId]				int,
			objlnkid				int
		) as jsonValues
    --select @objectId,@objType,@fieldid,@instURL
	select @instName=instance_name from [sd].[sq_instance] where instance_url=@instURL
	select @instName
	if isnull(@instName,'NA')<>'NA'
	begin
		select @recCount=count(*) from [sq].[sq_objectlink] where [object_id]=@objectId and instance_name=@instName and id=@objlinkid and object_type=@objType
			select @recCount
			if isnull(@recCount,0)=0
			begin
			   select 'Obj Insert'
			   
				INSERT INTO [sq].[sq_objectlink]
					([instance_name]
					,[object_id]
					   ,[object_type]
					   ,[id]
					   ,[pid]
					   ,[link_type]
					   ,[self])
				SELECT
					@instName
					,[objId]
					,objType
					,objlnkid
					,objlnkpid
					,objlnktype
					,objlnkself					   
				FROM OPENJSON(@json)
				WITH (
					instancenameurl			varchar(20) 
					,[objId]				int 
					,objType				varchar(15)
					,objlnkid				int
					,objlnkpid				varchar(10)
					,objlnktype			varchar(256)
					,objlnkself		varchar(256)
					) AS jsonValues
			end
			--else
			--begin
			--	update [sd].[sq_property] 
			--	set
			--		--[object_type]=objType
			--		[field_value]=prop_field_value
			--		,[field_value_name]=prop_field_value_name
			--	FROM OPENJSON(@json)
			--	WITH (
			--		--objType					    varchar(15)
			--		 prop_field_value			varchar(max)
			--		,prop_field_value_name		varchar(100)
			--		) AS jsonValues
			--	where [object_id]=@objectId and instance_name=@instName and field_id=@fieldid and object_type=@objType
			--end
	end
			
END
GO
/****** Object:  StoredProcedure [sq].[InsertPropertyData]    Script Date: 6/6/2022 1:25:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================
-- Create Stored Procedure To Insert qTest REquirement Data to SQL DB on Azure
-- ===========================================================================

CREATE PROCEDURE [sq].[InsertPropertyData]
 
	@json NVARCHAR(max)
 
AS
BEGIN
declare	 @objType		varchar(15)
			,@instURL		varchar(100)
			,@instName		varchar(20)
			,@objectId		int
			,@recCount		int
			,@fieldid		int

	 select 
		 @objType=objType
		,@instURL=instancenameurl
		,@objectId=[objId]
		,@fieldid=prop_field_id
	 from openjson (@json)
	 with(
			objType			varchar(15),
			instancenameurl		varchar(100),
			[objId]				int,
			prop_field_id		int
		) as jsonValues
    --select @objectId,@objType,@fieldid,@instURL
	select @instName=instance_name from [sq].[sq_instance] where instance_url=@instURL
	select @instName
	if isnull(@instName,'NA')<>'NA'
	begin
		select @recCount=count(*) from [sq].[sq_property] where [object_id]=@objectId and instance_name=@instName and field_id=@fieldid and object_type=@objType
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_property]
					([instance_name]
					,[object_id]
					,[object_type]
					,[field_id]
					,[field_name]
					,[field_value]
					,[field_value_name])
				SELECT
					@instName
					,[objId]
					,objType
					,prop_field_id
					,prop_field_name
					,prop_field_value
					,prop_field_value_name					   
				FROM OPENJSON(@json)
				WITH (
					instancenameurl			varchar(20) 
					,[objId]				int 
					,objType				varchar(15)
					,prop_field_id				int
					,prop_field_name				varchar(100)
					,prop_field_value			varchar(max)
					,prop_field_value_name		varchar(100)
					) AS jsonValues
			end
			else
			begin
				update [sq].[sq_property] 
				set
					--[object_type]=objType
					[field_value]=prop_field_value
					,[field_value_name]=prop_field_value_name
				FROM OPENJSON(@json)
				WITH (
					--objType					    varchar(15)
					 prop_field_value			varchar(max)
					,prop_field_value_name		varchar(100)
					) AS jsonValues
				where [object_id]=@objectId and instance_name=@instName and field_id=@fieldid and object_type=@objType
			end
	end
			
END
GO
/****** Object:  StoredProcedure [sq].[InsertTestStepData]    Script Date: 6/6/2022 1:25:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================================
-- Create Stored Procedure To Insert qTest REquirement Data to SQL DB on Azure
-- ===========================================================================

CREATE PROCEDURE [sq].[InsertTestStepData]
 
	@json NVARCHAR(max)
 
AS
BEGIN
declare	 @objType		varchar(15)
			,@instURL		varchar(100)
			,@instName		varchar(20)
			,@objectId		int
			,@recCount		int
			,@testcaseid	int

	 select 
		 @objType=objectname
		,@instURL=instancenameurl
		,@objectId=[objId]
		,@testcaseid=tstestcaseid
	 from openjson (@json)
	 with(
			objectname			varchar(15),
			instancenameurl		varchar(100),
			[objId]				int,
			tstestcaseid		int
		) as jsonValues

	select @instName=instance_name from [sq].[sq_instance] where instance_url=@instURL
	select @instName
	if isnull(@instName,'NA')<>'NA'
	begin
		select @recCount=count(*) from [sq].[sq_teststep] where id=@objectId and instance_name=@instName and testcase_id=@testcaseid
			if isnull(@recCount,0)=0
			begin
				INSERT INTO [sq].[sq_teststep]
				   ([instance_name]
				   ,[id]
				   ,[testcase_id]
				   ,[test_case_version_id]
				   ,[root_called_test_case_id]
				   ,[order]
				   ,[called_test_case_name]
				   ,[plain_value_text]
				   ,[parent_test_step_id]
				   ,[expected]
				   ,[description]
				   ,[group])
			select
					@instName
				   ,[objId]
				   ,tstestcaseid
				   ,tstestcaseversionid
				   ,tsrootcalledtestcaseid
				   ,tsorder
				   ,tscalledtestcasename
				   ,tsplainvaluetest
				   ,tsparentteststep
				   ,tsexpected
				   ,tsdescription
				   ,tsgroup
			FROM OPENJSON(@json)
				WITH (
					instancenameurl					varchar(20)
				   ,[objId]							int
				   ,tstestcaseid					int
				   ,tstestcaseversionid				int
				   ,tsrootcalledtestcaseid			int
				   ,tsorder							int
				   ,tscalledtestcasename			varchar(256)
				   ,tsplainvaluetest				varchar(max)
				   ,tsparentteststep				int
				   ,tsexpected						varchar(256)
				   ,tsdescription					varchar(max)
				   ,tsgroup							int
				   ) AS jsonValues
			end
			else
			begin
				update [sq].[sq_teststep] 
				set
					[test_case_version_id]=tstestcaseversionid
				   ,[root_called_test_case_id]=tsrootcalledtestcaseid
				   ,[order]=tsorder
				   ,[called_test_case_name]=tscalledtestcasename
				   ,[plain_value_text]=tsplainvaluetest
				   ,[parent_test_step_id]=tsparentteststep
				   ,[expected]=tsexpected
				   ,[description]=tsdescription
				   ,[group]=tsgroup
				FROM OPENJSON(@json)
				WITH (
						tstestcaseversionid				int
					   ,tsrootcalledtestcaseid			int
					   ,tsorder							int
					   ,tscalledtestcasename			varchar(256)
					   ,tsplainvaluetest				varchar(max)
					   ,tsparentteststep				int
					   ,tsexpected						varchar(256)
					   ,tsdescription					varchar(max)
					   ,tsgroup							int
					) AS jsonValues
				where id=@objectId and instance_name=@instName and testcase_id=@testcaseid
			end
	end
			
END
GO
