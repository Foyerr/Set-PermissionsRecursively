<#
.SYNOPSIS
    Recursively sets file and folder permissions for a specified path and user group.

.PARAMETER path
    Specifies the root directory path where permissions will be recursively applied.
    [ValidateScript: Must be a valid path]
    [Default: None]

.PARAMETER group
    Specifies the user group to which permissions will be granted.
    [Default: None]

.EXAMPLE
    Set-PermissionsRecursively -path "W:\" -group "BUILTIN\Administrators"
    This example sets full control permissions for the "BUILTIN\Administrators" group starting from the "W:\" directory and recursively applying to all subdirectories and files.

.EXAMPLE
    Set-PermissionsRecursively -path "C:\Users\Public" -group "Everyone"
    This example sets full control permissions for the "Everyone" group starting from the "C:\Users\Public" directory and recursively applying to all subdirectories and files.

.NOTES
    The function uses the .NET class System.Security.AccessControl.FileSystemAccessRule to create an ACL rule.
    It uses Get-Acl to fetch existing ACLs and Set-Acl to apply new ACLs.
    Errors are logged to a specified error log file.
    
#>

function Set-PermissionsRecursively {
    param (
        [ValidateScript({Test-Path $_})]
        [string]$path=$null,
        [string]$group
    )
    
    try {
   
        # Enumerate files and subdirectories separately to avoid loading all at once
        $files = Get-ChildItem -File -Force -Path $path
        $subdirectories = Get-ChildItem -Directory -Force -Path $path
        
        
        # Recursively apply permissions to subdirectories
        foreach ($subdirectory in ($subdirectories+$path)) {
            # Apply permissions to the current directory
            $acl = Get-Acl -Path $path
            if("$group" -notin (($acl).Access | select IdentityReference)){
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
                $acl.AddAccessRule($rule)
                Set-Acl -Path $path -AclObject $acl
            }
            Set-PermissionsRecursively -path $subdirectory.fullname -group $group
        }
        foreach($file in $files){
            # Apply permissions to the current directory
            $acl = Get-Acl -Path $file.FullName
            if("$group" -notin (($acl).Access | select IdentityReference)){
                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($group, "FullControl", "None", "None", "Allow")
                $acl.AddAccessRule($rule)
                Set-Acl -Path $file.FullName -AclObject $acl
            }
        }

        return 
    }
    catch {
        # Log any errors to the error log file
        $_.Exception.Message + "$path $file" | Out-File -Append -FilePath $errorLogFile
    }
}

﻿# Define the directory path you want to apply permissions to
$directoryPath = "W:\"

# Define the administrators group
$administratorsGroup = "BUILTIN\Administrators"

# Define the output file path for errors
$errorLogFile = "C:\temp\ErrorLog.txt"

# Call the function to set permissions recursively
Set-PermissionsRecursively -path $directoryPath -group $administratorsGroup
