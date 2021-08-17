$AD_DC = "yf.hryt.com"
$Group_Path= "OU=Services Accounts,DC=HRYT,DC=com"
$AD_OUs=Get-ADOrganizationalUnit -SearchBase "OU=华人运通,DC=HRYT,DC=com"  -Filter *  -SearchScope OneLevel | Select Name,DistinguishedName
foreach ( $OU in $AD_OUs )
{ 
  $Deptname = "SGroup_"+$OU.name
 if((Get-ADGroup -Identity $DeptName))
  {
   $OU_Users = Get-ADUser -Filter * -SearchBase $OU.DistinguishedName
   Write-Host "The OU $($OU.name) has $(($OU_Users).count) members!　" -ForegroundColor Yellow 
   foreach ( $OU_User in $OU_Users ){ Add-ADGroupMember -Identity $Deptname -members $OU_User  }
   $SGroup_Users =Get-ADGroupMember –Identity $Deptname
   $SGroup_Users | Where-Object {$_.distinguishedName –NotMatch $OU.name } | ForEach-Object {Remove-ADPrincipalGroupMembership –Identity $_ –MemberOf $Deptname  }
   Write-Host "The ShadowGroup $($Deptname) has $(($SGroup_Users).count) members!" -ForegroundColor Green
  }
    else { 
    New-ADGroup -GroupCategory: "Security" -GroupScope: "Global" -Name $Deptname -Path:$Group_Path -SamAccountName:$Deptname -Server:$AD_DC 
    $OU_Users = Get-ADUser -Filter * -SearchBase $OU.DistinguishedName
    Write-Host "The OU $($OU.name) has $(($OU_Users).count) members!" -ForegroundColor Yellow 
    foreach ( $OU_User in $OU_Users ){ Add-ADGroupMember -Identity $Deptname -members $OU_User  } 
    $SGroup_Users =Get-ADGroupMember –Identity $Deptname
    $SGroup_Users | Where-Object {$_.distinguishedName –NotMatch $OU.name } | ForEach-Object {Remove-ADPrincipalGroupMembership –Identity $_ –MemberOf $Deptname  }
    Write-Host "The ShadowGroup $($Deptname) has $(($SGroup_Users).count) members!" -ForegroundColor Green      
         }
 }