$output = Get-Content .\deploymentOut.json | ConvertFrom-Json

$copmponentSuccess = $output[0].result.details.componentSuccesses
$copmponentFailures = $output[0].result.details.componentFailures

$successCount = $copmponentSuccess.Count
$failureCount = $copmponentFailures.Count

for($i=0; $i -lt $successCount; $i++){
    $output[0].result.details.componentSuccesses[$i].success = "Success"
}

for($i=0; $i -lt $failureCount; $i++){
    $output[0].result.details.componentFailures[$i].success = "Failed"
}

$gitJsonBody = @()
$gitFailedBody = @()
$removeableField = @("CustomField","WebLink","ListView","BusinessProcess","ValidationRule","CompactLayout","RecordType","FieldSet","ListView")

$gitJsonBody = @"
<html>
<body> 
    <h2>Deployment Details</h2>
</body>
</html>
"@

$githeader = @" 
"@

$gitJSONResult = $output | Select-Object -expand  result
$gitJsonBody += $gitJSONResult | Select-Object  @{Name="Deployment Status";Expression={$_.status}},@{Name="Number of Components Deployed";Expression={$_.numberComponentsDeployed}},@{Name="Number of Components Failed";Expression={$_.numberComponentErrors}} | ConvertTo-Html -Head $githeader
$gitJsonBody +=  "<p><b>Note:</b> Object count includes fields, listview, validation, and so on. </p>"
$gitJsonBody += "<br><h2>Component Details</h2><br>"
 
if($output[0].result.status -eq "Succeeded")
{ 
    $JSONResult = $output | Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentSuccesses 
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}} | Sort-Object success > .\mailResult.txt
    $removeUnwantedField = ""
    $removeXml = $JSONResult | Select-Object | Where-Object { $_.fullName -ne "package.xml" }
    $tempJSONResult = $removeXml
    foreach($field in $removeableField){
        $removeUnwantedField = $tempJSONResult | Select-Object | Where-Object { $_.componentType -ne "$field" }
        $tempJSONResult = $removeUnwantedField
    }
    $gitJsonBody += $removeUnwantedField | Select-Object  @{Name="Component Type";Expression={$_.componentType}},@{Name="File";Expression={$_.fileName}},@{Name="Full Name";Expression={$_.fullName}},@{Name="Status";Expression={$_.success}} | Sort-Object success | ConvertTo-Html -Head $githeader
}
else 
{
    $JSONResult = $output | Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentSuccesses 
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}} | Sort-Object success > .\mailResult.txt
    $removeUnwantedField = ""
    $removeXml = $JSONResult | Select-Object | Where-Object { $_.fullName -ne "package.xml" }
    $tempJSONResult = $removeXml
    foreach($field in $removeableField){
        $removeUnwantedField = $tempJSONResult | Select-Object | Where-Object { $_.componentType -ne "$field" }
        $tempJSONResult = $removeUnwantedField
    }
    $gitFailedBody += $removeUnwantedField
   
    $JSONResult = $output |Select-Object -expand  result |Select-Object -expand details | Select-Object -expand componentFailures  
    $JSONResult | Select-Object @{Name="Component Type";Expression={$_.componentType}}, @{Name="File";Expression={$_.fileName}}, @{Name="Full Name";Expression={$_.fullName}}, @{Name="Status";Expression={$_.success}}, @{Name="Failure Reason";Expression={$_.problem}} | Sort-Object success > .\mailResult.txt
    $gitFailedBody += $JSONResult
    $gitJsonBody += $gitFailedBody | Select-Object  @{Name="Component Type";Expression={$_.componentType}},@{Name="File";Expression={$_.fileName}},@{Name="Full Name";Expression={$_.fullName}},@{Name="Status";Expression={$_.success}}, @{Name="Failure Reason";Expression={$_.problem}} | Sort-Object success | ConvertTo-Html -Head $githeader

}

$pullRequestID = $env:GITHUB_REF -replace 'refs/pull/(\d+)/merge','$1'

$gitbody = @{
    body = "$gitJsonBody"
} | ConvertTo-Json

$githeader =@{
    Authorization = "token $env:GIT_TOKEN"
    Accept = "application/vnd.github.v3+json"
}

$pullReqStatusUrl =  "$env:GIT_SERVER_URL$env:GITHUB_REPOSITORY/issues/$pullRequestID/comments"
$pullReqStatusResponse = Invoke-RestMethod -Uri $pullReqStatusUrl -Headers $githeader -Method Post -Body $gitbody
