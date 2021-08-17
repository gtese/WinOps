$reportsender="sa_srv_report"
$reportemail="sa_srv_report@human-horizons.com"
$Reportsenderpwd=???????" | ConvertTo-SecureString -asPlainText -Force 
$reportrecipient ="Yiyao_Lin@human-horizons.com" 
$ReportSmtpserver="mail.human-horizons.com"               
$ReportSmtpCred = New-Object System.Management.Automation.PSCredential($reportsender,$Reportsenderpwd)

$ReportBody +="<style>TABLE{ border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;align:center;width:100%;}
TH{border-width: 1px;background-color: #0048ba;bgcolor=#0048ba;padding: 1px;border-style: solid;border-color: black;}
TD{border-width: 1px;color: gray;background-color: transparent ;padding: 1px;border-style: solid;border-color: black;}
h1{text-shadow: 1px 1px 1px #000,1px 1px 1px blue; text-align: center;font-style:Arial;font-family: Tahoma,Verdana,STHeiTi,simsun,sans-serif;</style>"

$Date=(get-date).ToString('yyyyMMdd')
$Hostname = hostname | Out-String
$Version = (Get-WmiObject -class Win32_OperatingSystem).Caption | Out-String
$os = Get-WmiObject win32_operatingsystem
$uptime = (Get-Date) - ($os.ConvertToDateTime($os.lastbootuptime))
$boottime = [Management.ManagementDateTimeConverter]::ToDateTime($os.LastBootUpTime) 
$Up="Boottime:"+ $boottime + " `n System Uptime: " + $Uptime.Days + " days, " + $Uptime.Hours + " hours, " + $Uptime.Minutes + " minutes"

## Get Disk Spaces
$Disk = Get-WmiObject Win32_logicaldisk -ComputerName LocalHost -Filter "DriveType=3" | select -property DeviceID,@{Name="Size(GB)";Expression={[decimal]("{0:N0}" -f($_.size/1gb))}},@{Name="Free Space(GB)";Expression={[decimal]("{0:N0}" -f($_.freespace/1gb))}},@{Name="Free (%)";Expression={"{0,6:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}}|ConvertTo-Html

## Get CPU Utilization
$CPU_Utilization = Get-Process|Sort-object -Property CPU -Descending| Select -first 10 `
-Property ID,ProcessName,@{Name = 'CPU In (%)';Expression = {$TotalSec = (New-TimeSpan -Start $_.StartTime).TotalSeconds;[Math]::Round( ($_.CPU * 100 /$TotalSec),2)}},@{Expression={$_.threads.count};Label="Threads";},@{Name="Mem Usage(MB)";Expression={[math]::round($_.ws / 1mb)}}|ConvertTo-Html

## Get Each Processor Utilization
$arr=@()
$ProcessorObject=gwmi win32_processor
foreach($processor in $ProcessorObject)
{
   $arr += $processor.Caption
   $arr += $processor.LoadPercentage
}


## RAM Usage
$Private:perfmem = Get-WmiObject -namespace root\cimv2 Win32_PerfFormattedData_PerfOS_Memory
$Private:totmem = Get-WmiObject -namespace root\cimv2 CIM_PhysicalMemory 
[Int32]$Private:totalcapacity = 0 
foreach ($Mem in $totmem) 
{ 
$totalcapacity += $Mem.Capacity / 1Mb 
} 
Get-WmiObject Win32_PhysicalMemory | ForEach-Object {$totalcapacity += $_.Capacity / 1Mb} 

$Private:tmp = New-Object -TypeName System.Object 
$tmp | Add-Member -Name CapacityMB -Value $totalcapacity -MemberType NoteProperty 
$tmp | Add-Member -Name AvailableMB -Value $perfmem.AvailableMBytes -MemberType NoteProperty
$ram_usage = $tmp |ConvertTo-Html


## Physical Memory
function Get-MemoryUsage ($ComputerName=$ENV:ComputerName) {
if (Test-Connection -ComputerName $ComputerName -Count 1 -Quiet) {
$ComputerSystem = Get-WmiObject -ComputerName $ComputerName -Class Win32_operatingsystem -Property TotalVisibleMemorySize, FreePhysicalMemory
$MachineName = $ComputerSystem.CSName
$FreePhysicalMemory = ($ComputerSystem.FreePhysicalMemory) / (1mb)
$TotalVisibleMemorySize = ($ComputerSystem.TotalVisibleMemorySize) / (1mb)
$TotalVisibleMemorySizeR = "{0:N2}" -f $TotalVisibleMemorySize
$TotalFreeMemPerc = ($FreePhysicalMemory/$TotalVisibleMemorySize)*100
$TotalFreeMemPercR = "{0:N2}" -f $TotalFreeMemPerc
# print the machine details:
"<table border=1 width=100>"
"<tr><th>RAM</th><td>$TotalVisibleMemorySizeR GB</td></tr>"
"<tr><th>Free Physical Memory</th><td>$TotalFreeMemPercR %</td></tr>"
"</table>"

}}
$PhyMem = Get-MemoryUsage


$d=get-date

#This is the HTML view you can customize accoring to your requirement .
$ReportBody +="<BODY><HTML>"
$ReportBody +="<h2 align=left><u> $Hostname HEALTH CHECK REPORT AS ON $d</u></h2>"
$ReportBody +="</br>"
#$ReportBody +="<table border=1 ><tr><td>"
$ReportBody +="<table border=1 width=100%>"
$ReportBody +="<tr><th><B>Hostname</B></th><td>"+$Hostname+"</td></tr>"
$ReportBody +="<tr><th><B>Version</B></th><td>"+$Version+"</td></tr>"
$ReportBody +="<tr><th><B>Uptime</B></th><td>"+$up+"</td></tr>"
$ReportBody +="<tr><th><B>Disk Size</B></th><td>"+$Disk+"</td></tr>"
$ReportBody +="<tr><th><B>Physical Memory</B></th><td>"+$PhyMem+"</td></tr>"
$ReportBody +="<tr><th><B>Top5 Process</B></th><td>"+$CPU_Utilization+"</td></tr>"
$ReportBody +="</table></BODY></HTML>"

$subect ="HHT Server"+ [System.Net.Dns]::GetHostName() + " Health Check Report"

Send-MailMessage -From $reportemail -To $reportrecipient  -Subject $subect  -body $ReportBody  -Port 587 -UseSsl -SmtpServer $ReportSmtpserver -Credential $ReportSmtpCred -BodyAsHtml -Encoding ([System.Text.Encoding]::UTF8) 

Get-Variable -Name repor* | Remove-Variable

