$ops="ops_adadmin"
$cred = Get-Credential -UserName $ops -Message "Input Ops User's Password"

$Servers = ''
$Servers = Get-ADComputer -SearchBase "OU=Domain Controllers,DC=HRYT,DC=com" -Filter { servicePrincipalName -notlike "msclustervirtualserver*" } | Sort-Object name
$Servers += Get-ADComputer -SearchBase "OU=Infra_OA,OU=MgmtServers,DC=HRYT,DC=com" -Filter { servicePrincipalName -notlike "msclustervirtualserver*" } | Sort-Object name
$DiskUsage=''
$DiskUsage=@()

foreach( $server in $servers)

{

$Disks = Get-WmiObject Win32_logicaldisk -ComputerName $server.Name -Filter "DriveType=3" -Credential $cred | select -property DeviceID,@{Name="Size(GB)";Expression={[decimal]("{0:N0}" -f($_.size/1gb))}},@{Name="Free Space(GB)";Expression={[decimal]("{0:N0}" -f($_.freespace/1gb))}},@{Name="Free (%)";Expression={"{0,0:P0}" -f(($_.freespace/1gb) / ($_.size/1gb))}}

foreach ($disk in $disks)
{

    if( $disk.'Free (%)' -lt '20%' -and $disk.'Free (%)' -ne '100%'  )

     { 
     
     $DiskUsage += New-Object psobject -Property @{
     Sever_Name = $server.Name ;
     Disk_Name = $disk.DeviceID;
     Free_Space =$disk.'Free Space(GB)';
     Free_Usg = $disk.'Free (%)';
     }  


        }
}


}

$DiskUsage | select Sever_Name,Disk_Name,Free_Space,Free_Usg 


