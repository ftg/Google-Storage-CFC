<!---

http://code.google.com/p/google-storage-cfc/

http://code.google.com/apis/storage

https://sandbox.google.com/storage/
https://sandbox.google.com/storage/m/manage

--->

<!--- SET YOUR KEYS HERE --->
<cfset key = "YOUR-KEY-HERE" />
<cfset secret = "YOUR-SECRET-HERE" />

<!--- Create GoogleStorage Object --->
<cfset gs = createObject("component","gs").init(key,secret)>

<!--- some actions before listing --->
<cfif IsDefined("form.gs_action") AND form.gs_action EQ "createBucket">
	<cfset result = gs.createBucket(Trim(form.bucketName)) />
	<cfoutput><br />Result: #result# </cfoutput>
<cfelseif IsDefined("url.deleteBucket")>
	<cfset result = gs.deleteBucket(Trim(url.deleteBucket)) />
	<cfoutput><br />Result: #result# </cfoutput>
<cfelseif IsDefined("url.deleteObject") AND IsDefined("url.getBucket")>
	<cfset result = gs.deleteObject(url.getBucket,url.deleteObject) />
	<cfoutput><br />Result: #result# </cfoutput>
</cfif>


<!--- List Buckets --->
<cfset result = gs.getBuckets()>
	
<cfoutput>		
<ul>
	<cfloop from="1" to="#arrayLen(result)#" index="i">
		<li>[<a href="#cgi.script_name#?deleteBucket=#URLEncodedFormat(result[i].Name)#">DELETE</a>] <a href="#cgi.script_name#?getBucket=#URLEncodedFormat(result[i].Name)#">#result[i].Name#</a> #result[i].CreationDate#</li>
	</cfloop>
	<cfform method="post" action="#cgi.script_name#">
	<li><cfinput type="text" required="yes" name="bucketName"><cfinput type="submit" name="gs_action" value="createBucket" /></li>
	</cfform>
</ul>
</cfoutput>

<cfif IsDefined("url.getBucket")>
	<hr>
	<cfset bucket = gs.getBucket(url.getBucket)>
	<cfoutput>		
	<ul>
		<cfloop from="1" to="#arrayLen(bucket)#" index="i">
			<li>[<a href="#cgi.script_name#?getBucket=#url.getBucket#&deleteObject=#bucket[i].Key#">DELETE</a>]
				[<a href="#cgi.script_name#?getBucket=#url.getBucket#&getObject=#bucket[i].Key#">GET</a>]
				[<a href="#cgi.script_name#?getBucket=#url.getBucket#&readObject=#bucket[i].Key#">READ</a>]
				<a href="#cgi.script_name#?getBucket=#url.getBucket#&getObject=#bucket[i].Key#">#bucket[i].Key#</a> (#bucket[i].Size# bytes)
			</li>
		</cfloop>
	</ul>
	</cfoutput>
</cfif>

<!--- readObject reads content of file into a struct --->

<cfif IsDefined("url.readObject") AND IsDefined("url.getBucket") >
	<hr>
	<cfset file = gs.readObject(url.getBucket,url.readObject) >
	<cfdump var="#file#">
	<!---cfcontent reset="yes" type="#file.mimeType#" variable="#file.content#" /--->
</cfif>

<!--- getObject creates a link directly to the object on Google Storage servers --->

<cfif IsDefined("url.getObject") AND IsDefined("url.getBucket") >
	<hr>
	<cfset link = gs.getObject(url.getBucket,url.getObject) >
	
	<cfoutput><a href="#link#">#link#</a></cfoutput>
</cfif>
