<cfcomponent name="gs" displayname="Google Storage CFC">

<!---

Google Storage CFC

Copyright (C) 2011 far too good

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
   
--   
   
www.ftg.co.uk/lab/gscfc

Version 0.1 Alpha - Jan 2011

Based heavily on the work of Joe Danziger and his Amazon S3 REST Wrapper CFC.

Done: constructor, auth, getBuckets, createBucket, readObject, copyObject, renameObject, putObject

Todo: acl stuff

--->

	<!--- init local vars --->
	<cfset variables.host = "commondatastorage.googleapis.com" />
	<cfset variables.host_auth = "sandbox.google.com/storage/bucket/object" />
	<cfset variables.key = "">
	<cfset variables.secret = "">
	<cfset variables.debug = true />

	<!--- constructor --->
	<cffunction name="init" access="public" output="false" returnType="gs">
		<cfargument name="key" type="string" required="true">
		<cfargument name="secret" type="string" required="true">
		
		<cfset variables.key = arguments.key>
		<cfset variables.secret = arguments.secret>
	
		<cfreturn this>
	</cffunction>
	
	<!--- encryptor --->
	<!---
	http://stackoverflow.com/questions/2959972/hmac-sha1-coldfusion
	--->
	<cffunction name="hmacEncrypt" access="private" output="false" returntype="string">
	   <cfargument name="signKey" type="string" required="true" />
	   <cfargument name="signMessage" type="string" required="true" />
	
	   	<cfset var jMsg = JavaCast("string",arguments.signMessage).getBytes("iso-8859-1") />
	   	<cfset var jKey = JavaCast("string",arguments.signKey).getBytes("iso-8859-1") />
	   	<cfset var key = createObject("java","javax.crypto.spec.SecretKeySpec") />
	   	<cfset var mac = createObject("java","javax.crypto.Mac") />
	
	   	<cfset key = key.init(jKey,"HmacSHA1") />
	   	<cfset mac = mac.getInstance(key.getAlgorithm()) />
	   	<cfset mac.init(key) />
	   	<cfset mac.update(jMsg) />
	
		<cfreturn toBase64(mac.doFinal())>
	</cffunction>

	<cffunction name="getBuckets" access="public" output="false" returntype="array" description="List buckets">
		<cfset var arrayResult = arrayNew(1) />
		<cfset var dt = GetHTTPTimeString(Now()) />
		
		<cfset n = chr(10) />
		
		<cfset var sig = "GET#n##n##n##dt##n#/" />
		<cfset sig = hmacEncrypt(variables.secret,sig) />
		
		<cfhttp method="GET" url="http://#variables.host#" result="gsResult">
			<cfhttpparam type="header" name="Date" value="#dt#" />
			<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#" />
		</cfhttp>
		
		<cfif gsResult.Statuscode EQ "200 OK"> 
			<cfset var data = xmlParse(gsResult.FileContent) />
			<cfset var arrayBuckets = xmlSearch(data,"//:Bucket") />
	
			<cfloop index="i" from="1" to="#arrayLen(arrayBuckets)#">
			   <cfset var bucket = structNew() />
			   <cfset bucket.Name = arrayBuckets[i].Name.xmlText />
			   <cfset bucket.CreationDate = arrayBuckets[i].CreationDate.xmlText />
			   <cfset arrayAppend(arrayResult,bucket) />   
			</cfloop>
		<cfelse>
			<!--- handle failed response here --->		
		</cfif>
	
		<cfreturn arrayResult>
	</cffunction>
	
	<cffunction name="getBucket" access="public" output="false" returntype="array">
		<cfargument name="bucketName" type="string" required="yes" />
		
		<cfset var item = "" />
		<cfset var dt = GetHTTPTimeString(Now()) />
		<cfset n = chr(10) />
		<cfset arrayResult = arrayNew(1) />
		
		<cfset var sig = "GET#n##n##n##dt##n#/#arguments.bucketName#" />
		<cfset sig = hmacEncrypt(variables.secret,sig) />

		<cfhttp method="GET" url="http://#variables.host#/#arguments.bucketName#" result="gsResult">
			<cfhttpparam type="header" name="Date" value="#dt#" />
			<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#" />
		</cfhttp>
		
		<cfif gsResult.Statuscode EQ "200 OK"> 
			<cfset var data = xmlParse(gsResult.FileContent) />
			<cfset var arrayContents = xmlSearch(data,"//:Contents") />
	
			<!--- create array and insert values from XML --->
			<cfloop index="i" from="1" to="#arrayLen(arrayContents)#">
				<cfset item = structNew() />
				<cfset item.Key = arrayContents[i].Key.xmlText />
				<cfset item.LastModified = arrayContents[i].LastModified.xmlText />
				<cfset item.Size = arrayContents[i].Size.xmlText />
				<cfset item.StorageClass = arrayContents[i].StorageClass.xmlText />
				<cfset arrayAppend(arrayResult, item) />   
			</cfloop>
		<cfelse>
			<!--- handle failed response here --->	
		</cfif>
	
		<cfreturn arrayResult>
	</cffunction>
	
	<cffunction name="readObject" access="public" output="false" returnType="struct">
		<cfargument name="bucketName" type="string" required="yes" />
		<cfargument name="objectName" type="string" required="yes" />
		
		<cfset var dt = GetHTTPTimeString(Now()) />
		<cfset n = chr(10) />
	
		<cfset var sig = "GET#n##n##n##dt##n#/#arguments.bucketName#/#objectName#" />
		<cfset sig = hmacEncrypt(variables.secret,sig) />

		<cfhttp method="GET" url="http://#variables.host#/#arguments.bucketName#/#arguments.objectName#" result="gsResult">
			<cfhttpparam type="header" name="Date" value="#dt#" />
			<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#" />
		</cfhttp>
		
		<cfset file = StructNew() />
		<cfset file.content = gsResult.Filecontent.toByteArray() />
		<cfset file.mimeType = gsResult.Mimetype />
		<cfset file.size = gsResult.Responseheader["Content-Length"] />
		<cfset file.header = gsResult.Responseheader />
		
		<cfreturn file>
	</cffunction>
	
	<cffunction name="getObject" access="public" output="false" returnType="string">
		<cfargument name="bucketName" type="string" required="yes" />
		<cfargument name="objectName" type="string" required="yes" />

		<!-- Google Storage doesn't yet support time-limited authenticated URls --->

		<cfset string = "http://#arguments.bucketName#.#variables.host#/#arguments.objectName#" />

		<cfreturn string />
	</cffunction>
	
	<cffunction name="createBucket" access="public" output="false" returnType="boolean">
		<cfargument name="bucketName" type="string" required="true">
		<cfargument name="acl" type="string" required="false" default="public-read">

		<cfset var n = chr(10) />
		<cfset var dt = GetHTTPTimeString(Now()) />

		<cfset var sig = "PUT#n##n#text/html#n##dt##n#x-goog-acl:#arguments.acl##n#/#arguments.bucketName#">
		<cfset sig = hmacEncrypt(variables.secret,sig) />

		<cfhttp method="PUT" url="http://#variables.host#/#arguments.bucketName#" result="gsResult">
			<cfhttpparam type="header" name="Content-Type" value="text/html" />
			<cfhttpparam type="header" name="Date" value="#dt#" />
			<cfhttpparam type="header" name="x-goog-acl" value="#arguments.acl#" />
			<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#" />
		</cfhttp>
		
		<cfif gsResult.Statuscode EQ "200 OK"> 
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="deleteBucket" access="public" output="false" returntype="boolean">
		<cfargument name="bucketName" type="string" required="yes">	
		
		<cfset var n = chr(10) />
		<cfset var dt = GetHTTPTimeString(Now()) />
		
		<cfset var sig = "DELETE#n##n##n##dt##n#/#arguments.bucketName#"> 
		<cfset sig = hmacEncrypt(variables.secret,sig) />
		
		<cfhttp method="DELETE" url="http://#variables.host#/#arguments.bucketName#" result="gsResult">
			<cfhttpparam type="header" name="Date" value="#dt#" />
			<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#">
		</cfhttp>
		
		<cfdump var="#gsResult#">
		
		<cfif gsResult.Statuscode EQ "204 No Content"> 
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="deleteObject" access="public" output="false" returntype="boolean">
		<cfargument name="bucketName" type="string" required="yes" />
		<cfargument name="objectName" type="string" required="yes" />

		<cfset var n = chr(10) />
		<cfset var dt = GetHTTPTimeString(Now())>

		<cfset var sig = "DELETE#n##n##n##dt##n#/#arguments.bucketName#/#arguments.objectName#"> 
		<cfset sig = hmacEncrypt(variables.secret,sig) />

		<cfhttp method="DELETE" url="http://#variables.host#/#arguments.bucketName#/#arguments.objectName#" result="gsResult">
			<cfhttpparam type="header" name="Date" value="#dt#">
			<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#">
		</cfhttp>

		<cfreturn true>
	</cffunction>
	
	<cffunction name="copyObject" access="public" output="false" returntype="boolean">
		<cfargument name="srcBucketName" type="string" required="yes" />
		<cfargument name="srcObjectName" type="string" required="yes" />
		<cfargument name="destinationBucketName" type="string" required="yes" />
		<cfargument name="destinationObjectName" type="string" required="yes" />
	
		<cfset var n = chr(10) />
		<cfset var dt = GetHTTPTimeString(Now())>

		<cfset var sig = "PUT#n##n#application/octet-stream#n##dt##n#x-goog-copy-source:/#arguments.srcBucketName#/#arguments.srcObjectName##n#/#arguments.destinationBucketName#/#arguments.destinationObjectName#"> 
		<cfset sig = hmacEncrypt(variables.secret,sig) />

		<cfhttp method="PUT" url="http://#variables.host#/#arguments.destinationBucketName#/#arguments.destinationObjectName#" result="gsResult">
			<cfhttpparam type="header" name="Date" value="#dt#">
			<cfhttpparam type="header" name="x-goog-copy-source" value="/#arguments.srcBucketName#/#arguments.srcObjectName#">
			<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#">
		</cfhttp>
		
		<cfif gsResult.Statuscode EQ "200 OK"> 
			<cfreturn true />
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>
	
	<cffunction name="moveObject" access="public" output="false" returntype="boolean">
		<cfargument name="srcBucketName" type="string" required="yes" />
		<cfargument name="srcObjectName" type="string" required="yes" />
		<cfargument name="destinationBucketName" type="string" required="yes" />
		<cfargument name="destinationObjectName" type="string" required="yes" />

		<cfset var status = copyObject(srcBucketName,srcObjectName,destinationBucketName,destinationObjectName) />
		
		<cfif status>
			<cfset status = deleteObject(srcBucketName,srcObjectName) />
			<cfif status>
				<cfreturn true />
			</cfif>
		</cfif>
		
		<cfreturn false />

	</cffunction>
	
	<!--- this is just an alias function to avoid confusion --->
	<cffunction name="renameObject" access="public" output="false" returntype="boolean">
		<cfargument name="srcBucketName" type="string" required="yes" />
		<cfargument name="srcObjectName" type="string" required="yes" />
		<cfargument name="destinationBucketName" type="string" required="yes" />
		<cfargument name="destinationObjectName" type="string" required="yes" />
		
		<cfset var status = moveObject(srcBucketName,srcObjectName,destinationBucketName,destinationObjectName) />
		
		<cfreturn status />
	</cffunction>
		
	<cffunction name="putObject" access="public" output="true" returntype="boolean">
		<cfargument name="srcFile" type="string" required="yes">
		<cfargument name="bucketName" type="string" required="yes">
		<cfargument name="objectName" type="string" required="yes">
		<cfargument name="acl" type="string" required="no" default="public-read">
		
		<cfset var n = chr(10) />
		<cfset var dt = GetHTTPTimeString(Now())>

		<cfif FileExists(srcFile)>
			
			<cfset contentType = getPageContext().getServletContext().getMimeType(srcFile) />
			
			<cfset var sig = "PUT#n##n##contentType##n##dt##n#x-goog-acl:#arguments.acl##n#/#arguments.bucketName#/#arguments.objectName#">
			<cfset sig = hmacEncrypt(variables.secret,sig) />
		
			<cfhttp method="PUT" url="http://#variables.host#/#arguments.bucketName#/#arguments.objectName#" result="gsResult">
				<cfhttpparam type="header" name="Date" value="#dt#">
				<cfhttpparam type="header" name="x-goog-acl" value="#arguments.acl#">
				<cfhttpparam type="header" name="Authorization" value="GOOG1 #variables.key#:#sig#">
				<cfhttpparam type="file" file="#srcFile#" name="#arguments.objectName#" mimeType="#contentType#">
			</cfhttp> 		
			
			<!---cfdump var="#gsResult#" /--->
			
			<cfreturn true>
		<cfelse>
			<cfreturn false />
		</cfif>
	</cffunction>	
		
</cfcomponent>







